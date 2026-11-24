Rails.application.routes.draw do
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  root "dashboard#index"
  resources :audit_events, only: %i[index show] do
    member do
      post :toggle_pin
    end
  end
  resources :alert_rules
  resources :vcenter_connections do
    member do
      post :test_connection
    end
  end
  get "system_status", to: "system_status#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
