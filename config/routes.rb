Rails.application.routes.draw do
	root 'ramens#index'
  post '/callback' => 'webhook#callback'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
