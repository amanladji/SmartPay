package com.smartpay.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
@AllArgsConstructor
public class TransactionPageResponse {
    private List<TransactionResponse> content;
    private int totalPages;
    private long totalElements;
    private int currentPage;
    private int pageSize;
}
