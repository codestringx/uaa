@echo off
REM UAA Local Run Script (without Docker)
REM Runs UAA directly with Gradle and local PostgreSQL
REM
REM Usage: Run from UAA root directory
REM   .\uaa-setup\scripts\run-uaa-locally.bat

SETLOCAL

REM Get script directory and UAA root (2 levels up)
set SCRIPT_DIR=%~dp0
set UAA_ROOT=%SCRIPT_DIR%..\..
cd /d "%UAA_ROOT%"

echo Working directory: %CD%
echo.

:: Colors for Windows command prompt
set GREEN=[32m
set BLUE=[34m
set RED=[31m
set NC=[0m

:: Configuration
set DB_USER=uaauser
set DB_PASS=uaapass
set DB_NAME=uaa
set PROFILES=default,postgresql

echo %BLUE%Starting UAA with PostgreSQL (local mode)...%NC%

:: Check if PostgreSQL is installed
where psql >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo %RED%PostgreSQL client not found. Please install PostgreSQL.%NC%
    exit /b 1
)

:: Test database connection
psql -U %DB_USER% -d %DB_NAME% -c "\conninfo" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo %RED%Cannot connect to database. Please check if:%NC%
    echo 1. PostgreSQL is running
    echo 2. Database '%DB_NAME%' exists
    echo 3. User '%DB_USER%' has correct permissions
    echo %BLUE%You can run 'make setup-db' to initialize the database.%NC%
    exit /b 1
)

echo %GREEN%Database connection successful.%NC%
echo %BLUE%Starting UAA server...%NC%

:: Run UAA
call gradlew -Ddatabase.username=%DB_USER% ^
    -Ddatabase.password=%DB_PASS% ^
    -Dspring.profiles.active=%PROFILES% ^
    :cloudfoundry-identity-uaa:bootRun

ENDLOCAL