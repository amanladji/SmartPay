package com.smartpay.repository;

import com.smartpay.model.User;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.Optional;

public interface UserRepository extends MongoRepository<User, String> {
    Optional<User> findByEmail(String email);
    Optional<User> findByPhone(String phone);
    Optional<User> findByUpiId(String upiId);
    boolean existsByEmail(String email);
    boolean existsByPhone(String phone);
    boolean existsByUpiId(String upiId);
}
