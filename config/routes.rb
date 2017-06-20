class ActionDispatch::Routing::Mapper
    def draw(routes_name)
        instance_eval(File.read(Rails.root.join("config/routes/#{routes_name}.rb")))
    end
end

Rails.application.routes.draw do

  resources :contacts
	scope module: 'api' do
        draw :apiv1
    end

    match '/' => 'homes#index', :via => [:get, :post]
    match 'confirm_account' => "homes#confirm_account", :via => [:get]
    match 'admin' => 'dashboard#index', :via => [:get]

    get "/grid/*path" => "gridfs#serve"

    resources :products
    match '/product_comments/:id' => "products#comments", :via => [:get, :post]
    match '/product_bids/:id' => "products#bids", :via => [:get, :post]

    resources :users, :only => [:show, :index]
    match '/user_bids/:id' => "users#bids", :via => [:get, :post]
    match '/user_products/:id' => "users#products", :via => [:get, :post]

    get "/subscribe_to_chat/:product_id/:user_id" => "chats#subscribe_to_chat", :via => [:get, :post], :defaults => { :format => 'json' }
    match "/unsubscribe_to_chat" => "chats#unsubscribe_to_chat", :via => [:get, :post], :defaults => { :format => 'json' }
    match "/add_chat_message" => "chats#add_chat_message", :via => [:get, :post], :defaults => { :format => 'json' }
    match 'contact' => "homes#contact", :via => [:post]
    resources :cities
    resources :states
    resources :countries
    resources :categories
    resources :qualities
    resources :brands
    resources :contacts

    devise_for :admins, :controllers => {:registrations => "registrations"}
    # match '*path', to: redirect('admin'), via: :all
    root 'homes#index'
end
