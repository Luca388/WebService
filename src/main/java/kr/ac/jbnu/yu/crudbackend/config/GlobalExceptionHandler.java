package kr.ac.jbnu.yu.crudbackend.config;

import kr.ac.jbnu.yu.crudbackend.api.dto.ApiResponse;
import kr.ac.jbnu.yu.crudbackend.exception.ServiceUnavailableException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ServiceUnavailableException.class)
    public ResponseEntity<ApiResponse<String>> handleServiceUnavailable(
            ServiceUnavailableException exception
    ) {
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(ApiResponse.of(
                        HttpStatus.SERVICE_UNAVAILABLE.value(),
                        exception.getMessage()
                ));
    }

    @ExceptionHandler({
            HttpMessageNotReadableException.class,
            MethodArgumentTypeMismatchException.class
    })
    public ResponseEntity<ApiResponse<String>> handleBadRequest(Exception exception) {
        return ResponseEntity.badRequest()
                .body(ApiResponse.of(
                        HttpStatus.BAD_REQUEST.value(),
                        "요청 형식이 올바르지 않습니다."
                ));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<String>> handleException(Exception exception) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.of(
                        HttpStatus.INTERNAL_SERVER_ERROR.value(),
                        "서버 내부에서 오류가 발생했습니다."
                ));
    }
}
