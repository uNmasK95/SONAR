require 'yaml'
require 'httparty'
require 'json'


class Sensor
  include HTTParty

  format :json
  headers 'Content-Type' => 'application/json'


  attr_accessor :rate, :zone, :sensor, :url, :thread_read_noise_run, :thread_read_noise

  def initialize
    @config = YAML.load_file('config.yml')
    run if openConfig
  end

  def register(zone,sensor,url,rate,token)
    puts "registe"
    @zone = zone
    @sensor = sensor
    @url = url
    @rate = rate

    run if not @state_run
    @state_run = true
    saveConfig
  end

  def setRate(rate)
    @rate = rate
    saveConfig
  end

  def state
    { state: @state_run, zone: @zone, sensor: @sensor, url: @url, rate: @rate }
  end

  def turnOn
    # ligar sensor
    @state_run = true
    saveConfig
    run
    { state: @state_run }
  end

  def turnOff
    # desligar sensor
    @state_run = false
    saveConfig
    { state: false }
  end

  private

  def openConfig
    @zone = @config['reads']['zone'] if @config['reads']['zone']
    @sensor = @config['reads']['sensor'] if @config['reads']['sensor']
    @url = @config['reads']['url'] if @config['reads']['url']
    @rate = @config['reads']['rate'].to_i || 30
    @state_run = @config['reads']['state'] || false
    @admin_email = @config['admin']['email'] if @config['admin']['email']
    @admin_password = @config['admin']['password'] if @config['admin']['password']
    @token = @config['reads']['token'] if @config['reads']['token']
    @state_run and @zone and @sensor and @url
  end

  def saveConfig
    @config['reads']['url'] = @url if @url
    @config['reads']['zone'] = @zone if @zone
    @config['reads']['sensor'] = @sensor if @sensor
    @config['reads']['rate'] = @rate if @rate
    @config['reads']['state'] = @state_run if @state_run
    @config['reads']['token'] = @token if @token

    File.open('config.yml', 'r+') do |file|
      file.write(@config.to_yaml)
    end
  end

  def sendValue value
    puts value
    #colocar try cath aqui
    # verificar se temos token se não vamos ter de fazer um login do administrador
    result = HTTParty.post(
        @url,
        headers: {"Authorization" => "#{@token}"},
        body: { zone: @zone,
                sensor: @sensor,
                value: value,
                timestamp: Time.now.getutc.to_i
        })
    return result
  end

  def run
    puts 'begin'
    @thread_read_noise = Thread.new {
      begin
        Thread.stop if not @state_run

        loop do
          Thread.stop if not @state_run
          sendValue(rand(0..100))
          sleep(@rate)
        end
      rescue  Exception => e
        puts "error #{e}"
      end
    }
  end


end

