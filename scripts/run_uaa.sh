#!/usr/bin/env bash
mkdir -p logs

JAVA_OPTS="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=logs/uaa-tests.hprof"
export JAVA_OPTS

./gradlew -Ddatabase.username=uaauser \
          -Ddatabase.password=uaapass \
          -Dspring.profiles.active=default,postgresql \
          run