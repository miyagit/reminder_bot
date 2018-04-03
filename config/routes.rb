Rails.application.routes.draw do
	root 'ramens#index'
  post '/callback' => 'webhook#callback'
end
