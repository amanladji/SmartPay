package com.smartpay.service;

import jakarta.annotation.PostConstruct;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class RateLimitingService {

    private static final int MAX_ATTEMPTS = 5;
    private static final long WINDOW_SECONDS = 900;
    private final Map<String, RateLimitEntry> attemptStore = new ConcurrentHashMap<>();

    @PostConstruct
    public void init() {
        Thread cleaner = new Thread(() -> {
            while (true) {
                try { Thread.sleep(60000); } catch (InterruptedException e) { break; }
                LocalDateTime cutoff = LocalDateTime.now().minusSeconds(WINDOW_SECONDS);
                attemptStore.entrySet().removeIf(e -> e.getValue().windowStart().isBefore(cutoff));
            }
        }, "rate-limiter-cleaner");
        cleaner.setDaemon(true);
        cleaner.start();
    }

    public boolean isAllowed(String key) {
        RateLimitEntry entry = attemptStore.get(key);
        if (entry == null) return true;
        if (entry.windowStart().isBefore(LocalDateTime.now().minusSeconds(WINDOW_SECONDS))) {
            attemptStore.remove(key);
            return true;
        }
        return entry.attempts() < MAX_ATTEMPTS;
    }

    public void recordAttempt(String key) {
        attemptStore.merge(key, new RateLimitEntry(1, LocalDateTime.now()), (existing, incoming) -> {
            if (existing.windowStart().isBefore(LocalDateTime.now().minusSeconds(WINDOW_SECONDS))) {
                return new RateLimitEntry(1, LocalDateTime.now());
            }
            return new RateLimitEntry(existing.attempts() + 1, existing.windowStart());
        });
    }

    public void resetAttempts(String key) {
        attemptStore.remove(key);
    }

    private record RateLimitEntry(int attempts, LocalDateTime windowStart) {}
}
