@echo off
REM UAA Database Setup Script for Windows
REM Creates PostgreSQL user and database for UAA
REM
REM Usage: Run with PostgreSQL admin credentials
REM   .\uaa-setup\scripts\setup-database.bat

setlocal enabledelayedexpansion

echo =========================================
echo UAA PostgreSQL Database Setup
echo =========================================
echo.

REM Database configuration
set DB_NAME=uaa
set DB_USER=uaauser
set DB_PASSWORD=uaapassword
set POSTGRES_USER=postgres

echo This script will create:
echo   - Database: %DB_NAME%
echo   - User: %DB_USER%
echo   - Password: %DB_PASSWORD%
echo.

REM Check if PostgreSQL is installed
where psql >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PostgreSQL client (psql) not found!
    echo Please install PostgreSQL first.
    pause
    exit /b 1
)

echo Connecting to PostgreSQL as '%POSTGRES_USER%'...
echo.

REM Create user and database
echo Creating database user '%DB_USER%'...

psql -U %POSTGRES_USER% -c "DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_user WHERE usename = '%DB_USER%') THEN CREATE USER %DB_USER% WITH PASSWORD '%DB_PASSWORD%'; ELSE ALTER USER %DB_USER% WITH PASSWORD '%DB_PASSWORD%'; END IF; END $$;"

if %ERRORLEVEL% EQU 0 (
    echo [OK] User '%DB_USER%' ready
) else (
    echo [ERROR] Failed to create/update user
    pause
    exit /b 1
)

echo Creating database '%DB_NAME%'...
psql -U %POSTGRES_USER% -tc "SELECT 1 FROM pg_database WHERE datname = '%DB_NAME%'" | findstr /C:"1" >nul
if %ERRORLEVEL% EQU 0 (
    echo [INFO] Database '%DB_NAME%' already exists
) else (
    psql -U %POSTGRES_USER% -c "CREATE DATABASE %DB_NAME% OWNER %DB_USER%;"
)

if %ERRORLEVEL% EQU 0 (
    echo [OK] Database '%DB_NAME%' ready
) else (
    echo [ERROR] Failed to create database
    pause
    exit /b 1
)

echo Granting privileges...
psql -U %POSTGRES_USER% -c "GRANT ALL PRIVILEGES ON DATABASE %DB_NAME% TO %DB_USER%;"

if %ERRORLEVEL% EQU 0 (
    echo [OK] Privileges granted
) else (
    echo [ERROR] Failed to grant privileges
    pause
    exit /b 1
)

echo.
echo =========================================
echo Database Setup Complete!
echo =========================================
echo.
echo Database Details:
echo   Host: localhost
echo   Port: 5432
echo   Database: %DB_NAME%
echo   User: %DB_USER%
echo   Password: %DB_PASSWORD%
echo.
echo Test connection:
echo   psql -U %DB_USER% -d %DB_NAME% -h localhost
echo.
echo Next steps:
echo   1. Generate keys: .\uaa-setup\scripts\generate-uaa-keys.bat
echo   2. Build UAA: .\gradlew clean :cloudfoundry-identity-uaa:assemble
echo   3. Start UAA: docker compose up --build
echo.
pause

endlocal
