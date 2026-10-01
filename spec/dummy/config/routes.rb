Rails.application.routes.draw do
  mount Localmail::Engine, at: "/mail"
end
