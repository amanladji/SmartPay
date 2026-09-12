package com.smartpay.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartpay.dto.response.ApiResponse;
import com.smartpay.service.RateLimitingService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.ReadListener;
import jakarta.servlet.ServletInputStream;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Map;

@Component
@RequiredArgsConstructor
public class RateLimitingFilter extends OncePerRequestFilter {

    private final RateLimitingService rateLimitingService;
    private final ObjectMapper objectMapper;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String path = request.getRequestURI();
        String method = request.getMethod();

        if ("POST".equalsIgnoreCase(method) && (
                path.equals("/api/auth/login") ||
                path.equals("/api/auth/verify-otp"))) {

            CachedBodyRequestWrapper wrapper = new CachedBodyRequestWrapper(request);
            String phone = extractPhone(wrapper.getCachedBody());

            if (phone != null) {
                String key = path + ":" + phone;
                if (!rateLimitingService.isAllowed(key)) {
                    response.setStatus(429);
                    response.setContentType("application/json");
                    objectMapper.writeValue(response.getOutputStream(),
                            ApiResponse.error("Too many attempts. Please try again after 15 minutes"));
                    return;
                }
                rateLimitingService.recordAttempt(key);
            }
            filterChain.doFilter(wrapper, response);
        } else {
            filterChain.doFilter(request, response);
        }
    }

    private String extractPhone(byte[] body) {
        try {
            Map<?, ?> parsed = objectMapper.readValue(body, Map.class);
            Object phone = parsed.get("phone");
            if (phone != null) return phone.toString();
            Object email = parsed.get("email");
            return email != null ? email.toString() : null;
        } catch (Exception e) {
            return null;
        }
    }

    private static class CachedBodyRequestWrapper extends HttpServletRequestWrapper {
        private final byte[] cachedBody;

        public CachedBodyRequestWrapper(HttpServletRequest request) throws IOException {
            super(request);
            this.cachedBody = request.getInputStream().readAllBytes();
        }

        public byte[] getCachedBody() {
            return cachedBody;
        }

        @Override
        public ServletInputStream getInputStream() {
            ByteArrayInputStream bis = new ByteArrayInputStream(cachedBody);
            return new ServletInputStream() {
                @Override public int read() { return bis.read(); }
                @Override public boolean isFinished() { return bis.available() == 0; }
                @Override public boolean isReady() { return true; }
                @Override public void setReadListener(ReadListener listener) {}
            };
        }
    }
}
