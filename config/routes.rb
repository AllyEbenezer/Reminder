Rails.application.routes.draw do
  resources :posts

  resources :imports, only: [:new, :create]

  root "posts#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
