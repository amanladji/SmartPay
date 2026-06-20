FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY backend/pom.xml .
COPY backend/src ./src
RUN mvn package -DskipTests -B

FROM eclipse-temurin:21-jre
COPY --from=build /app/target/smartpay-backend-1.0.0.jar app.jar
EXPOSE 8765
CMD ["java", "-jar", "app.jar"]
