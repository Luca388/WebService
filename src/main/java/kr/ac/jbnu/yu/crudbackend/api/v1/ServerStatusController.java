package kr.ac.jbnu.yu.crudbackend.api.v1;

import kr.ac.jbnu.yu.crudbackend.api.dto.ApiResponse;
import kr.ac.jbnu.yu.crudbackend.exception.ServiceUnavailableException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/server-status")
public class ServerStatusController {

    @GetMapping("/error")
    public ResponseEntity<ApiResponse<String>> internalServerError() {
        throw new IllegalStateException("서버 내부 오류 확인용 예외입니다.");
    }

    @GetMapping("/unavailable")
    public ResponseEntity<ApiResponse<String>> serviceUnavailable() {
        throw new ServiceUnavailableException("현재 상품 서비스를 사용할 수 없습니다.");
    }
}
