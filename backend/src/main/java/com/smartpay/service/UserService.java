package com.smartpay.service;

import com.smartpay.dto.response.SessionResponse;
import com.smartpay.dto.response.UserProfileResponse;
import com.smartpay.exception.InvalidPinException;
import com.smartpay.exception.ResourceNotFoundException;
import com.smartpay.model.Device;
import com.smartpay.model.User;
import com.smartpay.repository.DeviceRepository;
import com.smartpay.repository.RefreshTokenRepository;
import com.smartpay.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final DeviceRepository deviceRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final RateLimitingService rateLimitingService;
    private final PasswordEncoder passwordEncoder;

    public UserProfileResponse getProfile(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        return UserProfileResponse.builder()
                .id(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .upiId(user.getUpiId())
                .createdAt(user.getCreatedAt() != null ? user.getCreatedAt().toString() : null)
                .pinSet(user.getUpiPin() != null)
                .build();
    }

    public void setPin(String email, String upiPin) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        user.setUpiPin(passwordEncoder.encode(upiPin));
        userRepository.save(user);
    }

    public void verifyPin(String email, String upiPin) {
        String rateLimitKey = "pin-verify:" + email;
        if (!rateLimitingService.isAllowed(rateLimitKey)) {
            throw new InvalidPinException("Too many incorrect PIN attempts. Please try again after 15 minutes");
        }

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        if (user.getUpiPin() == null) {
            throw new InvalidPinException("UPI PIN not set. Please set your PIN first");
        }
        if (!passwordEncoder.matches(upiPin, user.getUpiPin())) {
            rateLimitingService.recordAttempt(rateLimitKey);
            throw new InvalidPinException("Invalid UPI PIN");
        }

        rateLimitingService.resetAttempts(rateLimitKey);
    }

    public List<SessionResponse> getSessions(String email) {
        List<Device> devices = deviceRepository.findByEmail(email);
        return devices.stream()
                .map(d -> SessionResponse.builder()
                        .deviceId(d.getDeviceId())
                        .deviceName(d.getDeviceName())
                        .trusted(d.isTrusted())
                        .lastLogin(d.getLastLogin() != null ? d.getLastLogin().toString() : null)
                        .createdAt(d.getCreatedAt() != null ? d.getCreatedAt().toString() : null)
                        .build())
                .toList();
    }

    public void revokeSession(String email, String deviceId) {
        Device device = deviceRepository.findByEmailAndDeviceId(email, deviceId)
                .orElseThrow(() -> new ResourceNotFoundException("Session not found"));
        deviceRepository.deleteById(device.getId());
    }

    public void revokeAllSessions(String email) {
        List<Device> devices = deviceRepository.findByEmail(email);
        deviceRepository.deleteAll(devices);
        refreshTokenRepository.deleteByEmail(email);
    }
}
