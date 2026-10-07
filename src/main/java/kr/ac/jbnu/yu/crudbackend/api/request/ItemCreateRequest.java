package kr.ac.jbnu.yu.crudbackend.api.request;

import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class ItemCreateRequest {

    private String name;
    private Integer price;
}
