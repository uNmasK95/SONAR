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
  token = params[:token]
  zone = params[:zone].to_i
  sensor = params[:sensor].to_i
  rate = params[:rate].to_i

  $sensor.register( zone,sensor,url,rate,token )

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





