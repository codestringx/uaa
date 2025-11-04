@echo off
REM UAA Key Generation Script for Windows
REM This script generates all required keys and certificates for UAA setup
REM
REM Usage: Run from UAA root directory
REM   .\uaa-setup\scripts\generate-uaa-keys.bat

setlocal enabledelayedexpansion

echo =========================================
echo UAA Key and Certificate Generation
echo =========================================
echo.

REM Get script directory and UAA root (2 levels up)
set SCRIPT_DIR=%~dp0
set UAA_ROOT=%SCRIPT_DIR%..\..
cd /d "%UAA_ROOT%"

echo Working directory: %CD%
echo.

REM Check if OpenSSL is available
where openssl >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: OpenSSL is required but not found in PATH
    echo.
    echo Please install OpenSSL:
    echo   - Download from: https://slproweb.com/products/Win32OpenSSL.html
    echo   - Or use Git Bash which includes OpenSSL
    echo.
    pause
    exit /b 1
)

REM Create app directory if it doesn't exist
if not exist "app" mkdir app

echo Step 1: Generating SAML Service Provider Keys
echo Generating SAML private key and certificate (RSA 2048-bit, valid for 365 days)...
echo.

REM Generate SAML SP key and certificate
openssl req -newkey rsa:2048 -nodes -keyout app\saml.key -x509 -days 365 -out app\saml.crt -subj "/C=US/ST=Virginia/L=Henrico/O=Elephant Insurance/OU=Digital Development/CN=elephant.com" 2>nul

if %ERRORLEVEL% EQU 0 (
    echo [OK] SAML keys generated:
    echo   - app\saml.key ^(private key^)
    echo   - app\saml.crt ^(certificate^)
) else (
    echo [ERROR] Failed to generate SAML keys
    pause
    exit /b 1
)
echo.

echo Step 2: Generating JWT Signing Keys
echo Generating JWT RSA private key (2048-bit)...
echo.

REM Generate JWT private key
openssl genrsa -out app\jwt_key.pem 2048 2>nul

REM Convert to RSA format (required by UAA)
openssl rsa -in app\jwt_key.pem -out app\jwt_key_rsa.pem 2>nul

REM Extract public key
openssl rsa -in app\jwt_key.pem -pubout -out app\jwt_pub.pem 2>nul

if %ERRORLEVEL% EQU 0 (
    echo [OK] JWT keys generated:
    echo   - app\jwt_key.pem ^(private key^)
    echo   - app\jwt_key_rsa.pem ^(RSA format private key^)
    echo   - app\jwt_pub.pem ^(public key^)
) else (
    echo [ERROR] Failed to generate JWT keys
    pause
    exit /b 1
)
echo.

echo Step 3: Updating config\uaa.yml
echo.

REM Check if config\uaa.yml exists
if not exist "config\uaa.yml" (
    echo [ERROR] config\uaa.yml not found!
    echo Please ensure you're running this script from the UAA root directory.
    pause
    exit /b 1
)

REM Backup existing config
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
for /f "tokens=1-2 delims=/: " %%a in ('time /t') do (set mytime=%%a%%b)
set BACKUP_FILE=config\uaa.yml.backup.%mydate%_%mytime%
copy config\uaa.yml "%BACKUP_FILE%" >nul
echo Created backup: %BACKUP_FILE%
echo.

echo =========================================
echo Key Generation Complete!
echo =========================================
echo.
echo Generated key files:
echo   - SAML Key: app\saml.key
echo   - SAML Certificate: app\saml.crt
echo   - JWT Signing Key: app\jwt_key_rsa.pem
echo   - JWT Verification Key: app\jwt_pub.pem
echo.
echo IMPORTANT: You need to manually update config\uaa.yml
echo.
echo Next steps:
echo 1. Edit config\uaa.yml and replace the key placeholders with:
echo    - login.saml.keys.key1.key: Contents of app\saml.key
echo    - login.saml.keys.key1.certificate: Contents of app\saml.crt
echo    - jwt.token.signing-key: Contents of jwt_key_rsa.pem
echo    - jwt.token.verification-key: Contents of jwt_pub.pem
echo.
echo 2. Build UAA: gradlew clean :cloudfoundry-identity-uaa:assemble --no-daemon
echo 3. Start Docker: docker compose up --build
echo.
echo Tip: Use Git Bash to run generate-uaa-keys.sh for automatic config update
echo.
pause
