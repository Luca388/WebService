import { AppError, missing, forbidden, invalidState } from './errors.js';

// TODO-01~04: 업무 규칙과 트랜잭션을 직접 구현합니다. docs/API.md를 먼저 읽으세요.
// actor는 검증된 로그인 사용자입니다. repo의 저장 함수는 권한을 검사하지 않습니다.
// 상태 변경과 이력 저장은 함께 성공하거나 함께 실패해야 합니다.
// 승인 취소와 자동 승급은 신청 2건 + 이력 2건을 한 트랜잭션으로 처리합니다.

// ---- [학생 구현] 공통 도구 ----------------------------------------------------

const alreadyApplied = () => new AppError(409, 'ALREADY_APPLIED', '이미 이 행사에 신청한 기록이 있습니다.');
const capacityFull = () => new AppError(409, 'CAPACITY_FULL', '정원이 모두 찼습니다.');
const SQLITE_CONSTRAINT_UNIQUE = 2067;

// 하나의 요청 = 하나의 트랜잭션.
// BEGIN IMMEDIATE로 시작해 첫 조회 전에 DB 쓰기 잠금을 잡습니다. 따라서 검사(조회)와 저장 사이에
// 다른 연결(다른 서버 프로세스)이 끼어들 수 없고, 매 요청은 잠금 이후의 최신 DB 상태로 판단합니다(R8).
// fn 안에서 거부(AppError)나 저장 오류가 나면 ROLLBACK하여 요청 전 상태·이력으로 되돌립니다(R7).
function inTransaction(db, fn) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const result = fn();
    db.exec('COMMIT');
    return result;
  } catch (err) {
    if (db.isTransaction) db.exec('ROLLBACK');
    throw err;
  }
}

// 담당 운영자 판단: 역할이 MANAGER이고 행사의 manager_id가 로그인 사용자와 같아야 합니다(R1).
const isManagerOf = (actor, event) => actor.role === 'MANAGER' && event.managerId === actor.id;

// 신청과 그 신청의 행사를 함께 조회합니다. 없으면 404.
function loadTarget(repo, applicationId) {
  const application = repo.application(applicationId);
  if (!application) throw missing('신청');
  return { application, event: repo.event(application.eventId) };
}

export function createApplicationService(repo) {
  const { db } = repo;
  return {
    // TODO-01: 행사·학생 역할·중복 검사 → PENDING 저장 + APPLY 이력.
    apply(actor, eventId) {
      return inTransaction(db, () => {
        const event = repo.event(eventId);
        if (!event) throw missing('행사');                         // 404
        if (actor.role !== 'STUDENT') throw forbidden();            // 403 학생만 신청
        if (repo.existing(eventId, actor.id)) throw alreadyApplied(); // 409 상태 무관(CANCELLED·REVOKED 포함)

        let created;
        try {
          created = repo.insert(eventId, actor.id); // userId는 항상 로그인 사용자
        } catch (err) {
          // UNIQUE(event_id,user_id) 최종 방어선에 걸려도 500이 아닌 409로 응답합니다.
          if (err.errcode === SQLITE_CONSTRAINT_UNIQUE) throw alreadyApplied();
          throw err;
        }
        repo.addHistory({ applicationId: created.id, actorId: actor.id, action: 'APPLY', fromStatus: null, toStatus: 'PENDING' });
        return created;
      });
    },

    // TODO-02: 본인의 PENDING만 CANCELLED로 변경 + CANCEL 이력.
    // 대기 취소는 승인 자리를 비우지 않으므로 자동 승급하지 않습니다.
    cancel(actor, applicationId) {
      return inTransaction(db, () => {
        const { application } = loadTarget(repo, applicationId);   // 404
        if (application.userId !== actor.id) throw forbidden();      // 403 본인만(운영자·타인 거부)
        if (application.status !== 'PENDING') throw invalidState();  // 409 APPROVED·종료 상태 거부

        const updated = repo.setStatus(application.id, 'CANCELLED');
        repo.addHistory({ applicationId: application.id, actorId: actor.id, action: 'CANCEL', fromStatus: 'PENDING', toStatus: 'CANCELLED' });
        return updated;
      });
    },

    // TODO-03: 담당자·PENDING·정원 검사 → APPROVED + APPROVE 이력.
    // 직접 승인은 운영자가 대상을 선택합니다(FIFO 강제 없음).
    approve(actor, applicationId) {
      return inTransaction(db, () => {
        const { application, event } = loadTarget(repo, applicationId); // 404
        if (!isManagerOf(actor, event)) throw forbidden();                // 403
        if (application.status !== 'PENDING') throw invalidState();       // 409
        if (repo.approvedCount(event.id) >= event.capacity) throw capacityFull(); // 409 APPROVED만 정원에 포함

        const updated = repo.setStatus(application.id, 'APPROVED');
        repo.addHistory({ applicationId: application.id, actorId: actor.id, action: 'APPROVE', fromStatus: 'PENDING', toStatus: 'APPROVED' });
        return updated;
      });
    },

    // TODO-04: 담당자·APPROVED 검사 → REVOKED + REVOKE 이력 → 다음 대기자 1명 AUTO_APPROVE.
    // reason은 app.js에서 trim·5~200자 검사를 마친 값입니다.
    revoke(actor, applicationId, reason) {
      return inTransaction(db, () => {
        const { application, event } = loadTarget(repo, applicationId); // 404
        if (!isManagerOf(actor, event)) throw forbidden();                // 403
        if (application.status !== 'APPROVED') throw invalidState();      // 409 반복 승인 취소 포함

        // 1) 승인 취소 + REVOKE 이력
        const revoked = repo.setStatus(application.id, 'REVOKED');
        const revokeHistoryId = repo.addHistory({
          applicationId: application.id, actorId: actor.id, action: 'REVOKE',
          fromStatus: 'APPROVED', toStatus: 'REVOKED', reason
        });

        // 2) 비워진 한 자리만 다음 대기자에게: 요청당 최대 1명 승급
        const next = repo.nextPending(event.id);
        let promoted = null;
        if (next) {
          promoted = repo.setStatus(next.id, 'APPROVED');
          repo.addHistory({
            applicationId: next.id, actorId: actor.id, action: 'AUTO_APPROVE',
            fromStatus: 'PENDING', toStatus: 'APPROVED', causeHistoryId: revokeHistoryId
          });
        }
        // 위 네 저장 중 하나라도 실패하면 inTransaction이 전체를 ROLLBACK합니다.
        return { revoked, promoted };
      });
    }
  };
}
