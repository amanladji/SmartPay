package com.smartpay.service;

public interface SmsService {
    void sendOtp(String phone, String otp);
}
