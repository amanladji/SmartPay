# SmartPay Feature Manifest

Use this file to track which features have been implemented.
To undo a feature, say: "undo feature [FEATURE_NAME]"

---

## Feature: upi-pin
**Status:** implemented
**Files created:**
- backend/.../exception/InvalidPinException.java
- backend/.../dto/request/SetPinRequest.java
- backend/.../dto/request/VerifyPinRequest.java
- frontend/src/pages/SetUpiPin.jsx
**Files modified:**
- backend/.../model/User.java — added `upiPin` field
- backend/.../dto/response/UserProfileResponse.java — added `pinSet` field
- backend/.../dto/response/AuthResponse.java — added `pinSet` field
- backend/.../dto/request/TransferRequest.java — added `upiPin` field
- backend/.../service/UserService.java — added setPin/verifyPin methods
- backend/.../controller/UserController.java — added /set-pin, /verify-pin endpoints
- backend/.../service/PaymentService.java — added PIN verification before transfer
- backend/.../service/AuthService.java — return pinSet in register/login
- backend/.../exception/GlobalExceptionHandler.java — added InvalidPinException handler
- frontend/src/context/AuthContext.jsx — pinSet state, refreshPinStatus
- frontend/src/pages/SendMoney.jsx — PIN dialog before sending
- frontend/src/pages/QRPayment.jsx — PIN dialog before QR payment
- frontend/src/pages/Dashboard.jsx — PIN setup banner
- frontend/src/pages/Profile.jsx — PIN status display
- frontend/src/App.jsx — added /set-pin route

---

## Feature: jwt-refresh-tokens
**Status:** implemented
**Files created:**
- backend/.../model/RefreshToken.java
- backend/.../repository/RefreshTokenRepository.java
- backend/.../dto/request/RefreshTokenRequest.java
**Files modified:**
- backend/.../config/JwtUtil.java — added generateAccessToken, generateRefreshToken, getAccessExpirationMs, getRefreshExpirationMs; changed constructor to accept refresh-expiration
- backend/.../dto/response/AuthResponse.java — added `refreshToken` field
- backend/.../service/AuthService.java — added buildAuthResponse helper, refresh() method; store refresh tokens in DB; revoke old tokens
- backend/.../controller/AuthController.java — added POST /api/auth/refresh endpoint
- backend/.../resources/application.yml — changed expiration to 900000 (15min), added refresh-expiration: 604800000 (7 days)
- frontend/src/api/axios.js — added 401 interceptor with token refresh queue
- frontend/src/context/AuthContext.jsx — store refreshToken, storeTokens helper, clear refreshToken on logout

---

## Feature: otp-device-binding
**Status:** implemented
**Files created:**
- backend/.../model/Device.java
- backend/.../repository/DeviceRepository.java
- frontend/src/pages/OtpVerification.jsx
**Files modified:**
- backend/.../dto/request/LoginRequest.java — added deviceId, deviceName fields
- backend/.../service/OtpService.java — in-memory 6-digit OTP with 5 min expiry
- backend/.../service/AuthService.java — login checks device trust, generates OTP for new devices; verifyOtpAndLogin trusts device
- backend/.../controller/AuthController.java — added /verify-otp endpoint
- backend/.../dto/response/AuthResponse.java — added requiresOtp, otp fields
- frontend/src/context/AuthContext.jsx — login() returns raw data, verifyOtp() added
- frontend/src/pages/Login.jsx — getDeviceId(), pass device params to login, navigate to verify-otp
- frontend/src/App.jsx — added /verify-otp route

---

## Feature: rate-limiting
**Status:** implemented
**Files created:**
- backend/.../config/RateLimitingFilter.java
- backend/.../service/RateLimitingService.java
**Files modified:**
- backend/.../config/SecurityConfig.java — added RateLimitingFilter
- backend/.../service/AuthService.java — rate limiting on login/verifyOtp
- backend/.../service/UserService.java — rate limiting on PIN verify
- backend/.../exception/GlobalExceptionHandler.java — handle rate limit errors

---

## Feature: otp-via-phone
**Status:** implemented
**Files modified:**
- backend/.../service/OtpService.java — OTP stored/verified by phone key (not email)
- backend/.../service/AuthService.java — login generates OTP via user.getPhone(); verifyOtpAndLogin verifies by phone
- backend/.../config/RateLimitingFilter.java — extracts phone from body (falls back to email)
- frontend/src/pages/OtpVerification.jsx — message: "registered phone number"
- frontend/src/pages/Login.jsx — message: "OTP sent to your registered phone"

---

## Feature: sms-service
**Status:** implemented
**Files created:**
- backend/.../service/SmsService.java — interface with sendOtp(String phone, String otp)
- backend/.../service/ConsoleSmsService.java — @Profile("default") impl; logs to console + sms.log with +91 format
- backend/src/main/resources/logback-spring.xml — SMS_LOGGER appender to logs/sms.log
**Files modified:**
- backend/.../dto/response/AuthResponse.java — removed otp field (OTP no longer in API response)
- backend/.../service/AuthService.java — inject SmsService; call smsService.sendOtp() after generateOtp(); remove .otp() from response builder
- frontend/src/pages/Login.jsx — removed otp from navigate state
- frontend/src/pages/OtpVerification.jsx — removed mock SMS banner (no OTP shown in UI)
- test-phone-otp.ps1 — extract OTP from sms.log instead of API response; register with deviceId
