package kr.ac.jbnu.yu.crudbackend.api.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class ApiResponse<T> {

    private int status;
    private T data;

    public static <T> ApiResponse<T> of(int status, T data) {
        return new ApiResponse<>(status, data);
    }
}
