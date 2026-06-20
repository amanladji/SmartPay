package com.smartpay.controller;

import com.smartpay.dto.request.TransferRequest;
import com.smartpay.dto.response.ApiResponse;
import com.smartpay.dto.response.TransactionResponse;
import com.smartpay.service.PaymentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final PaymentService paymentService;

    @PostMapping("/transfer")
    public ResponseEntity<ApiResponse<TransactionResponse>> transfer(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody TransferRequest request) {
        TransactionResponse response = paymentService.transferMoney(
                userDetails.getUsername(), request);
        return ResponseEntity.ok(ApiResponse.success("Transfer successful", response));
    }

    @GetMapping("/qr")
    public ResponseEntity<ApiResponse<Map<String, String>>> generateQr(
            @RequestParam String upiId,
            @RequestParam double amount) {
        Map<String, String> qrData = new HashMap<>();
        qrData.put("upiId", upiId);
        qrData.put("amount", String.valueOf(amount));
        qrData.put("qrPayload", "upi://pay?pa=" + upiId + "&am=" + amount + "&tn=SmartPay");
        return ResponseEntity.ok(ApiResponse.success("QR data generated", qrData));
    }

    @PostMapping("/qr/pay")
    public ResponseEntity<ApiResponse<TransactionResponse>> payViaQr(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody TransferRequest request) {
        TransactionResponse response = paymentService.processQrPayment(
                userDetails.getUsername(), request);
        return ResponseEntity.ok(ApiResponse.success("QR payment successful", response));
    }
}
