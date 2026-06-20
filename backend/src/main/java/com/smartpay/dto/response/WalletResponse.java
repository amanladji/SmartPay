package com.smartpay.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;

@Data
@Builder
@AllArgsConstructor
public class WalletResponse {
    private String id;
    private String upiId;
    private BigDecimal balance;
    private String userName;
}
