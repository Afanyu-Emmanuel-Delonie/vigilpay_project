#!/bin/bash
# Quick start script for VigilPay Docker setup

set -e

echo "🐋 VigilPay Docker Setup"
echo "========================"

# Check Docker installation
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📋 Creating .env file from template..."
    cp .env.example .env
    echo "✅ .env created. Update it with your settings."
fi

# Build and start containers
echo "🔨 Building Docker images..."
docker-compose build

echo "🚀 Starting containers..."
docker-compose up -d

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 10

echo "📦 Running migrations..."
docker-compose exec -T web python manage.py migrate --noinput

echo "🎨 Collecting static files..."
docker-compose exec -T web python manage.py collectstatic --noinput

# Get local IP
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    LOCAL_IP=$(ipconfig getifaddr en0)
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    LOCAL_IP=$(hostname -I | awk '{print $1}')
else
    # Windows Git Bash / WSL
    LOCAL_IP="YOUR_LOCAL_IP"
fi

echo ""
echo "✅ VigilPay is ready!"
echo ""
echo "📱 Mobile API Endpoint:"
echo "   Development: http://$LOCAL_IP:8000/api/"
echo "   (Replace $LOCAL_IP with your actual IP)"
echo ""
echo "🌐 Web Interface:"
echo "   http://localhost:8000/"
echo "   http://$LOCAL_IP:8000/"
echo ""
echo "🔒 Admin Panel:"
echo "   http://localhost:8000/admin/"
echo ""
echo "📊 Database:"
echo "   PostgreSQL at localhost:5432"
echo ""
echo "📝 Next steps:"
echo "   1. Create a superuser: docker-compose exec web python manage.py createsuperuser"
echo "   2. View logs: docker-compose logs -f"
echo "   3. Stop containers: docker-compose down"
echo ""
