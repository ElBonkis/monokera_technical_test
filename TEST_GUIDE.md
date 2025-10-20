# Guía de Pruebas Manuales - Monokera Technical Test

Esta guía te permitirá probar manualmente todo el sistema paso a paso.

## Prerrequisitos

- Tener los servicios corriendo (Customer Service, Order Service, RabbitMQ Listener, Job Worker)
- Tener `jq` instalado para formatear JSON (opcional pero recomendado)
- Tener `curl` disponible

## 📋 Checklist Inicial

Antes de comenzar las pruebas, verifica que todo esté corriendo:
```bash
curl http://localhost:3001/api/v1/customers

curl http://localhost:3000/api/v1/orders

open http://localhost:15672
```

---

## 🧪 Test Suite Manual

### Test 1: Listar Clientes

**Objetivo:** Verificar que Customer Service retorna la lista de clientes.

**Comando:**
```bash
curl http://localhost:3001/api/v1/customers | jq
```

**Resultado Esperado:**
- Status: 200 OK
- JSON con array de clientes
- Cada cliente debe tener: id, name, email, address, phone, orders_count

**Ejemplo de respuesta:**
```json
[
  {
    "id": 1,
    "name": "Juan Pérez",
    "email": "juan.perez@example.com",
    "address": "Calle 10 #45-67, Medellín, Antioquia",
    "phone": "+57 300 123 4567",
    "orders_count": 0,
    "created_at": "2025-10-19T14:07:06.466-05:00",
    "updated_at": "2025-10-19T14:07:06.466-05:00"
  }
]
```

✅ **Criterios de Éxito:**
- [ ] Status code 200
- [ ] Array con mínimo 1 cliente
- [ ] Todos los campos presentes

---

### Test 2: Obtener Cliente Específico

**Objetivo:** Obtener los detalles de un cliente por su ID.

**Comando:**
```bash
curl http://localhost:3001/api/v1/customers/1 | jq
```

**Resultado Esperado:**
- Status: 200 OK
- JSON con datos del cliente
- Campo `orders_count` presente

**Tomar nota del `orders_count` para tests posteriores:**
```bash
# Guardar el valor inicial
INITIAL_COUNT=$(curl -s http://localhost:3001/api/v1/customers/1 | jq -r '.orders_count')
echo "Initial orders_count: $INITIAL_COUNT"
```

✅ **Criterios de Éxito:**
- [ ] Status code 200
- [ ] Cliente con ID 1 encontrado
- [ ] `orders_count` es un número

---

### Test 3: Crear un Nuevo Cliente

**Objetivo:** Crear un cliente nuevo en el sistema.

**Comando:**
```bash
curl -X POST http://localhost:3001/api/v1/customers \
  -H "Content-Type: application/json" \
  -d '{
    "customer": {
      "name": "Test Manual Cliente",
      "email": "test.manual@example.com",
      "address": "Calle Test #123-45",
      "phone": "+57 300 999 8888"
    }
  }' | jq
```

**Resultado Esperado:**
- Status: 201 Created
- JSON con el cliente creado incluyendo su ID
- Campo `orders_count` debe ser 0

✅ **Criterios de Éxito:**
- [ ] Status code 201
- [ ] Cliente creado con ID asignado
- [ ] orders_count = 0
- [ ] Todos los campos correctos

---


**Resultado Esperado:**
- Status: 200 OK
- Cliente con teléfono actualizado

✅ **Criterios de Éxito:**
- [ ] Status code 200
- [ ] Teléfono actualizado correctamente

---

### Test 5: Listar Órdenes

**Objetivo:** Verificar que Order Service retorna la lista de órdenes.

**Comando:**
```bash
curl http://localhost:3000/api/v1/orders | jq
```

**Resultado Esperado:**
- Status: 200 OK
- Array de órdenes
- Cada orden con: id, customer_id, product_name, quantity, price, status

✅ **Criterios de Éxito:**
- [ ] Status code 200
- [ ] Array con órdenes
- [ ] Todos los campos presentes

---

### Test 6: Obtener Orden Específica con Datos del Cliente

**Objetivo:** Verificar que al obtener una orden, también se incluyen los datos del cliente.

**Comando:**
```bash
curl http://localhost:3000/api/v1/orders/1 | jq
```

**Resultado Esperado:**
- Status: 200 OK
- JSON con datos de la orden
- Objeto `customer` anidado con datos completos del cliente

**Ejemplo:**
```json
{
  "id": 1,
  "customer_id": 1,
  "product_name": "Laptop HP Pavilion 15",
  "quantity": 2,
  "price": 2500000.0,
  "status": "pending",
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

✅ **Criterios de Éxito:**
- [ ] Status code 200
- [ ] Orden con todos sus datos
- [ ] Objeto `customer` presente y completo

---

### Test 7: Filtrar Órdenes por Cliente

**Objetivo:** Obtener solo las órdenes de un cliente específico.

**Comando:**
```bash
curl "http://localhost:3000/api/v1/orders?customer_id=1" | jq
```

**Resultado Esperado:**
- Status: 200 OK
- Array con solo las órdenes del customer_id=1

✅ **Criterios de Éxito:**
- [ ] Status code 200
- [ ] Todas las órdenes tienen customer_id = 1

---

### Test 8: Crear Orden y Verificar Actualización de Contador (CRÍTICO)

**Objetivo:** Probar el flujo completo end-to-end con comunicación HTTP y eventos.

Este es el test más importante porque valida toda la arquitectura.

#### Paso 1: Obtener orders_count inicial
```bash
echo "=== Paso 1: orders_count inicial ==="
curl -s http://localhost:3001/api/v1/customers/1 | jq '.orders_count'
```

**Anotar el valor.**

#### Paso 2: Crear una nueva orden
```bash
echo "=== Paso 2: Crear orden ==="
curl -X POST http://localhost:3000/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{
    "order": {
      "customer_id": 1,
      "product_name": "Test Manual Product",
      "quantity": 1,
      "price": 500000,
      "status": "pending"
    }
  }' | jq
```

**Verificar:**
- Status: 201 Created
- Mensaje "Order created successfully"
- Orden con ID asignado
- Datos del customer incluidos

#### Paso 3: Esperar procesamiento del evento
```bash
echo "=== Paso 3: Esperando 5 segundos ==="
sleep 5
```

⏳ Durante estos segundos:
1. Order Service publica evento a RabbitMQ
2. Job Worker procesa el PublishOrderEventJob
3. Customer Service Listener recibe el evento
4. Se incrementa el orders_count

#### Paso 4: Verificar orders_count actualizado
```bash
echo "=== Paso 4: orders_count después ==="
curl -s http://localhost:3001/api/v1/customers/1 | jq '.orders_count'
```

**El valor debe ser orders_count_inicial + 1**

✅ **Criterios de Éxito:**
- [ ] Orden creada exitosamente (201)
- [ ] orders_count incrementado en 1
- [ ] Tiempo de procesamiento < 10 segundos

**Si falla:**
```bash
# Verificar logs del listener
docker compose logs customer_listener

# Verificar logs del job worker
docker compose logs order_worker

# Verificar cola de RabbitMQ
open http://localhost:15672/#/queues
```

---

### Test 9: Validación de Datos - Orden sin Customer ID

**Objetivo:** Verificar que las validaciones funcionan correctamente.

**Comando:**
```bash
curl -X POST http://localhost:3000/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{
    "order": {
      "product_name": "Test Product",
      "quantity": 1,
      "price": 100000
    }
  }' | jq
```

**Resultado Esperado:**
- Status: 400 Bad Request
- Mensaje de error indicando campos faltantes

✅ **Criterios de Éxito:**
- [ ] Status code 400
- [ ] Error de validación claro

---

### Test 10: Orden con Cliente Inexistente

**Objetivo:** Verificar manejo de errores cuando el cliente no existe.

**Comando:**
```bash
curl -X POST http://localhost:3000/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{
    "order": {
      "customer_id": 99999,
      "product_name": "Test Product",
      "quantity": 1,
      "price": 100000
    }
  }' | jq
```

**Resultado Esperado:**
- Status: 404 Not Found
- Error: "customer_not_found"
- Mensaje descriptivo

✅ **Criterios de Éxito:**
- [ ] Status code 404
- [ ] Error type: "customer_not_found"
- [ ] Mensaje claro

---

### Test 11: Cliente Inexistente

**Objetivo:** Verificar manejo de errores en Customer Service.

**Comando:**
```bash
curl http://localhost:3001/api/v1/customers/99999 | jq
```

**Resultado Esperado:**
- Status: 404 Not Found
- Mensaje de error

✅ **Criterios de Éxito:**
- [ ] Status code 404
- [ ] Mensaje de error descriptivo

---

## 🔍 Verificaciones Adicionales

### Verificar RabbitMQ Management UI
```bash
open http://localhost:15672
# Usuario: admin
# Password: admin
```

**Verificar:**
- [ ] Cola `customer_service.orders` existe
- [ ] Mensajes siendo procesados
- [ ] No hay mensajes en estado "Unacked" acumulados

### Verificar Logs en Tiempo Real
```bash
# Customer Service
docker compose logs -f customer_service

# Order Service
docker compose logs -f order_service

# Customer Listener
docker compose logs -f customer_listener

# Order Worker
docker compose logs -f order_worker
```

### Verificar Base de Datos
```bash
# Customer Service DB
docker exec -it monokera_postgres_customers psql -U postgres -d customer_service_development -c "SELECT id, name, orders_count FROM customers LIMIT 5;"

# Order Service DB
docker exec -it monokera_postgres_orders psql -U postgres -d order_service_development -c "SELECT id, customer_id, product_name, status FROM orders LIMIT 5;"
```

---

## 📊 Reporte de Pruebas

Al finalizar, completa este checklist:

### Funcionalidades Core
- [ ] Listar clientes
- [ ] Obtener cliente específico
- [ ] Crear cliente
- [ ] Listar órdenes
- [ ] Obtener orden específica
- [ ] Filtrar órdenes por cliente
- [ ] Crear orden
- [ ] **CRÍTICO:** Contador orders_count se actualiza automáticamente

### Validaciones y Errores
- [ ] Validación de campos requeridos
- [ ] Error cuando cliente no existe
- [ ] Error cuando orden no existe
- [ ] Mensajes de error descriptivos

### Comunicación entre Servicios
- [ ] HTTP: Order Service → Customer Service (validación)
- [ ] RabbitMQ: Order Service → Customer Service (eventos)
- [ ] Jobs procesados correctamente
- [ ] Eventos consumidos por listener

### Performance
- [ ] Respuestas < 1 segundo
- [ ] Eventos procesados < 10 segundos
- [ ] Sin errores en logs

---

## 🐛 Troubleshooting

### El orders_count no se actualiza

**Posibles causas:**
1. RabbitMQ Listener no está corriendo
2. Job Worker no está corriendo
3. Problema de conectividad con RabbitMQ

**Solución:**
```bash
# Verificar procesos
docker compose ps

# Reiniciar listener
docker compose restart customer_listener

# Ver logs
docker compose logs -f customer_listener
docker compose logs -f order_worker
```

### Error "Customer Service is not running"

**Solución:**
```bash
# Verificar que esté corriendo
docker compose ps customer_service

# Reiniciar
docker compose restart customer_service

# Ver logs
docker compose logs customer_service
```

### Errores 500 en Order Service

**Solución:**
```bash
# Ver logs detallados
docker compose logs order_service

# Verificar conectividad a Customer Service
curl http://localhost:3001/api/v1/customers

# Verificar variable CUSTOMER_SERVICE_URL
docker compose exec order_service env | grep CUSTOMER
```

---

## ✅ Conclusión

Si todos los tests pasan:
- ✅ Sistema funcionando correctamente
- ✅ Arquitectura de microservicios validada
- ✅ Comunicación HTTP funcionando
- ✅ Comunicación por eventos funcionando
- ✅ Manejo de errores correcto

