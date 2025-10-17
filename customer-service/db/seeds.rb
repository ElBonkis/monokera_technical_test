Customer.destroy_all if Rails.env.development?

puts "Seeding customers"

customers_data = [
  {
    name: 'Juan Pérez',
    email: 'juan.perez@example.com',
    address: 'Calle 10 #45-67, Medellín, Antioquia',
    phone: '+57 300 123 4567',
    orders_count: 0
  },
  {
    name: 'María García',
    email: 'maria.garcia@example.com',
    address: 'Carrera 50 #30-20, Bogotá, Cundinamarca',
    phone: '+57 310 987 6543',
    orders_count: 0
  },
  {
    name: 'Carlos Rodríguez',
    email: 'carlos.rodriguez@example.com',
    address: 'Avenida 3 #12-34, Cali, Valle del Cauca',
    phone: '+57 320 456 7890',
    orders_count: 0
  },
  {
    name: 'Ana Martínez',
    email: 'ana.martinez@example.com',
    address: 'Calle 80 #15-30, Barranquilla, Atlántico',
    phone: '+57 315 234 5678',
    orders_count: 0
  },
  {
    name: 'Luis Hernández',
    email: 'luis.hernandez@example.com',
    address: 'Carrera 20 #40-50, Cartagena, Bolívar',
    phone: '+57 301 876 5432',
    orders_count: 0
  },
  {
    name: 'Laura Gómez',
    email: 'laura.gomez@example.com',
    address: 'Calle 25 #30-15, Bucaramanga, Santander',
    phone: '+57 311 345 6789',
    orders_count: 0
  },
  {
    name: 'Pedro Sánchez',
    email: 'pedro.sanchez@example.com',
    address: 'Avenida 7 #22-44, Pereira, Risaralda',
    phone: '+57 321 654 3210',
    orders_count: 0
  },
  {
    name: 'Sofia López',
    email: 'sofia.lopez@example.com',
    address: 'Carrera 15 #50-60, Manizales, Caldas',
    phone: '+57 312 567 8901',
    orders_count: 0
  },
  {
    name: 'Diego Torres',
    email: 'diego.torres@example.com',
    address: 'Calle 35 #18-25, Santa Marta, Magdalena',
    phone: '+57 314 890 1234',
    orders_count: 0
  },
  {
    name: 'Valentina Ruiz',
    email: 'valentina.ruiz@example.com',
    address: 'Avenida 10 #28-40, Ibagué, Tolima',
    phone: '+57 316 123 4567',
    orders_count: 0
  }
]

customers_data.each do |customer_data|
  customer = Customer.create!(customer_data)
  puts "Created customer: #{customer.name} (ID: #{customer.id})"
end

puts "Seeding completed! Created #{Customer.count} customers"