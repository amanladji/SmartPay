package com.smartpay.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
public class SetPinRequest {
    @NotBlank(message = "UPI PIN is required")
    @Pattern(regexp = "^\\d{4,6}$", message = "UPI PIN must be 4 to 6 digits")
    private String upiPin;
}
