package kr.ac.jbnu.yu.crudbackend.api.v3;

import kr.ac.jbnu.yu.crudbackend.api.dto.ApiResponse;
import kr.ac.jbnu.yu.crudbackend.api.request.ItemCreateRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v3/items")
public class ItemController3 {

    @PostMapping("/with-header")
    public ResponseEntity<ApiResponse<Map<String, Object>>> createItemWithHeader(
            @RequestBody ItemCreateRequest request,
            @RequestHeader(value = "X-USER-ID", required = false) String userId,
            @RequestHeader(value = "Authorization", required = false) String authorization
    ) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("name", request.getName());
        result.put("price", request.getPrice());
        result.put("userId", userId);
        result.put("authorization", authorization);

        return ResponseEntity.ok(ApiResponse.of(HttpStatus.OK.value(), result));
    }
}
