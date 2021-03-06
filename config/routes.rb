require 'sidekiq/web'

Liveinspired::Application.routes.draw do

  resources :chatrooms
  mount Sidekiq::Web => '/sidekiq'

  root :to => "home#index"
  devise_for :users
  namespace :admin do
    resources :home, only: %i(index)
    resources :channels, only: %i(index)
  end
  get 'admin', to: 'admin/home#index'
  resources :keywords, only: [:index]
  resources :chatrooms do
    resources :chatters, only: [:index] do
      collection do
        post :add_to_chatroom
        post :remove_from_chatroom
      end
    end
    resources :chats
  end
  resources :channels do
    member do
      get  'list_subscribers'
      get  'messages_report'
      post 'delete_all_messages'
      get  'timeline'
      get  'export'
      get  'all'
    end
    resources :messages do
      member do
        post 'broadcast'
        post 'move_up'
        post 'move_down'
        get  'responses'
      end
      collection do
        get 'select_import'
        post 'import'
        post 'update_seq_no'
      end
      resources :response_actions do
        collection do
          get 'select_import'
          post 'import'
        end
      end
    end
  end
  post 'channels/:channel_id/add_subscriber/:id',    to: 'channels#add_subscriber',    :as => 'channel_add_subscriber'
  post 'channels/:channel_id/remove_subscriber/:id', to: 'channels#remove_subscriber', :as => 'channel_remove_subscriber'

  resources :channel_groups, :except => [:index] do
    member do
      get 'messages_report'
    end
  end
  post 'channel_groups/:channel_group_id/remove_channel/:id', to: 'channel_groups#remove_channel',  :as => 'channel_group_remove_channel'

  resources :rules
  resources :users do
    member do
      get :activity
    end
  end
  resources :subscribers do
    resources :subscriber_responses, only: %i(index)
    member do
      get :download_activity
    end
  end
  resources :subscriber_activities, :except=>[:new,:create,:destroy] do
    member do
      post 'reprocess'
    end
  end

  resources :downloads,           only: [:index]
  resources :service_identifiers, only: [:index]

  match 'subscribe/:channel_group_id' => "home#new_web_subscriber", :via => [:get, :post]
  match 'thank_you' => "home#sign_up_success", via: [:get]
  match 'twilio' =>'twilio#callback', :via => [:post]

  match 'help/user_show',            via: [:get]
  match 'help/edit_channel',         via: [:get]
  match 'help/edit_message',         via: [:get]
  match 'help/index_channels',       via: [:get]
  match 'help/edit_response_action', via: [:get]
  match 'help/glossary',             via: [:get]

end
