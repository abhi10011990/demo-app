# Use OpenJDK 17 from Eclipse Temurin
FROM eclipse-temurin:17-jdk

WORKDIR /app

# Copy the Maven-built jar
COPY ./target/my-java-app-0.0.1-SNAPSHOT.jar /app/app.jar

# Expose port (same as Spring Boot)
EXPOSE 8080

ENTRYPOINT ["java","-jar","/app/app.jar"]
