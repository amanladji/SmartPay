package com.smartpay.repository;

import com.smartpay.model.Device;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;
import java.util.Optional;

public interface DeviceRepository extends MongoRepository<Device, String> {
    List<Device> findByEmail(String email);
    Optional<Device> findByEmailAndDeviceId(String email, String deviceId);
}
