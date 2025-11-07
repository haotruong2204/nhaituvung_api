require "sidekiq/web"
require "sidekiq-status/web"
require "sidekiq-scheduler/web"

Rails.application.routes.draw do
  Sidekiq::Web.use ActionDispatch::Cookies
  Sidekiq::Web.use Rails.application.config.session_store, Rails.application.config.session_options
  # Sidekiq Web UI (protect this in production!)
  mount Sidekiq::Web => "/sidekiq"

  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      resources :posts
    end
  end
end
