package com.smartpay.service;

import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
public class MongoKeepaliveService {
    private final MongoTemplate mongoTemplate;

    public MongoKeepaliveService(MongoTemplate mongoTemplate) {
        this.mongoTemplate = mongoTemplate;
    }

    @Scheduled(fixedRate = 120000)
    public void keepAlive() {
        try {
            mongoTemplate.executeCommand("{ ping: 1 }");
        } catch (Exception ignored) {
        }
    }
}
