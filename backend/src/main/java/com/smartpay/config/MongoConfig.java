package com.smartpay.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.mongodb.MongoDatabaseFactory;
import org.springframework.data.mongodb.core.convert.MongoCustomConversions;

import java.math.BigDecimal;
import java.util.Arrays;

@Configuration
public class MongoConfig {

    @Bean
    public MongoCustomConversions mongoCustomConversions() {
        return new MongoCustomConversions(Arrays.asList(
                new BigDecimalToDoubleConverter(),
                new DoubleToBigDecimalConverter()
        ));
    }

    static class BigDecimalToDoubleConverter implements org.springframework.core.convert.converter.Converter<BigDecimal, Double> {
        @Override
        public Double convert(BigDecimal source) {
            return source.doubleValue();
        }
    }

    static class DoubleToBigDecimalConverter implements org.springframework.core.convert.converter.Converter<Double, BigDecimal> {
        @Override
        public BigDecimal convert(Double source) {
            return BigDecimal.valueOf(source);
        }
    }
}
