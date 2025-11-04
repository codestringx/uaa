# Use Eclipse Temurin OpenJDK 21
FROM eclipse-temurin:21-jre

# Set working directory
WORKDIR /app

# Install PostgreSQL client for healthcheck
RUN apt-get update && \
    apt-get install -y postgresql-client netcat-traditional && \
    rm -rf /var/lib/apt/lists/*

# Copy WAR file and configuration
COPY uaa/build/libs/cloudfoundry-identity-uaa-*.war /app/uaa.war
COPY config/uaa.yml /app/config/uaa.yml

# Set non-sensitive environment variables
ENV JAVA_OPTS="-Xmx512m -Xms256m -Djava.security.egd=file:/dev/./urandom" \
    SPRING_PROFILES_ACTIVE=postgresql \
    DATABASE_HOST=host.docker.internal \
    DATABASE_PORT=5432 \
    DATABASE_NAME=uaa \
    SPRING_CONFIG_LOCATION=/app/config/uaa.yml

# Create health check script
RUN echo '#!/bin/bash\n\
echo "Checking database connection..."\n\
until nc -z -v -w5 $DATABASE_HOST $DATABASE_PORT; do\n\
  echo "Waiting for PostgreSQL at $DATABASE_HOST:$DATABASE_PORT..."\n\
  sleep 2\n\
done\n\
echo "Database is ready, starting UAA..."' > /app/wait-for-db.sh && \
    chmod +x /app/wait-for-db.sh

# Expose port
EXPOSE 8080

# Start the application
CMD ["/bin/bash", "-c", "/app/wait-for-db.sh && java $JAVA_OPTS -jar /app/uaa.war"]