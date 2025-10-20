FactoryBot.define do
  factory :order do
    customer_id { rand(1..10) }
    product_name { Faker::Commerce.product_name }
    quantity { rand(1..5) }
    price { Faker::Commerce.price(range: 10.0..1000.0) }
    status { 'pending' }

    trait :processing do
      status { 'processing' }
    end

    trait :completed do
      status { 'completed' }
    end

    trait :cancelled do
      status { 'cancelled' }
    end

    trait :with_multiple_items do
      quantity { rand(5..20) }
    end
  end
end
