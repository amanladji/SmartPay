package com.smartpay.controller;

import com.smartpay.dto.response.ApiResponse;
import com.smartpay.dto.response.TransactionPageResponse;
import com.smartpay.service.TransactionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/transactions")
@RequiredArgsConstructor
public class TransactionController {

    private final TransactionService transactionService;

    @GetMapping
    public ResponseEntity<ApiResponse<TransactionPageResponse>> getTransactions(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String status) {
        TransactionPageResponse response = transactionService
                .getTransactionHistory(userDetails.getUsername(), page, size, type, status);
        return ResponseEntity.ok(ApiResponse.success("Transactions fetched successfully", response));
    }

    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getStats(
            @AuthenticationPrincipal UserDetails userDetails) {
        Map<String, Object> stats = transactionService.getStats(userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.success("Stats fetched successfully", stats));
    }
}
