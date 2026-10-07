package kr.ac.jbnu.yu.crudbackend.api.v1;

import kr.ac.jbnu.yu.crudbackend.api.dto.ApiResponse;
import kr.ac.jbnu.yu.crudbackend.api.dto.ItemDto;
import kr.ac.jbnu.yu.crudbackend.api.request.ItemCreateRequest;
import kr.ac.jbnu.yu.crudbackend.api.request.ItemUpdateRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/items")
public class ItemController {

    private final Map<Long, ItemDto> store = new LinkedHashMap<>();
    private long sequence = 0L;

    public ItemController() {
        saveItem("노트북", 1_500_000);
        saveItem("마우스", 30_000);
    }

    @GetMapping
    public ResponseEntity<ApiResponse<?>> getItems() {
        List<ItemDto> items = new ArrayList<>(store.values());
        return ok(items);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<?>> getItem(@PathVariable Long id) {
        ItemDto item = store.get(id);

        if (item == null) {
            return notFound(id);
        }

        return ok(item);
    }

    @PostMapping
    public ResponseEntity<ApiResponse<?>> createItem(@RequestBody ItemCreateRequest request) {
        String validationMessage = validateItem(request.getName(), request.getPrice());

        if (validationMessage != null) {
            return badRequest(validationMessage);
        }

        ItemDto item = saveItem(request.getName(), request.getPrice());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.of(HttpStatus.CREATED.value(), item));
    }

    @PostMapping("/sample")
    public ResponseEntity<ApiResponse<?>> createSampleItem() {
        ItemDto item = saveItem("샘플 상품", 1_000);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.of(HttpStatus.CREATED.value(), item));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<?>> updateItem(
            @PathVariable Long id,
            @RequestBody ItemUpdateRequest request
    ) {
        ItemDto item = store.get(id);

        if (item == null) {
            return notFound(id);
        }

        if (request.getName() == null && request.getPrice() == null) {
            return badRequest("수정할 name 또는 price를 입력해야 합니다.");
        }

        if (request.getName() != null) {
            if (request.getName().isBlank()) {
                return badRequest("상품 이름은 비어 있을 수 없습니다.");
            }
            item.setName(request.getName());
        }

        if (request.getPrice() != null) {
            if (request.getPrice() < 0) {
                return badRequest("상품 가격은 0 이상이어야 합니다.");
            }
            item.setPrice(request.getPrice());
        }

        return ok(item);
    }

    @PutMapping("/{id}/price")
    public ResponseEntity<ApiResponse<?>> updateItemPrice(
            @PathVariable Long id,
            @RequestBody ItemUpdateRequest request
    ) {
        ItemDto item = store.get(id);

        if (item == null) {
            return notFound(id);
        }

        if (request.getPrice() == null || request.getPrice() < 0) {
            return badRequest("0 이상의 price를 입력해야 합니다.");
        }

        item.setPrice(request.getPrice());
        return ok(item);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<?>> deleteItem(@PathVariable Long id) {
        ItemDto removedItem = store.remove(id);

        if (removedItem == null) {
            return notFound(id);
        }

        return ok(removedItem);
    }

    @DeleteMapping
    public ResponseEntity<ApiResponse<?>> deleteAllItems() {
        int deletedCount = store.size();
        store.clear();

        Map<String, Integer> result = Map.of("deletedCount", deletedCount);
        return ok(result);
    }

    private ItemDto saveItem(String name, int price) {
        ItemDto item = new ItemDto(++sequence, name, price);
        store.put(item.getId(), item);
        return item;
    }

    private String validateItem(String name, Integer price) {
        if (name == null || name.isBlank()) {
            return "상품 이름을 입력해야 합니다.";
        }
        if (price == null || price < 0) {
            return "상품 가격은 0 이상이어야 합니다.";
        }
        return null;
    }

    private ResponseEntity<ApiResponse<?>> ok(Object data) {
        return ResponseEntity.ok(ApiResponse.of(HttpStatus.OK.value(), data));
    }

    private ResponseEntity<ApiResponse<?>> badRequest(String message) {
        return ResponseEntity.badRequest()
                .body(ApiResponse.of(HttpStatus.BAD_REQUEST.value(), message));
    }

    private ResponseEntity<ApiResponse<?>> notFound(Long id) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.of(
                        HttpStatus.NOT_FOUND.value(),
                        "ID가 " + id + "인 상품을 찾을 수 없습니다."
                ));
    }
}
