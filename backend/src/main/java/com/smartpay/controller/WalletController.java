package com.smartpay.controller;

import com.smartpay.dto.request.AddBalanceRequest;
import com.smartpay.dto.response.ApiResponse;
import com.smartpay.dto.response.WalletResponse;
import com.smartpay.service.WalletService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/wallet")
@RequiredArgsConstructor
public class WalletController {

    private final WalletService walletService;

    @GetMapping("/balance")
    public ResponseEntity<ApiResponse<WalletResponse>> getBalance(
            @AuthenticationPrincipal UserDetails userDetails) {
        WalletResponse response = walletService.getBalance(userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.success("Balance fetched successfully", response));
    }

    @PostMapping("/add")
    public ResponseEntity<ApiResponse<WalletResponse>> addBalance(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody AddBalanceRequest request) {
        WalletResponse response = walletService.addBalance(userDetails.getUsername(), request);
        return ResponseEntity.ok(ApiResponse.success("Money added successfully", response));
    }
}
