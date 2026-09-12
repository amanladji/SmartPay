package com.smartpay.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class SessionResponse {
    private String deviceId;
    private String deviceName;
    private boolean trusted;
    private String lastLogin;
    private String createdAt;
}
