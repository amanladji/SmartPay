package com.smartpay.service;

import com.smartpay.config.JwtUtil;
import com.smartpay.dto.request.LoginRequest;
import com.smartpay.dto.request.RefreshTokenRequest;
import com.smartpay.dto.request.RegisterRequest;
import com.smartpay.dto.request.VerifyOtpRequest;
import com.smartpay.dto.response.AuthResponse;
import com.smartpay.exception.InvalidTransactionException;
import com.smartpay.model.Device;
import com.smartpay.model.RefreshToken;
import com.smartpay.model.User;
import com.smartpay.model.Wallet;
import com.smartpay.repository.DeviceRepository;
import com.smartpay.repository.RefreshTokenRepository;
import com.smartpay.repository.UserRepository;
import com.smartpay.repository.WalletRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Random;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final WalletRepository walletRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final DeviceRepository deviceRepository;
    private final OtpService otpService;
    private final RateLimitingService rateLimitingService;
    private final SmsService smsService;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    private AuthResponse buildAuthResponse(User user, String message) {
        String accessToken = jwtUtil.generateAccessToken(user.getEmail());
        String refreshToken = jwtUtil.generateRefreshToken(user.getEmail());

        refreshTokenRepository.deleteByEmail(user.getEmail());
        refreshTokenRepository.save(RefreshToken.builder()
                .token(refreshToken)
                .email(user.getEmail())
                .expiryDate(LocalDateTime.now().plusSeconds(jwtUtil.getRefreshExpirationMs() / 1000))
                .createdAt(LocalDateTime.now())
                .build());

        return AuthResponse.builder()
                .token(accessToken)
                .refreshToken(refreshToken)
                .message(message)
                .expiresIn(jwtUtil.getAccessExpirationMs())
                .pinSet(user.getUpiPin() != null)
                .build();
    }

    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new InvalidTransactionException("Email is already registered");
        }
        if (userRepository.existsByPhone(request.getPhone())) {
            throw new InvalidTransactionException("Phone is already registered");
        }

        String upiId = generateUpiId(request.getName());

        User user = User.builder()
                .name(request.getName())
                .email(request.getEmail())
                .phone(request.getPhone())
                .upiId(upiId)
                .password(passwordEncoder.encode(request.getPassword()))
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        user = userRepository.save(user);

        Wallet wallet = Wallet.builder()
                .userId(user.getId())
                .balance(BigDecimal.ZERO)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        walletRepository.save(wallet);

        if (request.getDeviceId() != null) {
            deviceRepository.save(Device.builder()
                    .email(user.getEmail())
                    .deviceId(request.getDeviceId())
                    .deviceName(request.getDeviceName())
                    .trusted(true)
                    .lastLogin(LocalDateTime.now())
                    .createdAt(LocalDateTime.now())
                    .build());
        }

        return buildAuthResponse(user, "Registration successful. Your UPI ID: " + upiId);
    }

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadCredentialsException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new BadCredentialsException("Invalid email or password");
        }

        rateLimitingService.resetAttempts("/api/auth/login:" + user.getEmail());

        if (request.getDeviceId() != null) {
            Device existingDevice = deviceRepository.findByEmailAndDeviceId(
                    user.getEmail(), request.getDeviceId()).orElse(null);

            if (existingDevice != null && existingDevice.isTrusted()) {
                existingDevice.setLastLogin(LocalDateTime.now());
                deviceRepository.save(existingDevice);
                rateLimitingService.resetAttempts("/api/auth/login:" + user.getEmail());
                return buildAuthResponse(user, "Login successful");
            }

            if (existingDevice == null) {
                deviceRepository.save(Device.builder()
                        .email(user.getEmail())
                        .deviceId(request.getDeviceId())
                        .deviceName(request.getDeviceName())
                        .trusted(false)
                        .lastLogin(LocalDateTime.now())
                        .createdAt(LocalDateTime.now())
                        .build());
            }

            String otp = otpService.generateOtp(user.getPhone());
            smsService.sendOtp(user.getPhone(), otp);
            return AuthResponse.builder()
                    .requiresOtp(true)
                    .otp(otp)
                    .message("OTP sent to your registered phone")
                    .pinSet(user.getUpiPin() != null)
                    .build();
        }

        return buildAuthResponse(user, "Login successful");
    }

    public AuthResponse verifyOtpAndLogin(VerifyOtpRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadCredentialsException("User not found"));

        otpService.verifyOtp(user.getPhone(), request.getOtp());

        Device device = deviceRepository.findByEmailAndDeviceId(
                user.getEmail(), request.getDeviceId()).orElse(null);

        if (device == null) {
            device = Device.builder()
                    .email(request.getEmail())
                    .deviceId(request.getDeviceId())
                    .deviceName(request.getDeviceName())
                    .createdAt(LocalDateTime.now())
                    .build();
        }

        device.setTrusted(true);
        device.setLastLogin(LocalDateTime.now());
        deviceRepository.save(device);

        return buildAuthResponse(user, "Login successful");
    }

    public AuthResponse refresh(RefreshTokenRequest request) {
        RefreshToken storedToken = refreshTokenRepository.findByToken(request.getRefreshToken())
                .orElseThrow(() -> new BadCredentialsException("Invalid refresh token"));

        if (storedToken.isRevoked()) {
            throw new BadCredentialsException("Refresh token has been revoked");
        }

        if (storedToken.getExpiryDate().isBefore(LocalDateTime.now())) {
            throw new BadCredentialsException("Refresh token has expired");
        }

        if (!jwtUtil.isTokenValid(storedToken.getToken())) {
            throw new BadCredentialsException("Refresh token is invalid");
        }

        String email = jwtUtil.extractEmail(storedToken.getToken());
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new BadCredentialsException("User not found"));

        storedToken.setRevoked(true);
        refreshTokenRepository.save(storedToken);

        return buildAuthResponse(user, "Token refreshed successfully");
    }

    private String generateUpiId(String name) {
        String base = name.toLowerCase().replaceAll("\\s+", "");
        String suffix = String.valueOf(1000 + new Random().nextInt(9000));
        String upiId = base + suffix + "@smartpay";

        while (userRepository.existsByUpiId(upiId)) {
            suffix = String.valueOf(1000 + new Random().nextInt(9000));
            upiId = base + suffix + "@smartpay";
        }
        return upiId;
    }
}
