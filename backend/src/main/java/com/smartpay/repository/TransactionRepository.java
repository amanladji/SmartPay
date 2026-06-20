package com.smartpay.repository;

import com.smartpay.model.Transaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface TransactionRepository extends MongoRepository<Transaction, String> {
    Page<Transaction> findBySenderUpiIdOrReceiverUpiIdOrderByCreatedAtDesc(
            String senderUpiId, String receiverUpiId, Pageable pageable);

    Page<Transaction> findBySenderUpiIdAndTypeOrderByCreatedAtDesc(
            String senderUpiId, String type, Pageable pageable);

    Page<Transaction> findByReceiverUpiIdAndTypeOrderByCreatedAtDesc(
            String receiverUpiId, String type, Pageable pageable);

    List<Transaction> findBySenderUpiIdAndTypeAndStatus(String senderUpiId, String type, String status);

    List<Transaction> findByReceiverUpiIdAndTypeAndStatus(String receiverUpiId, String type, String status);

    List<Transaction> findBySenderUpiId(String senderUpiId);

    List<Transaction> findByReceiverUpiId(String receiverUpiId);
}
