package kr.ac.jbnu.yu.crudbackend.api.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class ItemDto {

    private Long id;
    private String name;
    private int price;
}
