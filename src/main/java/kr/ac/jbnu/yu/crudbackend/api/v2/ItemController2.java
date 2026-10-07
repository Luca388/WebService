package kr.ac.jbnu.yu.crudbackend.api.v2;

import kr.ac.jbnu.yu.crudbackend.api.dto.ApiResponse;
import kr.ac.jbnu.yu.crudbackend.api.dto.ItemDto;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v2/items")
public class ItemController2 {

    private final List<ItemDto> items = List.of(
            new ItemDto(1L, "노트북", 1_500_000),
            new ItemDto(2L, "마우스", 30_000),
            new ItemDto(3L, "키보드", 80_000)
    );

    @GetMapping("/search")
    public ResponseEntity<ApiResponse<?>> searchItems(
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        if (page < 0 || size <= 0) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.of(
                            HttpStatus.BAD_REQUEST.value(),
                            "page는 0 이상, size는 1 이상이어야 합니다."
                    ));
        }

        List<ItemDto> result = items.stream()
                .filter(item -> keyword == null || item.getName().contains(keyword))
                .skip((long) page * size)
                .limit(size)
                .toList();

        return ResponseEntity.ok(ApiResponse.of(HttpStatus.OK.value(), result));
    }
}
