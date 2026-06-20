package com.smartpay.service;

import com.smartpay.dto.request.TransferRequest;
import com.smartpay.dto.response.TransactionResponse;
import com.smartpay.exception.InsufficientBalanceException;
import com.smartpay.exception.InvalidTransactionException;
import com.smartpay.exception.ResourceNotFoundException;
import com.smartpay.model.Transaction;
import com.smartpay.model.User;
import com.smartpay.model.Wallet;
import com.smartpay.model.enums.TransactionStatus;
import com.smartpay.model.enums.TransactionType;
import com.smartpay.repository.TransactionRepository;
import com.smartpay.repository.UserRepository;
import com.smartpay.repository.WalletRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PaymentService {

    private final UserRepository userRepository;
    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;

    public TransactionResponse transferMoney(String senderEmail, TransferRequest request) {
        User sender = userRepository.findByEmail(senderEmail)
                .orElseThrow(() -> new ResourceNotFoundException("Sender not found"));
        User receiver = userRepository.findByUpiId(request.getReceiverUpiId())
                .orElseThrow(() -> new ResourceNotFoundException("Receiver UPI ID not found"));

        if (sender.getUpiId().equals(request.getReceiverUpiId())) {
            throw new InvalidTransactionException("Cannot send money to yourself");
        }
        if (request.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new InvalidTransactionException("Amount must be greater than zero");
        }

        Wallet senderWallet = walletRepository.findByUserId(sender.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Sender wallet not found"));

        if (senderWallet.getBalance().compareTo(request.getAmount()) < 0) {
            throw new InsufficientBalanceException("Insufficient balance");
        }

        Wallet receiverWallet = walletRepository.findByUserId(receiver.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Receiver wallet not found"));

        senderWallet.setBalance(senderWallet.getBalance().subtract(request.getAmount()));
        senderWallet.setUpdatedAt(LocalDateTime.now());
        walletRepository.save(senderWallet);

        receiverWallet.setBalance(receiverWallet.getBalance().add(request.getAmount()));
        receiverWallet.setUpdatedAt(LocalDateTime.now());
        walletRepository.save(receiverWallet);

        String referenceId = UUID.randomUUID().toString();

        Transaction debitTxn = Transaction.builder()
                .senderUpiId(sender.getUpiId())
                .receiverUpiId(receiver.getUpiId())
                .amount(request.getAmount())
                .type(TransactionType.DEBIT)
                .status(TransactionStatus.SUCCESS)
                .description(request.getDescription())
                .referenceId(referenceId)
                .createdAt(LocalDateTime.now())
                .build();
        transactionRepository.save(debitTxn);

        Transaction creditTxn = Transaction.builder()
                .senderUpiId(sender.getUpiId())
                .receiverUpiId(receiver.getUpiId())
                .amount(request.getAmount())
                .type(TransactionType.CREDIT)
                .status(TransactionStatus.SUCCESS)
                .description(request.getDescription())
                .referenceId(referenceId)
                .createdAt(LocalDateTime.now())
                .build();
        transactionRepository.save(creditTxn);

        return TransactionResponse.builder()
                .id(debitTxn.getId())
                .senderUpiId(sender.getUpiId())
                .receiverUpiId(receiver.getUpiId())
                .amount(request.getAmount())
                .type("DEBIT")
                .status("SUCCESS")
                .description(request.getDescription())
                .referenceId(referenceId)
                .createdAt(debitTxn.getCreatedAt().toString())
                .build();
    }

    public TransactionResponse processQrPayment(String senderEmail, TransferRequest request) {
        request.setDescription("QR Payment");
        return transferMoney(senderEmail, request);
    }
}
