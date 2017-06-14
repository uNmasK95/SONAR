require 'sinatra'
require_relative 'sensor'
require 'json'

$sensor = Sensor.new


get '/state', :provides => :json do
  content_type :json
  $sensor.state.to_json
end

post '/register' do
  url = params[:url]
  zone = params[:zone]
  sensor = params[:sensor]
  rate = params[:rate].to_i

  $sensor.register( zone,sensor,url,rate )

  content_type :json
  $sensor.state.to_json
end

post '/turnOff' do
  content_type :json
  $sensor.turnOff().to_json
end

post '/turnOn', :provides => :json do
  content_type :json
  $sensor.turnOn().to_json
end

post '/rate' do
  rate = params[:rate].to_i
  $sensor.setRate( rate )
end





