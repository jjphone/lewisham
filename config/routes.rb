Rails.application.routes.draw do

  resources :users
  resources :sessions,		only: [:new, :create, :destroy]
  resources :relations,		only: [:update]
  
  resources :pages,			  only: [:index]

  resources :chats,       only: [:index, :show, :create, :update, :destroy]
  resources :messages,    only: [:update, :destroy]


  get     '/signin',  to: "sessions#new"
  delete  '/signout', to: "sessions#destroy"
  get     '/signup',  to: "users#new"
  get     '/search',  to: "search#index"

  get   '/about',   to: "pages#index", :id => 'about'
  get   '/help',    to: "pages#index", :id => 'help'
  get   '/contact', to: "pages#index", :id => 'contact'
  get   '/home',    to: "pages#index", :id => 'home'
  root            to: "pages#index"

end
