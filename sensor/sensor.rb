require 'yaml'
require 'httparty'
require 'json'

class Sensor
  include HTTParty
  include Math


  format :json
  headers 'Content-Type' => 'application/json'


  attr_accessor :rate, :zone, :sensor, :url, :thread_read_noise_run, :thread_read_noise

  def initialize(type)
    require 'open3' if type == 0

    @type = type # 0 run readNoise 1 random
    @config = YAML.load_file('config.yml')
    run if openConfig
  end

  def register(zone,sensor,url,rate)
    @zone = zone
    @sensor = sensor
    @url = url
    @rate = rate
    if not @state_run
      run
      @state_run = true
    end
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
    if not @state_run
      @state_run = true
      saveConfig
      run
    end
  end

  def turnOff
    # desligar sensor
    @state_run = false
    @thread_read_noise.terminate
    saveConfig
  end

  private

  def loginToken
    begin
      response = HTTParty.post(
          @url + '/login',
          body: { email: @admin_email,
                  password: @admin_password
          })

      response_hash =  JSON.parse(response.body)
      @token = response_hash['auth_token']
    rescue HTTParty::Error
      puts 'Error to make POST /login'
      @state_run = false
    end
  end

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
    @config['reads']['url'] = @url
    @config['reads']['zone'] = @zone
    @config['reads']['sensor'] = @sensor
    @config['reads']['rate'] = @rate
    @config['reads']['state'] = @state_run
    @config['reads']['token'] = @token

    File.open('config.yml', 'r+') do |file|
      file.write(@config.to_yaml)
    end
  end

  def sendValue value
    puts "Noise value: #{value}"
    #colocar try cath aqui
    # verificar se temos token se não vamos ter de fazer um login do administrador
    begin
      response = HTTParty.post(
          @url + '/reads',
          headers: {"Authorization" => "#{@token}"},
          body: { zone: @zone,
                  sensor: @sensor,
                  value: value,
                  timestamp: Time.now.getutc.to_i
          })
      puts "Response code: #{response.code}"
      if response.code == 401
        loginToken
        saveConfig
      end
    rescue HTTParty::Error
      puts 'Error to make POST /reads'
      @state_run = false
    end

  end

  def run
    puts 'begin'
    @thread_read_noise = Thread.new {
      begin
        Thread.stop if not @state_run

        loop do
          Thread.stop if not @state_run
          if @type == 0
            sendValue(readNoise)
          else
            sendValue(generateNoise)
          end
          #sleep(@rate)
        end
      rescue  Exception => e
        puts "error #{e}"
      end
    }
  end

  def readNoise
    Open3.capture2e("timeout #{@rate}s arecord  -D plughw:0,0 -f cd /tmp/test.wav")
    o,e = Open3.capture2e("sox -t .wav /tmp/test.wav -n stat")
    v = o.match("Maximum amplitude:[ ]*[0-9].[0-9]*\n").to_s.match("[0-9].[0-9]*").to_s.to_f
    20 * ( Math.log10( (2*10**-5)/ v )).abs
  end

  def generateNoise

    if rand(0...1.0) >= 0.8
      if rand(0...1) == 1
        value = rand(30...50)
      else
        value = rand(70...100)
      end
    else
      value = rand(50...70)
    end
    sleep(@rate)
    return value
  end

end

