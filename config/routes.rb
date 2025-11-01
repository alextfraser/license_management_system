Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root path
  root "accounts#index"

  # Top-level resources
  resources :accounts, only: [ :index, :show, :new, :create ] do
    # Nested resources under accounts
    resources :users, only: [ :index, :new, :create ]
    resources :subscriptions, only: [ :index, :new, :create ]

    # License assignment interface
    resource :license_assignment, only: [ :show ] do
      member do
        post :bulk_assign
        delete :bulk_unassign
      end
    end
  end

  resources :products, only: [ :index, :show, :new, :create ]
end
