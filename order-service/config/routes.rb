Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :orders, only: [ :index, :show, :create ]
    end
  end

  get '/health', to: proc {
    [ 200,
     { 'Content-Type' => 'application/json' },
     [ {
       status: 'ok',
       service: 'order-service',
       timestamp: Time.current.iso8601
     }.to_json ]
    ]
  }
end
