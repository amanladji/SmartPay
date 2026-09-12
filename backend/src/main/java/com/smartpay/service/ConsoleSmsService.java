package com.smartpay.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;

@Service
@Profile("default")
public class ConsoleSmsService implements SmsService {

    private static final Logger log = LoggerFactory.getLogger(ConsoleSmsService.class);
    private static final Logger smsLog = LoggerFactory.getLogger("SMS_LOGGER");

    @Override
    public void sendOtp(String phone, String otp) {
        String formattedPhone = formatPhone(phone);
        String message = String.format(
                "[SMS] To: %s | Your SmartPay OTP is %s | Valid for 5 minutes",
                formattedPhone, otp);
        log.info(message);
        smsLog.info(message);
    }

    private String formatPhone(String phone) {
        if (phone == null) return "unknown";
        String digits = phone.replaceAll("[^0-9]", "");
        if (digits.length() == 10) {
            return "+91" + digits;
        }
        return "+" + digits;
    }
}
