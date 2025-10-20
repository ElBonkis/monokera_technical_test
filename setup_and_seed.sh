#!/bin/bash

set -e  # Exit on error

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     MONOKERA TECHNICAL TEST - AUTOMATED SETUP             ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Función para imprimir pasos
print_step() {
    echo -e "\n${BLUE}▶ $1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Función para imprimir éxito
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Función para imprimir advertencia
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Función para imprimir error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Verificar que estamos en el directorio correcto
if [ ! -d "customer-service" ] || [ ! -d "order-service" ]; then
    print_error "This script must be run from the project root directory"
    exit 1
fi

# 1. Setup de archivos .env
print_step "1/8 Setting up environment files"

if [ ! -f customer-service/.env ]; then
    cp customer-service/.env.example customer-service/.env 2>/dev/null || true
    print_success "Created customer-service/.env"
else
    print_warning "customer-service/.env already exists"
fi

if [ ! -f order-service/.env ]; then
    cp order-service/.env.example order-service/.env 2>/dev/null || true
    print_success "Created order-service/.env"
else
    print_warning "order-service/.env already exists"
fi

# 2. Detener contenedores existentes
print_step "2/8 Stopping existing containers"
docker compose down -v 2>/dev/null || true
print_success "Containers stopped"

# 3. Construir imágenes de Docker
print_step "3/8 Building Docker images"
docker compose build --no-cache
print_success "Images built successfully"

# 4. Levantar servicios de infraestructura
print_step "4/8 Starting infrastructure services (PostgreSQL & RabbitMQ)"
docker compose up -d postgres_orders postgres_customers rabbitmq
echo "Waiting for services to be healthy..."
sleep 10
print_success "Infrastructure services started"

# 5. Crear y migrar bases de datos
print_step "5/8 Setting up databases"

echo "Setting up Customer Service database..."
docker compose run --rm customer_service bash -c "
    bin/rails db:drop db:create db:migrate 2>/dev/null || bin/rails db:create db:migrate
"
docker compose run --rm customer_service bash -c "
   RAILS_ENV=test bin/rails db:drop db:create db:migrate 2>/dev/null || RAILS_ENV=test bin/rails db:create db:migrate
"
print_success "Customer Service database ready"

echo "Setting up Order Service database..."
docker compose run --rm order_service bash -c "
    bin/rails db:drop db:create db:migrate 2>/dev/null || bin/rails db:create db:migrate
"
docker compose run --rm order_service bash -c "
   RAILS_ENV=test bin/rails db:drop db:create db:migrate 2>/dev/null || RAILS_ENV=test bin/rails db:create db:migrate
"
print_success "Order Service database ready"

# 6. Levantar todos los servicios
print_step "6/8 Starting all services"
docker compose up -d
echo "Waiting for services to initialize..."
sleep 15
print_success "All services started"

# 7. Seed databases
print_step "7/8 Seeding databases"

echo "Seeding Customer Service..."
docker compose exec -T customer_service bin/rails db:seed
print_success "Customer Service seeded"


echo "Waiting 5 seconds for events to process..."
sleep 5

echo "Seeding Order Service..."
docker compose exec -T order_service bin/rails db:seed
print_success "Order Service seeded"

echo "Waiting 10 seconds for all events to process..."
sleep 10

# 8. Verificación
print_step "8/8 Verifying setup"

echo "Checking service health..."
if curl -s http://localhost:3001/api/v1/customers > /dev/null; then
    print_success "Customer Service is responding"
else
    print_error "Customer Service is not responding"
fi

if curl -s http://localhost:3000/api/v1/orders > /dev/null; then
    print_success "Order Service is responding"
else
    print_error "Order Service is not responding"
fi

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}║              ✓ SETUP COMPLETED SUCCESSFULLY               ║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}📊 Services Running:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔹 Customer Service:     http://localhost:3001"
echo "  🔹 Order Service:        http://localhost:3000"
echo "  🔹 RabbitMQ Management:  http://localhost:15672 (admin/admin)"
echo "  🔹 PostgreSQL Orders:    localhost:5434"
echo "  🔹 PostgreSQL Customers: localhost:5435"
echo ""
echo -e "${CYAN}🧪 Quick Test Commands:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  # List all customers"
echo "  curl http://localhost:3001/api/v1/customers | jq"
echo ""
echo "  # List all orders"
echo "  curl http://localhost:3000/api/v1/orders | jq"
echo ""
echo "  # Get customer with orders count"
echo "  curl http://localhost:3001/api/v1/customers/1 | jq"
echo ""
echo "  # Create a new order"
echo '  curl -X POST http://localhost:3000/api/v1/orders \'
echo '    -H "Content-Type: application/json" \'
echo '    -d '"'"'{"order":{"customer_id":1,"product_name":"Test Product","quantity":1,"price":100000}}'"'"' | jq'
echo ""
echo -e "${CYAN}📝 Useful Commands:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  # View logs"
echo "  docker compose logs -f"
echo ""
echo "  # View specific service logs"
echo "  docker compose logs -f customer_service"
echo "  docker compose logs -f order_service"
echo "  docker compose logs -f customer_listener"
echo ""
echo "  # Stop all services"
echo "  docker compose down"
echo ""
echo "  # Restart services"
echo "  docker compose restart"
echo ""
echo "  # Run tests"
echo "  docker compose exec customer_service bundle exec rspec"
echo "  docker compose exec order_service bundle exec rspec"
echo ""