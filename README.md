# SmartPay — UPI Payment & Expense Tracker

> Virtual-wallet UPI demo: PIN-protected transfers, device-bound OTP via SMS abstraction, JWT refresh rotation, rate limiting and session management.

![Java 21](https://img.shields.io/badge/Java-21-orange) ![Spring Boot 3.2.5](https://img.shields.io/badge/Spring%20Boot-3.2.5-brightgreen) ![React 19](https://img.shields.io/badge/React-19-blue) ![MongoDB Atlas](https://img.shields.io/badge/MongoDB-Atlas-green) ![Vite](https://img.shields.io/badge/Vite-8.x-646CFF)

---

## Table of Contents
- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Features](#features)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Environment Variables](#environment-variables)
- [Local Setup](#local-setup)
- [API Overview](#api-overview)
- [Frontend Routes](#frontend-routes)
- [Security Model](#security-model)
- [Testing](#testing)
- [Deployment](#deployment)
- [Roadmap](#roadmap)
- [Contributing](#contributing)

---

## Overview

SmartPay simulates a real UPI app with **virtual balances** (no real money movement). Users register with phone-credentialled UPI IDs, set a UPI PIN, send money, generate/pay via QR, track transactions, and manage trusted devices. OTP is phone-keyed and sent through a pluggable `SmsService` — console + `logs/sms.log` in development, swappable to Twilio/MSG91 in production.

Live ports: **Backend `8765`** (`/api`) · **Frontend `5173`** (Vite proxy `/api` → `http://localhost:8765`).

## Tech Stack

| Layer | Tech |
|-------|------|
| Backend | Java 21, Spring Boot 3.2.5, Spring Security, Spring Data MongoDB |
| Auth | JJWT 0.12.5 (HMAC-SHA256), BCrypt, JWT access 15m + refresh 7d |
| Database | MongoDB Atlas (free tier) |
| Frontend | React 19, Vite 8, React Router 7, Axios 1.18, Recharts 3.8, lucide-react, qrcode.react |
| Build | Maven 3.9, Node 18+ |
| Infra | Dockerfile (multi-stage), `system.properties` (Java 21), `logback-spring.xml` |

## Features

Tracked in [`FEATURES.md`](./FEATURES.md) — each feature lists files created/modified for undo support.

| Feature | Key Points | Status |
|---------|------------|--------|
| **upi-pin** | `upiPin` bcrypt on `User`, `POST /users/set-pin`, `POST /users/verify-pin`, PIN dialog on Send/QR, setup banner on Dashboard | ✅ |
| **jwt-refresh-tokens** | Access 15m / Refresh 7d (`RefreshToken` Mongo collection), `POST /api/auth/refresh`, axios 401 interceptor with retry queue | ✅ |
| **otp-device-binding** | `Device` (trusted/untrusted), `OtpService` (6-digit, 5m, phone-keyed), new-device login requires OTP, `/verify-otp` page | ✅ |
| **rate-limiting** | `RateLimitingService` (5 attempts / 15m) + `RateLimitingFilter` on login/OTP/PIN, request-body caching wrapper | ✅ |
| **otp-via-phone** | OTP keyed by `phone` not `email`; `RateLimitingFilter` extracts `phone` fallback `email` | ✅ |
| **sms-service** | `SmsService` interface + `ConsoleSmsService` (`@Profile("default")`, `+91` format) → console + `logs/sms.log` via `logback-spring.xml`; future `TwilioSmsService`/`Msg91SmsService` on `prod` profile | ✅ |

**Core app capabilities beyond the feature flags:**
- Register / Login / Verify OTP
- Wallet balance + Add money (simulated top-up)
- Send money (`POST /api/payments/transfer`) with PIN + rate limiting
- QR Generate (`GET /api/payments/qr`) + QR Pay (`POST /api/payments/qr/pay`)
- Transactions paginated + filtered + stats (`GET /api/transactions`, `GET /api/transactions/stats`)
- Dashboard with recent transactions, PIN banner, charts
- Session management (`GET /users/sessions`, `DELETE /users/sessions/{deviceId}`, `DELETE /users/sessions`)
- Profile, 404 handling

## Architecture

```
Browser (React 5173)
  │  Vite proxy /api → http://localhost:8765
  ▼
Spring Boot 8765 (stateless, CSRF off, CORS *)
  ├─ JwtAuthenticationFilter ─┐
  ├─ RateLimitingFilter ──────┤  before UsernamePasswordAuthenticationFilter
  ├─ AuthService ─ OtpService ─ SmsService ──► ConsoleSmsService (dev) / Twilio (prod)
  ├─ PaymentService / TransactionService / UserService
  ▼
MongoDB Atlas ── users / wallets / transactions / devices / refreshTokens
         │
         └─ logs/sms.log (SMS_LOGGER rolling file, 10 MB / 7 days)
```

## Project Structure

```
smartPay/
├── backend/
│   ├── src/main/java/com/smartpay/
│   │   ├── config/        SecurityConfig, JwtUtil, RateLimitingFilter, JwtAuthenticationFilter
│   │   ├── controller/    AuthController, UserController, WalletController, PaymentController, TransactionController
│   │   ├── service/       AuthService, OtpService, SmsService, ConsoleSmsService, PaymentService, TransactionService, RateLimitingService
│   │   ├── model/         User, Wallet, Transaction, Device, RefreshToken
│   │   └── dto/           request/*, response/*
│   ├── src/main/resources/ application.yml, logback-spring.xml
│   └── pom.xml
├── frontend/
│   ├── src/
│   │   ├── pages/         Login, Register, OtpVerification, Dashboard, SendMoney, Transactions, Wallet, Profile, QRPayment, SetUpiPin, Sessions, NotFound
│   │   ├── components/    Layout, Navbar, ProtectedRoute, LoadingSpinner
│   │   ├── context/       AuthContext
│   │   └── api/           axios.js (refresh queue)
│   ├── vite.config.js
│   └── package.json
├── Dockerfile
├── system.properties
├── FEATURES.md
├── test-*.ps1              7× integration scripts (see Testing)
└── start-*.bat             Local launch helpers
```

## Prerequisites

- **Java 21** (Temurin), **Maven 3.9+**, **Node 18+**
- **MongoDB Atlas** free cluster (or local `mongod`)
- Ports `8765` and `5173` free

## Environment Variables

> Never commit real `.env`. Use `.env.example` as template.

**`backend/.env` / `backend/.env.example`**

| Variable | Required | Example / Default |
|----------|----------|-------------------|
| `MONGODB_URI` | Yes | `mongodb+srv://<user>:<pass>@cluster0.xxxxx.mongodb.net/smartpay?retryWrites=true&w=majority` |
| `JWT_SECRET` | Yes | 64+ hex chars (HMAC-SHA256) |
| `PORT` | No | `8765` |

`application.yml` resolves as:

```yaml
server.port: ${PORT:8765}
spring.data.mongodb.uri: ${MONGODB_URI:mongodb+srv://...}
app.jwt.secret: ${JWT_SECRET:...}
app.jwt.expiration: 900000            # 15 min
app.jwt.refresh-expiration: 604800000 # 7 days
```

**`frontend/.env` / `frontend/.env.example`**

| Variable | Value |
|----------|-------|
| `VITE_API_URL` | `/api` (proxied by Vite to `http://localhost:8765`) |

Create from examples:

```bash
cp backend/.env.example backend/.env   # then fill real values
cp frontend/.env.example frontend/.env
```

## Local Setup

```bash
# 1. Clone
git clone https://github.com/amanladji/SmartPay.git
cd SmartPay

# 2. Backend
cd backend
# fill backend/.env (see above)
mvn spring-boot:run
# or: mvn package -DskipTests && java -jar target/smartpay-backend-1.0.0.jar

# 3. Frontend (new terminal)
cd frontend
npm install
npm run dev          # http://localhost:5173

# 4. One-click (Windows)
start-smartpay.bat   # launches both; uses hidden java process for backend
# alternatives: start-backend.bat / start-frontend.bat
```

- Vite proxies `/api` → `http://localhost:8765`; no CORS config needed locally (backend also allows `*`).
- First write after Atlas idle may take 10–30s.
- OTP in dev: shown in green banner on `/verify-otp` **and** logged as `[SMS] To: +91XXXXXXXXXX | Your SmartPay OTP is XXXXXX` to console + `backend/logs/sms.log` (`SMS_LOGGER`).

## API Overview

Base: `http://localhost:8765/api`

| Group | Method & Path | Auth | Notes |
|-------|---------------|------|-------|
| **Auth** | `POST /auth/register` | No | `name, email, phone(10d), password, deviceId?, deviceName?` → `token, refreshToken, upiId`; trusts device |
| | `POST /auth/login` | No | `email, password, deviceId, deviceName` → `{requiresOtp, otp, message}` or tokens; rate-limited |
| | `POST /auth/verify-otp` | No | `email, otp, deviceId, deviceName` → tokens; rate-limited |
| | `POST /auth/refresh` | No | `refreshToken` → new tokens |
| **Users** | `GET /users/me` | Yes | Profile |
| | `POST /users/set-pin` | Yes | `upiPin` 4-6 digits |
| | `POST /users/verify-pin` | Yes | Rate-limited |
| | `GET /users/sessions` | Yes | List devices |
| | `DELETE /users/sessions/{deviceId}` | Yes | Revoke one |
| | `DELETE /users/sessions` | Yes | Revoke all |
| **Wallet** | `GET /wallet/balance` | Yes | Balance + UPI ID |
| | `POST /wallet/add` | Yes | `amount` |
| **Payments** | `POST /payments/transfer` | Yes | `receiverUpiId, amount, description, upiPin` |
| | `GET /payments/qr?upiId=&amount=` | Yes | `upi://pay` payload |
| | `POST /payments/qr/pay` | Yes | QR pay (same as transfer) |
| **Transactions** | `GET /transactions?page=&size=&type=&status=` | Yes | Paginated |
| | `GET /transactions/stats` | Yes | `totalSent/Received, counts, monthly*` |
| **Health** | `GET /health` | No | `{status, mongo}` |

## Frontend Routes

| Path | Component | Guard |
|------|-----------|-------|
| `/login` | Login | Public |
| `/register` | Register | Public |
| `/verify-otp` | OtpVerification | Public (requires `state.email`) |
| `/` | Dashboard | Protected |
| `/send` | SendMoney | Protected |
| `/transactions` | Transactions | Protected |
| `/wallet` | Wallet | Protected |
| `/profile` | Profile | Protected |
| `/qr` | QRPayment (Generate + Pay tabs) | Protected |
| `/set-pin` | SetUpiPin | Protected |
| `/sessions` | Sessions | Protected |
| `*` | NotFound | Protected catch-all |

State: `AuthContext` (`user, token, pinSet, login/register/logout/verifyOtp/refreshPinStatus`) + `localStorage: token, refreshToken, deviceId`.

## Security Model

- **Passwords & PINs:** BCrypt.
- **JWT:** HMAC-SHA256, access 15m / refresh 7d (Mongo `refreshTokens`, revocable).
- **OTP:** `SecureRandom` 6-digit, 5m expiry, `ConcurrentHashMap` keyed by `phone`, 5/15m rate limit, trusted-device bypass.
- **Rate Limiting:** `ConcurrentHashMap` sliding window, `CachedBodyRequestWrapper` so filter can read `phone`/`email` without consuming stream; order: `RateLimitingFilter` → `JwtAuthenticationFilter` → `UsernamePasswordAuthenticationFilter`.
- **Sessions:** `Device` (`email, deviceId, deviceName, trusted, lastLogin`); `localStorage deviceId` persists.

> Balances are virtual. No real payment gateway or bank linking. SMS is simulated in dev; wire a `TwilioSmsService`/`Msg91SmsService` (`@Profile("prod")`) for production and stop returning `otp` in `AuthResponse`.

## Testing

```bash
# Backend unit
cd backend && mvn test

# Frontend build
cd frontend && npm run build

# Integration (PowerShell, backend must be running on 8765)
.\test-upi-pin.ps1        # 49 tests
.\test-jwt-refresh.ps1    # 84
.\test-otp-device.ps1     # 84
.\test-rate-limit.ps1     # 42
.\test-phone-otp.ps1      # 98 (7 runs × 14, OTP cross-checked api vs sms.log)
.\test-sessions.ps1
.\test-e2e.ps1            # full flow
```

`test-phone-otp.ps1` clears `backend/logs/sms.log`, registers with `deviceId`, asserts same-device no OTP, new-device OTP via `+91` log + API, wrong OTP rejection, and trusted-device flow.

## Deployment

**Docker (multi-stage):**

```dockerfile
FROM maven:3.9-eclipse-temurin-21 AS build
COPY backend/pom.xml . && COPY backend/src ./src && RUN mvn package -DskipTests -B
FROM eclipse-temurin:21-jre
COPY --from=build /app/target/smartpay-backend-1.0.0.jar app.jar
EXPOSE 8765
CMD ["java","-jar","app.jar"]
```
```bash
docker build -t smartpay .
docker run -p 8765:8765 --env-file backend/.env smartpay
```

**Render / Railway:** `system.properties` pins `java.runtime.version=21`; set env `MONGODB_URI`, `JWT_SECRET`, `PORT` in dashboard. Frontend as static site (`npm run build` → `dist/`).

## Roadmap

- Camera QR scanner
- Send to Contacts (recent + search)
- Collect / Request Money
- Transaction receipts & PDF statements
- CSV export, email notifications, WebSocket real-time updates

## Contributing

PRs welcome. Keep feature tracking in `FEATURES.md` (add block per feature for undo). Run `mvn test` + relevant `test-*.ps1` before pushing.

---

Built for learning/demo — not a real payment network.
