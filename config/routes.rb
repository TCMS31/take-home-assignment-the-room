# frozen_string_literal: true

Rails.application.routes.draw do
  root 'products#index'

  resources :products, only: %i[index show]
  resources :comments, only: %i[new create edit update destroy]

  get 'login', to: 'sessions#new', as: 'new_session'
  post 'login', to: 'sessions#create', as: 'sessions'
  delete 'logout', to: 'sessions#destroy', as: 'logout'

  get 'up', to: 'health#show', as: 'health'
end
