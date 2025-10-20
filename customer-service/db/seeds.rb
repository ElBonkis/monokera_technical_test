puts "Cleaning existing data..."
Customer.destroy_all
ActiveRecord::Base.connection.reset_pk_sequence!('customers')

puts "Seeding customers..."

customers_data = [
  {
    name: "Juan Pérez",
    email: "juan.perez@example.com",
    address: "Calle 10 #45-67, Medellín, Antioquia",
    phone: "+57 300 123 4567"
  },
  {
    name: "María González",
    email: "maria.gonzalez@example.com",
    address: "Carrera 43A #34-95, Medellín, Antioquia",
    phone: "+57 301 234 5678"
  },
  {
    name: "Carlos Rodríguez",
    email: "carlos.rodriguez@example.com",
    address: "Calle 53 #45-123, Bogotá, Cundinamarca",
    phone: "+57 302 345 6789"
  },
  {
    name: "Ana Martínez",
    email: "ana.martinez@example.com",
    address: "Avenida El Poblado #12-34, Medellín, Antioquia",
    phone: "+57 303 456 7890"
  },
  {
    name: "Luis Torres",
    email: "luis.torres@example.com",
    address: "Carrera 70 #32-10, Cali, Valle del Cauca",
    phone: "+57 304 567 8901"
  },
  {
    name: "Patricia Ramírez",
    email: "patricia.ramirez@example.com",
    address: "Calle 100 #15-20, Bogotá, Cundinamarca",
    phone: "+57 305 678 9012"
  },
  {
    name: "Diego Hernández",
    email: "diego.hernandez@example.com",
    address: "Carrera 50 #25-45, Barranquilla, Atlántico",
    phone: "+57 306 789 0123"
  },
  {
    name: "Laura Jiménez",
    email: "laura.jimenez@example.com",
    address: "Calle 85 #48-56, Medellín, Antioquia",
    phone: "+57 307 890 1234"
  },
  {
    name: "Andrés Morales",
    email: "andres.morales@example.com",
    address: "Avenida 6 #28-10, Cali, Valle del Cauca",
    phone: "+57 308 901 2345"
  },
  {
    name: "Carolina Castro",
    email: "carolina.castro@example.com",
    address: "Carrera 15 #93-40, Bogotá, Cundinamarca",
    phone: "+57 309 012 3456"
  }
]

created_customers = []

customers_data.each do |customer_attrs|
  customer = Customer.create!(customer_attrs)
  created_customers << customer
  puts "Created: #{customer.name} (ID: #{customer.id})"
end

puts "\n Seeding Summary:"
puts "  Total customers created: #{Customer.count}"
puts "  Customer IDs: #{created_customers.map(&:id).join(', ')}"
puts "\n Customer Service seeds completed successfully!"
