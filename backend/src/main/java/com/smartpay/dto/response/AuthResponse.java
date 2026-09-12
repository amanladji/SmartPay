package com.smartpay.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class AuthResponse {
    private String token;
    private String refreshToken;
    private String message;
    private long expiresIn;
    private boolean pinSet;
    private boolean requiresOtp;
    private String otp;
}
