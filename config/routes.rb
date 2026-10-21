Rails.application.routes.draw do
  root "dashboard#index"
  resources :audit_events, only: %i[index show]

  get "up" => "rails/health#show", as: :rails_health_check
end
