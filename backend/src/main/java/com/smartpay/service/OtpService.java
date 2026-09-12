package com.smartpay.service;

import com.smartpay.exception.InvalidTransactionException;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class OtpService {

    private static final long OTP_EXPIRY_SECONDS = 300;
    private final SecureRandom random = new SecureRandom();
    private final Map<String, OtpEntry> otpStore = new ConcurrentHashMap<>();

    public String generateOtp(String phone) {
        String otp = String.format("%06d", random.nextInt(1000000));
        otpStore.put(phone, new OtpEntry(otp, LocalDateTime.now().plusSeconds(OTP_EXPIRY_SECONDS)));
        return otp;
    }

    public void verifyOtp(String phone, String otp) {
        OtpEntry entry = otpStore.get(phone);
        if (entry == null) {
            throw new InvalidTransactionException("No OTP requested. Please request a new OTP");
        }
        if (entry.expiry().isBefore(LocalDateTime.now())) {
            otpStore.remove(phone);
            throw new InvalidTransactionException("OTP has expired. Please request a new OTP");
        }
        if (!entry.otp().equals(otp.trim())) {
            throw new InvalidTransactionException("Invalid OTP");
        }
        otpStore.remove(phone);
    }

    private record OtpEntry(String otp, LocalDateTime expiry) {}
}
