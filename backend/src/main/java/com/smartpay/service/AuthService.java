package com.smartpay.service;

import com.smartpay.config.JwtUtil;
import com.smartpay.dto.request.LoginRequest;
import com.smartpay.dto.request.RegisterRequest;
import com.smartpay.dto.response.AuthResponse;
import com.smartpay.exception.InvalidTransactionException;
import com.smartpay.model.User;
import com.smartpay.model.Wallet;
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
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

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

        String token = jwtUtil.generateToken(user.getEmail());
        return AuthResponse.builder()
                .token(token)
                .message("Registration successful. Your UPI ID: " + upiId)
                .expiresIn(86400000)
                .build();
    }

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadCredentialsException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new BadCredentialsException("Invalid email or password");
        }

        String token = jwtUtil.generateToken(user.getEmail());
        return AuthResponse.builder()
                .token(token)
                .message("Login successful")
                .expiresIn(86400000)
                .build();
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
