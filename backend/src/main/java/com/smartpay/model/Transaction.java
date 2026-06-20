package com.smartpay.model;

import com.smartpay.model.enums.TransactionStatus;
import com.smartpay.model.enums.TransactionType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "transactions")
public class Transaction {
    @Id
    private String id;

    @Indexed
    private String senderUpiId;

    @Indexed
    private String receiverUpiId;

    private BigDecimal amount;

    private TransactionType type;

    @Builder.Default
    private TransactionStatus status = TransactionStatus.PENDING;

    private String description;

    @Indexed(unique = true)
    private String referenceId;

    @CreatedDate
    private LocalDateTime createdAt;
}
