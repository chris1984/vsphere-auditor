Rails.application.routes.draw do
  root "dashboard#index"
  resources :audit_events, only: %i[index show]
  resources :alert_rules
  resources :vcenter_connections do
    member do
      post :test_connection
    end
  end
  get "system_status", to: "system_status#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
