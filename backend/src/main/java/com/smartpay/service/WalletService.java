package com.smartpay.service;

import com.smartpay.dto.request.AddBalanceRequest;
import com.smartpay.dto.response.WalletResponse;
import com.smartpay.exception.ResourceNotFoundException;
import com.smartpay.model.User;
import com.smartpay.model.Wallet;
import com.smartpay.repository.UserRepository;
import com.smartpay.repository.WalletRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class WalletService {

    private final WalletRepository walletRepository;
    private final UserRepository userRepository;

    public WalletResponse getBalance(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        Wallet wallet = walletRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Wallet not found"));

        return WalletResponse.builder()
                .id(wallet.getId())
                .upiId(user.getUpiId())
                .balance(wallet.getBalance())
                .userName(user.getName())
                .build();
    }

    public WalletResponse addBalance(String email, AddBalanceRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        Wallet wallet = walletRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Wallet not found"));

        wallet.setBalance(wallet.getBalance().add(request.getAmount()));
        wallet.setUpdatedAt(LocalDateTime.now());
        walletRepository.save(wallet);

        return WalletResponse.builder()
                .id(wallet.getId())
                .upiId(user.getUpiId())
                .balance(wallet.getBalance())
                .userName(user.getName())
                .build();
    }
}
