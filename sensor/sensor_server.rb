require 'sinatra'
require_relative 'sensor'
require 'json'

set :bind, '0.0.0.0'

puts "RANDOM #{ARGV[0]}" if ARGV[0].to_i == 1
$sensor = Sensor.new(ARGV[0].to_i)

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
  $sensor.turnOff()
  $sensor.state.to_json
end

post '/turnOn', :provides => :json do
  content_type :json
  $sensor.turnOn()
  $sensor.state.to_json
end

post '/rate' do
  rate = params[:rate].to_i
  $sensor.setRate( rate )
  $sensor.state.to_json
end





