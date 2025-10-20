# Monokera Technical Test - Microservices Architecture

Sistema de microservicios con arquitectura orientada a eventos para gestión de órdenes y clientes.

## 🏗️ Arquitectura

Este proyecto implementa dos microservicios independientes que se comunican mediante:
- **HTTP REST APIs** para comunicación síncrona
- **RabbitMQ** para comunicación asíncrona mediante eventos
```
┌─────────────────────────────────────────────────────────────────┐
│                        ARQUITECTURA                             │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐                           ┌──────────────────┐
│                  │    HTTP Request           │                  │
│  Order Service   │──────────────────────────>│ Customer Service │
│   (Port 3000)    │   GET /customers/:id      │   (Port 3001)    │
│                  │                           │                  │
└────────┬─────────┘                           └────────┬─────────┘
         │                                              │
         │ Publish Event                                │ Subscribe
         │ "order.created"                              │ & Process
         │                                              │
         └──────────────────┐         ┐────────────────┘
                            │         │
                     ┌──────▼─────────▼──────┐
                     │                        │
                     │      RabbitMQ          │
                     │   Message Broker       │
                     │                        │
                     └────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                    BASE DE DATOS                                 │
└──────────────────────────────────────────────────────────────────┘

  ┌───────────────┐                    ┌────────────────┐
  │  PostgreSQL   │                    │  PostgreSQL    │
  │  Port: 5434   │                    │  Port: 5435    │
  │               │                    │                │
  │ order_service │                    │customer_service│
  │  _development │                    │  _development  │
  └───────────────┘                    └────────────────┘
```

### Servicios

#### Customer Service (Puerto 3001)
- **Base de datos:** PostgreSQL (puerto 5435)
- **Responsabilidades:**
  - CRUD de clientes
  - Mantener contador de órdenes por cliente
  - Escuchar eventos `order.created` vía RabbitMQ
  - Actualizar `orders_count` cuando se crea una orden

#### Order Service (Puerto 3000)
- **Base de datos:** PostgreSQL (puerto 5434)
- **Responsabilidades:**
  - CRUD de órdenes
  - Validar existencia de clientes (HTTP a Customer Service)
  - Publicar eventos `order.created` vía RabbitMQ
  - Procesar jobs asíncronos con Solid Queue

## 🚀 Instalación y Configuración

### Prerrequisitos

- Ruby 3.4.5
- PostgreSQL 15+
- RabbitMQ 3.x
- Bundler 2.x

### Opción 1: Instalación con Docker (Recomendado)
```bash
# 1. Clonar el repositorio
git clone <repository-url>
cd monokera_technical_test

# 2. Ejecutar setup automatizado
chmod +x setup_and_seed.sh
./setup_and_seed.sh
```

El script automáticamente:
- ✅ Crea archivos `.env` desde los ejemplos
- ✅ Levanta PostgreSQL y RabbitMQ
- ✅ Construye las imágenes de Docker
- ✅ Crea y migra las bases de datos
- ✅ Ejecuta los seeds con datos de prueba
- ✅ Levanta todos los servicios

### Opción 2: Instalación Manual

#### 1. Configurar variables de entorno
```bash
# Customer Service
cd customer-service
cp .env.example .env
# Editar .env si es necesario

# Order Service
cd ../order-service
cp .env.example .env
# Editar .env si es necesario
```

#### 2. Instalar dependencias
```bash
# Customer Service
cd customer-service
bundle install

# Order Service
cd ../order-service
bundle install
```

#### 3. Levantar infraestructura
```bash
# Desde la raíz del proyecto
docker compose up -d postgres_orders postgres_customers rabbitmq
```

#### 4. Crear y migrar bases de datos
```bash
# Customer Service
cd customer-service
bin/rails db:create db:migrate

# Order Service
cd ../order-service
bin/rails db:create db:migrate
```

#### 5. Ejecutar seeds (opcional)
```bash
# Customer Service
cd customer-service
bin/rails db:seed

# Order Service
cd ../order-service
bin/rails db:seed
```

#### 6. Iniciar servicios
```bash
# Terminal 1: Customer Service
cd customer-service
bin/rails server -p 3001

# Terminal 2: Customer Service RabbitMQ Listener
cd customer-service
bundle exec rake rabbitmq:listen

# Terminal 3: Order Service
cd order-service
bin/rails server -p 3000

# Terminal 4: Order Service Job Worker
cd order-service
bin/rails solid_queue:start
```

## 📡 API Endpoints

### Customer Service (http://localhost:3001)

#### Listar todos los clientes
```bash
GET /api/v1/customers

curl http://localhost:3001/api/v1/customers | jq
```

**Respuesta:**
```json
[
  {
    "id": 1,
    "name": "Juan Pérez",
    "email": "juan.perez@example.com",
    "address": "Calle 10 #45-67, Medellín, Antioquia",
    "phone": "+57 300 123 4567",
    "orders_count": 3,
    "created_at": "2025-10-19T14:07:06.466-05:00",
    "updated_at": "2025-10-19T16:30:15.123-05:00"
  }
]
```

#### Obtener un cliente específico
```bash
GET /api/v1/customers/:id

curl http://localhost:3001/api/v1/customers/1 | jq
```

#### Crear un cliente
```bash
POST /api/v1/customers

curl -X POST http://localhost:3001/api/v1/customers \
  -H "Content-Type: application/json" \
  -d '{
    "customer": {
      "name": "Pedro García",
      "email": "pedro@example.com",
      "address": "Carrera 50 #25-30",
      "phone": "+57 300 111 2222"
    }
  }' | jq
```

#### Actualizar un cliente
```bash
PUT /api/v1/customers/:id

curl -X PUT http://localhost:3001/api/v1/customers/1 \
  -H "Content-Type: application/json" \
  -d '{
    "customer": {
      "phone": "+57 300 999 8888"
    }
  }' | jq
```

#### Eliminar un cliente
```bash
DELETE /api/v1/customers/:id

curl -X DELETE http://localhost:3001/api/v1/customers/1
```

### Order Service (http://localhost:3000)

#### Listar todas las órdenes
```bash
GET /api/v1/orders

curl http://localhost:3000/api/v1/orders | jq
```

**Respuesta:**
```json
[
  {
    "id": 1,
    "customer_id": 1,
    "product_name": "Laptop HP Pavilion 15",
    "quantity": 2,
    "price": 2500000.0,
    "status": "pending",
    "created_at": "2025-10-19T16:06:52.054-05:00",
    "updated_at": "2025-10-19T16:06:52.054-05:00"
  }
]
```

#### Listar órdenes de un cliente específico
```bash
GET /api/v1/orders?customer_id=:id

curl http://localhost:3000/api/v1/orders?customer_id=1 | jq
```

#### Obtener una orden específica (con datos del cliente)
```bash
GET /api/v1/orders/:id

curl http://localhost:3000/api/v1/orders/1 | jq
```

**Respuesta:**
```json
{
  "id": 1,
  "customer_id": 1,
  "product_name": "Laptop HP Pavilion 15",
  "quantity": 2,
  "price": 2500000.0,
  "status": "pending",
  "created_at": "2025-10-19T16:06:52.054-05:00",
  "updated_at": "2025-10-19T16:06:52.054-05:00",
  "customer": {
    "id": 1,
    "name": "Juan Pérez",
    "email": "juan.perez@example.com",
    "address": "Calle 10 #45-67, Medellín, Antioquia",
    "phone": "+57 300 123 4567",
    "orders_count": 3
  }
}
```

#### Crear una orden
```bash
POST /api/v1/orders

curl -X POST http://localhost:3000/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{
    "order": {
      "customer_id": 1,
      "product_name": "iPhone 14 Pro",
      "quantity": 1,
      "price": 4500000,
      "status": "pending"
    }
  }' | jq
```

**Respuesta:**
```json
{
  "message": "Order created successfully",
  "order": {
    "id": 23,
    "customer_id": 1,
    "product_name": "iPhone 14 Pro",
    "quantity": 1,
    "price": 4500000.0,
    "status": "pending",
    "created_at": "2025-10-19T21:15:30.123Z",
    "updated_at": "2025-10-19T21:15:30.123Z"
  },
  "customer": {
    "id": 1,
    "name": "Juan Pérez",
    "email": "juan.perez@example.com"
  }
}
```

**Nota:** Al crear una orden:
1. Se valida que el cliente exista (HTTP request a Customer Service)
2. Se crea la orden en la base de datos
3. Se publica un evento `order.created` a RabbitMQ
4. Customer Service escucha el evento
5. Se incrementa automáticamente el `orders_count` del cliente

## 🧪 Tests

### Ejecutar todos los tests
```bash
# Customer Service
cd customer-service
bundle exec rspec

# Order Service
cd order-service
bundle exec rspec
```

### Ejecutar tests específicos
```bash
# Tests de modelos
bundle exec rspec spec/models

# Tests de controllers
bundle exec rspec spec/controllers

# Tests de servicios
bundle exec rspec spec/services

# Un archivo específico
bundle exec rspec spec/models/customer_spec.rb
```

### Coverage

Los tests incluyen coverage con SimpleCov. Después de ejecutar los tests, abre:
```bash
open coverage/index.html
```

## 🔍 Verificación del Sistema

### 1. Verificar que todos los servicios estén corriendo
```bash
# Con Docker
docker compose ps

# Sin Docker
ps aux | grep rails
ps aux | grep rake
```

### 2. Verificar conectividad a las bases de datos
```bash
# PostgreSQL Orders
psql -h localhost -p 5434 -U postgres -d order_service_development

# PostgreSQL Customers
psql -h localhost -p 5435 -U postgres -d customer_service_development
```

### 3. Verificar RabbitMQ

Accede a la interfaz de administración:
```
http://localhost:15672
Usuario: admin
Password: admin
```

### 4. Probar el flujo completo end-to-end
```bash
# 1. Obtener un customer y ver su orders_count inicial
curl http://localhost:3001/api/v1/customers/1 | jq '.orders_count'

# 2. Crear una nueva orden para ese customer
curl -X POST http://localhost:3000/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{
    "order": {
      "customer_id": 1,
      "product_name": "Test Product",
      "quantity": 1,
      "price": 100000
    }
  }' | jq

# 3. Esperar 2-3 segundos para que el evento se procese

# 4. Verificar que el orders_count se incrementó
curl http://localhost:3001/api/v1/customers/1 | jq '.orders_count'
```

## 🛠️ Comandos Útiles

### Docker
```bash
# Ver logs de todos los servicios
docker compose logs -f

# Ver logs de un servicio específico
docker compose logs -f customer_service
docker compose logs -f order_service
docker compose logs -f customer_listener

# Reiniciar un servicio
docker compose restart customer_service

# Detener todos los servicios
docker compose down

# Detener y eliminar volúmenes (⚠️ elimina las bases de datos)
docker compose down -v

# Reconstruir imágenes
docker compose build --no-cache
```

### Base de datos
```bash
# Resetear base de datos
cd customer-service
bin/rails db:drop db:create db:migrate db:seed

cd order-service
bin/rails db:drop db:create db:migrate db:seed
```

### RabbitMQ
```bash
# Ver estado de las colas
docker exec monokera_rabbitmq rabbitmqctl list_queues

# Ver conexiones activas
docker exec monokera_rabbitmq rabbitmqctl list_connections
```

### Rails Console
```bash
# Customer Service
cd customer-service
bin/rails console

# Order Service
cd order-service
bin/rails console
```

## 📊 Estructura del Proyecto
```
monokera_technical_test/
├── customer-service/
│   ├── app/
│   │   ├── adapters/          # Message broker adapters
│   │   ├── controllers/       # API controllers
│   │   ├── models/            # ActiveRecord models
│   │   └── services/          # Business logic
│   │       └── events/        # Event handlers
│   ├── config/
│   │   └── initializers/
│   ├── db/
│   │   ├── migrate/
│   │   └── seeds.rb
│   ├── lib/tasks/
│   │   └── rabbitmq.rake      # RabbitMQ listener task
│   ├── spec/                  # RSpec tests
│   ├── .env.example
│   ├── Dockerfile
│   └── Gemfile
├── order-service/
│   ├── app/
│   │   ├── adapters/          # Message broker adapters
│   │   ├── controllers/       # API controllers
│   │   ├── jobs/              # Background jobs
│   │   ├── models/            # ActiveRecord models
│   │   ├── serializers/       # Response serializers
│   │   └── services/          # Business logic
│   │       └── events/        # Event publishers
│   ├── config/
│   │   └── initializers/
│   ├── db/
│   │   ├── migrate/
│   │   └── seeds.rb
│   ├── spec/                  # RSpec tests
│   ├── .env.example
│   ├── Dockerfile
│   └── Gemfile
├── docker-compose.yml
├── setup_and_seed.sh          # Script de instalación automática
├── cleanup.sh                 # Script de limpieza
└── README.md
```

## 🎯 Patrones y Decisiones de Arquitectura

### 1. Service Objects Pattern
Toda la lógica de negocio está encapsulada en Service Objects (clases bajo `app/services/`):
- `Orders::Creator` - Creación de órdenes
- `Orders::Lister` - Listado de órdenes
- `Customers::Fetcher` - Obtención de datos de clientes desde API externa
- `Events::OrderPublisher` - Publicación de eventos
- `Events::OrderListener` - Escucha y procesamiento de eventos

### 2. Adapter Pattern
Los adapters de RabbitMQ permiten cambiar fácilmente el message broker sin afectar la lógica de negocio:
- `MessageBrokerAdapter::Base` - Interfaz base
- `RabbitmqAdapter` - Implementación para RabbitMQ
- `MessageBrokerFactory` - Factory para crear adapters

### 3. Event-Driven Architecture
- Comunicación asíncrona mediante eventos
- Desacoplamiento entre servicios
- Resiliencia: si un servicio cae, los eventos se quedan en la cola

### 4. Job Queue (Solid Queue)
- Procesamiento asíncrono de tareas pesadas
- Retry automático en caso de fallas
- Monitoreo y trazabilidad de jobs

## 🔒 Consideraciones de Seguridad

- Las credenciales están en archivos `.env` (no versionados)
- Validaciones a nivel de modelo y servicio
- Manejo de errores consistente
- Los endpoints no requieren autenticación (solo para propósitos de demo)

## 🚨 Troubleshooting

### Error: "Customer Service is not running"
```bash
# Verificar que el servicio esté corriendo
curl http://localhost:3001/api/v1/customers

# Si no responde, revisar logs
docker compose logs customer_service
```

### Error: "Connection refused" al crear orden
- Verificar que Customer Service esté corriendo en puerto 3001
- Verificar la variable `CUSTOMER_SERVICE_URL` en Order Service

### Los eventos no se procesan
- Verificar que RabbitMQ esté corriendo: `docker compose ps rabbitmq`
- Verificar que el listener esté activo: `docker compose logs customer_listener`
- Verificar la cola en RabbitMQ Management UI

### El orders_count no se actualiza
- Verificar que el RabbitMQ listener esté corriendo
- Verificar los logs del listener: `docker compose logs -f customer_listener`
- Verificar que el job se haya ejecutado: `docker compose logs -f order_worker`

## 👤 Autor

Desarrollado por ElBonkis como parte de la prueba técnica para Monokera.

## 📝 Licencia

Este proyecto es de uso educativo y de evaluación técnica.