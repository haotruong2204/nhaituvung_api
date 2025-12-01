Rails.application.routes.draw do
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      # Kanjis
      resources :kanjis, only: [ :index, :show ] do
        collection do
          get :search
        end

        member do
          get :ui_format
        end

        # Nested resources
        resources :examples, only: [ :index ], controller: "kanji_examples"
        get :textbooks, to: "textbook_references#by_kanji"
      end

      # Textbooks
      get "textbooks/:textbook_code/kanjis", to: "textbook_references#by_textbook"
    end
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
