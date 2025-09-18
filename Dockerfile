FROM eclipse-temurin:24-jre-alpine AS base
WORKDIR /app
EXPOSE 8080

# Set non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Install curl for health check
RUN apk add --no-cache curl

FROM gradle:8-jdk-21-and-24-corretto AS build
WORKDIR /src

# Copy and restore dependencies first (better caching)
COPY build.gradle settings.gradle gradlew ./
COPY gradle/ gradle/
RUN chmod +x ./gradlew
RUN ./gradlew dependencies --no-daemon

# Copy source and build
COPY src/ src/
RUN ./gradlew bootJar --no-daemon -x test

# Extract layers for optimal Docker layering
RUN java -Djarmode=tools -jar build/libs/*.jar extract --layers --destination extracted/

FROM base AS final
WORKDIR /app

# Copy layers in order of change frequency (most optimal for caching)
COPY --from=build --chown=appuser:appgroup /src/extracted/dependencies/ ./
COPY --from=build --chown=appuser:appgroup /src/extracted/spring-boot-loader/ ./
COPY --from=build --chown=appuser:appgroup /src/extracted/snapshot-dependencies/ ./
COPY --from=build --chown=appuser:appgroup /src/extracted/application/ ./

USER appuser:appgroup

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD curl -f http://localhost:8080/hello || exit 1

# Use wildcard for JAR name to avoid version sync issues
ENTRYPOINT ["sh", "-c", "java -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -jar *.jar"]
