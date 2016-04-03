Rails.application.routes.draw do

  mount CleverTable::Engine => "/clever_table"

  resources :users

end
