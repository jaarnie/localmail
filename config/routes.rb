Localmail::Engine.routes.draw do
  root "messages#index"
  delete "/", to: "messages#destroy_all", as: :messages
  resources :messages, path: "", only: %i[show destroy]
end
