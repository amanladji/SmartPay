FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY backend/pom.xml .
RUN mvn dependency:go-offline -B
COPY backend/src ./src
RUN mvn package -DskipTests -B

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/smartpay-backend-1.0.0.jar app.jar
EXPOSE 8765
ENTRYPOINT ["java", "-jar", "app.jar"]
