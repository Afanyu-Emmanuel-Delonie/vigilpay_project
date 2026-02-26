@echo off
REM Quick start script for VigilPay Docker setup (Windows)

setlocal enabledelayedexpansion

echo.
echo 🐋 VigilPay Docker Setup - Windows
echo ===================================
echo.

REM Check Docker installation
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not installed. Please install Docker Desktop for Windows first.
    exit /b 1
)

docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker Compose is not installed. Please ensure Docker Desktop includes Compose.
    exit /b 1
)

echo ✅ Docker and Docker Compose are installed
echo.

REM Create .env file if it doesn't exist
if not exist .env (
    echo 📋 Creating .env file from template...
    copy .env.example .env
    echo ✅ .env created. Update it with your settings.
    echo.
)

REM Build and start containers
echo 🔨 Building Docker images (this may take a few minutes)...
docker-compose build
if errorlevel 1 (
    echo ❌ Build failed. Check Docker is running.
    exit /b 1
)
echo ✅ Build complete
echo.

echo 🚀 Starting containers...
docker-compose up -d
if errorlevel 1 (
    echo ❌ Failed to start containers.
    exit /b 1
)
echo ✅ Containers started
echo.

echo ⏳ Waiting for database to be ready (15 seconds)...
timeout /t 15 /nobreak

echo 📦 Running migrations...
docker-compose exec -T web python manage.py migrate --noinput
if errorlevel 1 (
    echo ❌ Migrations failed.
    exit /b 1
)
echo ✅ Migrations complete
echo.

echo 🎨 Collecting static files...
docker-compose exec -T web python manage.py collectstatic --noinput
echo ✅ Static files collected
echo.

echo.
echo ✅ VigilPay is ready!
echo.
echo 📱 Mobile API Endpoint:
for /f "delims=" %%i in ('ipconfig ^| findstr /R "IPv4"') do (
    set LOCAL_IP=%%i
    set LOCAL_IP=!LOCAL_IP:*: =!
    echo    Development: http://!LOCAL_IP!:8000/api/
)
echo.
echo 🌐 Web Interface:
echo    http://localhost:8000/
echo.
echo 🔒 Admin Panel:
echo    http://localhost:8000/admin/
echo.
echo 📊 Database:
echo    PostgreSQL at localhost:5432
echo    User: vigilpay_user
echo    Password: (check docker-compose.yml)
echo.
echo 📝 Next steps:
echo    1. Create superuser:
echo       docker-compose exec web python manage.py createsuperuser
echo.
echo    2. View logs:
echo       docker-compose logs -f
echo.
echo    3. Stop containers:
echo       docker-compose down
echo.
echo    4. View running containers:
echo       docker-compose ps
echo.
pause
