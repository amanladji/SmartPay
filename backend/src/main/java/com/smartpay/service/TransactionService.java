package com.smartpay.service;

import com.smartpay.dto.response.TransactionPageResponse;
import com.smartpay.dto.response.TransactionResponse;
import com.smartpay.exception.ResourceNotFoundException;
import com.smartpay.model.Transaction;
import com.smartpay.model.User;
import com.smartpay.repository.TransactionRepository;
import com.smartpay.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final UserRepository userRepository;

    public TransactionPageResponse getTransactionHistory(String email, int page, int size,
                                                          String type, String status) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        Pageable pageable = PageRequest.of(page, size);
        Page<Transaction> transactionPage;

        if (type != null && !type.isEmpty()) {
            if (type.equalsIgnoreCase("CREDIT")) {
                transactionPage = transactionRepository
                        .findByReceiverUpiIdAndTypeOrderByCreatedAtDesc(
                                user.getUpiId(), "CREDIT", pageable);
            } else {
                transactionPage = transactionRepository
                        .findBySenderUpiIdAndTypeOrderByCreatedAtDesc(
                                user.getUpiId(), "DEBIT", pageable);
            }
        } else {
            transactionPage = transactionRepository
                    .findBySenderUpiIdOrReceiverUpiIdOrderByCreatedAtDesc(
                            user.getUpiId(), user.getUpiId(), pageable);
        }

        List<TransactionResponse> content = transactionPage.getContent().stream()
                .map(this::toTransactionResponse)
                .collect(Collectors.toList());

        return TransactionPageResponse.builder()
                .content(content)
                .totalPages(transactionPage.getTotalPages())
                .totalElements(transactionPage.getTotalElements())
                .currentPage(page)
                .pageSize(size)
                .build();
    }

    public Map<String, Object> getStats(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        List<Transaction> sentTxns = transactionRepository
                .findBySenderUpiIdAndTypeAndStatus(user.getUpiId(), "DEBIT", "SUCCESS");
        List<Transaction> receivedTxns = transactionRepository
                .findByReceiverUpiIdAndTypeAndStatus(user.getUpiId(), "CREDIT", "SUCCESS");

        BigDecimal totalSent = sentTxns.stream()
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal totalReceived = receivedTxns.stream()
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalSent", totalSent.doubleValue());
        stats.put("totalReceived", totalReceived.doubleValue());
        stats.put("sentCount", sentTxns.size());
        stats.put("receivedCount", receivedTxns.size());

        Map<Integer, Map<String, Object>> monthlySent = new HashMap<>();
        for (Transaction txn : sentTxns) {
            int month = txn.getCreatedAt().getMonthValue();
            monthlySent.putIfAbsent(month, new HashMap<>());
            Map<String, Object> m = monthlySent.get(month);
            m.put("month", month);
            m.put("total", ((Number) m.getOrDefault("total", 0.0)).doubleValue() + txn.getAmount().doubleValue());
            m.put("count", ((Number) m.getOrDefault("count", 0)).intValue() + 1);
        }
        stats.put("monthlySent", monthlySent.values());

        Map<Integer, Map<String, Object>> monthlyReceived = new HashMap<>();
        for (Transaction txn : receivedTxns) {
            int month = txn.getCreatedAt().getMonthValue();
            monthlyReceived.putIfAbsent(month, new HashMap<>());
            Map<String, Object> m = monthlyReceived.get(month);
            m.put("month", month);
            m.put("total", ((Number) m.getOrDefault("total", 0.0)).doubleValue() + txn.getAmount().doubleValue());
            m.put("count", ((Number) m.getOrDefault("count", 0)).intValue() + 1);
        }
        stats.put("monthlyReceived", monthlyReceived.values());

        return stats;
    }

    private TransactionResponse toTransactionResponse(Transaction txn) {
        return TransactionResponse.builder()
                .id(txn.getId())
                .senderUpiId(txn.getSenderUpiId())
                .receiverUpiId(txn.getReceiverUpiId())
                .amount(txn.getAmount())
                .type(txn.getType().name())
                .status(txn.getStatus().name())
                .description(txn.getDescription())
                .referenceId(txn.getReferenceId())
                .createdAt(txn.getCreatedAt() != null ? txn.getCreatedAt().toString() : null)
                .build();
    }
}
