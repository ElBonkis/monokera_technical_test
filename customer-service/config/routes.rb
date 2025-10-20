Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :customers, only: [ :index, :show, :create ]
    end
  end

  get '/health', to: proc {
    [ 200,
     { 'Content-Type' => 'application/json' },
     [ {
       status: 'ok',
       service: 'customer-service',
       timestamp: Time.current.iso8601
     }.to_json ]
    ]
  }
end
