FactoryBot.define do
  factory :customer do
    sequence(:name) { |n| "Customer #{n}" }
    sequence(:email) { |n| "customer#{n}@example.com" }
    address { "Calle 10 #45-67, Medellín, Antioquia" }
    phone { [ nil, '+57 300 123 4567', '+57 310 987 6543' ].sample }
    orders_count { 0 }

    trait :with_orders do
      orders_count { rand(1..10) }
    end

    trait :active do
      orders_count { rand(5..20) }
    end

    trait :with_phone do
      phone { '+57 300 123 4567' }
    end

    trait :without_phone do
      phone { nil }
    end
  end
end
