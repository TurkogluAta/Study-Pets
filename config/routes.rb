Rails.application.routes.draw do
  # Authentication routes
  post "register", to: "users#register"
  post "login", to: "users#login"

  # User profile routes (no ID needed - uses @current_user)
  get "profile", to: "users#profile"
  patch "profile", to: "users#update_profile"
  put "profile", to: "users#update_profile"
  delete "profile", to: "users#delete_account"

  # Resource routes
  resources :tasks
  resources :study_sessions
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
