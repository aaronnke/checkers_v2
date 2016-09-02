Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root "static#index"
  get "/complete_move" => "static#complete_move", as: :complete_move
  get "/ai_move" => "static#ai_move", as: :ai_move
  get "/undo" => "static#undo"
end
