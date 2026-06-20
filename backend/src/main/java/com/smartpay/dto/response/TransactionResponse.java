package com.smartpay.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;

@Data
@Builder
@AllArgsConstructor
public class TransactionResponse {
    private String id;
    private String senderUpiId;
    private String receiverUpiId;
    private BigDecimal amount;
    private String type;
    private String status;
    private String description;
    private String referenceId;
    private String createdAt;
}
