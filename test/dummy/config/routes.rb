Rails.application.routes.draw do

  mount Deserializer::Engine => "/deserializer"
end
