package kr.ac.jbnu.yu.crudbackend.api.v1;

import kr.ac.jbnu.yu.crudbackend.api.dto.ApiResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/server-status")
public class ServerStatusController {

    @GetMapping("/error")
    public ResponseEntity<ApiResponse<String>> internalServerError() {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.of(
                        HttpStatus.INTERNAL_SERVER_ERROR.value(),
                        "서버 내부 오류 테스트입니다."
                ));
    }

    @GetMapping("/unavailable")
    public ResponseEntity<ApiResponse<String>> serviceUnavailable() {
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(ApiResponse.of(
                        HttpStatus.SERVICE_UNAVAILABLE.value(),
                        "현재 서비스를 사용할 수 없습니다."
                ));
    }
}
