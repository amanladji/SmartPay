package com.smartpay.controller;

import com.smartpay.dto.request.SetPinRequest;
import com.smartpay.dto.request.VerifyPinRequest;
import com.smartpay.dto.response.ApiResponse;
import com.smartpay.dto.response.SessionResponse;
import com.smartpay.dto.response.UserProfileResponse;
import com.smartpay.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserProfileResponse>> getProfile(
            @AuthenticationPrincipal UserDetails userDetails) {
        UserProfileResponse profile = userService.getProfile(userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.success("Profile fetched successfully", profile));
    }

    @PostMapping("/set-pin")
    public ResponseEntity<ApiResponse<Void>> setPin(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody SetPinRequest request) {
        userService.setPin(userDetails.getUsername(), request.getUpiPin());
        return ResponseEntity.ok(ApiResponse.success("UPI PIN set successfully", null));
    }

    @PostMapping("/verify-pin")
    public ResponseEntity<ApiResponse<Void>> verifyPin(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody VerifyPinRequest request) {
        userService.verifyPin(userDetails.getUsername(), request.getUpiPin());
        return ResponseEntity.ok(ApiResponse.success("UPI PIN verified", null));
    }

    @GetMapping("/sessions")
    public ResponseEntity<ApiResponse<List<SessionResponse>>> getSessions(
            @AuthenticationPrincipal UserDetails userDetails) {
        List<SessionResponse> sessions = userService.getSessions(userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.success("Sessions fetched", sessions));
    }

    @DeleteMapping("/sessions/{deviceId}")
    public ResponseEntity<ApiResponse<Void>> revokeSession(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable String deviceId) {
        userService.revokeSession(userDetails.getUsername(), deviceId);
        return ResponseEntity.ok(ApiResponse.success("Session revoked", null));
    }

    @DeleteMapping("/sessions")
    public ResponseEntity<ApiResponse<Void>> revokeAllSessions(
            @AuthenticationPrincipal UserDetails userDetails) {
        userService.revokeAllSessions(userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.success("All sessions revoked", null));
    }
}
