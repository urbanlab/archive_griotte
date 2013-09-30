#!/usr/bin/env ruby
#
#video client for Raspéomix
#handles communication between scheduler
#and OMXPlayer ruby wrapper

require "i2c"
require "i2c/i2c"
require 'raspeomix/raspeomix'
require 'eventmachine'

module Raspeomix

  module Client
    # Class AnalogSensorsClient handles the 4 analog senors and sends read values on the wire
    #
    class AnalogSensorsClient

      include FayeClient

      # This class holds sensor information : name, description, type, and a
      # formula that converts analog reading to real-world value
      #
      class SensorProfile
        # Loads a sensor profile JSON file
        #
        # @params [String] file Profile file to load
        def SensorProfile.load(file)
          # TODO: read file
          # return SensorProfile.new(...)
        end

        # Initializes a SensorProfile
        #
        # @params [String] name Profile name
        # @params [Hash] options Options hash containing keys :convertion_formula, :metric and :description
        def initialize(name, options = {})
          @name = name
          options = { :convertion_formula => "x", :metric => "V", :description => 'none' }.merge(options)
          @convertion_formula = options[:convertion_formula]
          @metric = options[:metric]
          @description = options[:description]
        end
      end

      # Class MCP342x handles MCP342x ADC communications
      class MCP342x

        # Constants for configuration register, datasheet page 18
        #
        # Sample rate selection bits (S1-S0)
        RESOLUTION = { 
          :'12bits' => 0b00000000,
          :'14bits' => 0b00000100,
          :'16bits' => 0b00001000,
          :'18bits' => 0b00001100,
          :'240sps'  => 0b00000000,
          :'60sps'   => 0b00000100,
          :'15sps'   => 0b00001000,
          :'3_75sps' => 0b00001100
        }

        # PGA settings
        PGA = {
          :'1x' => 0b00000000,
          :'2x' => 0b00000001,
          :'4x' => 0b00000010,
          :'8x' => 0b00000011
        }

        # Channels
        CHANNEL = {
          :an0 => 0b00000000,
          :an1 => 0b00100000,
          :an2 => 0b01000000,
          :an3 => 0b01100000
        }

        # LSB in µV (cf datasheet table 4-1 p15)
        LSB = {
          :'12bits'  => 1000,
          :'14bits'  => 250,
          :'16bits'  => 62.5,
          :'18bits'  => 15.625,
          :'240sps'  => 1000,
          :'60sps'   => 250,
          :'15sps'   => 62.5,
          :'3_75sps' => 15.625
        }

        # Ready bit
        C_READY = 0b10000000
        ## Single shot mode
        C_OC_MODE = 0b00010000

        # Resistors divider ratio (R20+R21)/R21 required to scale back input voltage -
        # see {https://raw.github.com/hugokernel/RaspiOMix/master/export/1.0.1/images/schema.png Schematic}
        #
        # @note Ratio for 4k7 / 10k : 3.3
        # @note Ratio for 6k8 / 10k : 2.471
        DIVIDER_RATIO = 3.3

        # Initilize I2C communications
        #
        # @param [Hash] options Options hash containing :bus (I2C bus ID,
        #   defaults to 1; use 0 with Rev A boards) and :device address (0x6e by
        #   default)
        def initialize(options = {})
          @device = (options[:device] or 0x6e)
          @bus = (options[:bus] or 1)

          raise ArgumentError, "BusID must be 0 or 1 (got #{@bus})" unless [0,1].include?(@bus)
          @i2c = I2C.create("/dev/i2c-#{@bus}")
          Raspeomix.logger.info "MCP342x 0x%x initialized on bus %s" % [ @device, @bus ]
        end

        # Retrieves digitized value from analog channel
        #
        # @param [Symbol] channel Analog channel selction. One of :an0, :an1, :an2 or :an3
        # @param [Symbol] resolution Resolution setting. Can be :"12bits",
        #   :"14bits", :"16bits" or :"18bits". Setting sample rate is also
        #   supported. In this case, the supported values are :"240sps",
        #   :"60sps", :"15sps", :"3_75sps" which maps respectively to the
        #   resolution sympbols mentionned above.
        # One of :an0, :an1, :an2 or :an3
        #def sample(channel: :an0, resolution: :'18bits', pga: :'1x')
        def sample(channel=:an0, resolution=:'18bits', pga=:'1x')
          bytes    = [ 0, 0, 0, 0 ]

          # Check arguments
          unless RESOLUTION.include?(resolution)
            raise ArgumentError, "Rate/resolution must be 12bits, 14bits, 16bits, 18bits, 240sps, 60sps, 15sps or 3_75sps (was %s)" % resolution
          end

          unless CHANNEL.include?(channel)
            raise ArgumentError, "Channel must be one of an0, an1, an2 or an4i (was %s)" % channel
          end

          unless PGA.include?(pga)
            raise ArgumentError, "PGA setting must be one of 1x (default), 2x, 4x, 8x (was %s)" % pga
          end

          # Initiate conversion
          Raspeomix.logger.debug "resolution/rate set to #{resolution}, pga to #{pga}"
          @i2c.write(@device, C_READY | CHANNEL[channel] | C_OC_MODE | RESOLUTION[resolution] | PGA[pga])

          # Read 4 bytes
          # The first byte should be all zeroes
          # The first bit of 4th byte (& 0x80) should be 0, indicating the measure is ready (Cf datasheet page 19)
          bytes = @i2c.read(@device, 4).unpack("C4")
          while (bytes[3] & C_READY != 0) do
            # Repeat reading until measurement is ready
            bytes = @i2c.read(@device, 4).unpack("C4")
          end

          # config = bytes[3]
          # Get last bit of first byte, second byte, third byte
          output_code = ((bytes[0] & 0b00000001) << 16) | (bytes[1] << 8) | bytes[2]
          # puts "output code is %b %b %b %b (%x %x %x %x)" % (bytes + bytes)
          Raspeomix.logger.debug "bytes read %8.b %8.b %8.b %8.b" % bytes
          # puts "pga is %s (%s) %s" % [ pga, PGA[pga], 2**PGA[pga] ]

          #        puts "output code is %b %b %b %b" % bytes
          # Check MSB (datasheet equation 4-4 p16)
          Raspeomix.logger.debug "output_code %.8b / %d" % [ output_code, output_code ]

          if (bytes[0] & 0b10000000 != 0)
            output_code = ~(0x020000 - output_code)
          end

          # We need the PGA factor, which is 2^PGA[pga]
          # and return voltage in volts
          # puts "DIVIDER_RATIO #{DIVIDER_RATIO} LSB[resolution] #{LSB[resolution]} output_code #{output_code} 2**PGA[pga] #{2**PGA[pga]}"
          DIVIDER_RATIO * LSB[resolution] * (output_code / 2**PGA[pga]) / 1_000_000
        end
      end

      #
      # Class sensor holds paramters and current value for a given analog sensor
      #
      class Sensor
        attr_reader :channel, :profile

        def initialize(channel, profile, rate)
          @channel = channel
          @rate = rate
          @running = false
          @observers = []
        end

        # Sets ADC converter chip reference
        #
        # @params [Object] adc Reference to ADC
        def chip=(adc)
          @chip = adc
        end
        # Returns last read sensor value
        #
        # @return [Int] the sensor value in µV
        def value
          # @chip.sample(channel: @channel)
          @chip.sample(channel=@channel)
        end

        # Returns the current sensor reading rate
        #
        # @return [Float] the number of measurements per second
        def rate
          @rate
        end

        # Starts sensor sampling
        def start
          @running = true
          if @rate != 0
            @timer = EventMachine::PeriodicTimer.new(1/rate) {
              notify_observers
            }
          end
        end

        # Stops sensor sampling
        def stop
          @running = false
          # Remove timer if set
          if @timer
            EventMachine.cancel_timer
            # Empty instance variable since if rate is set to 0 we want to clear it
            @timer = nil
          end
        end

        # Sets the sensors reading rate
        #
        # @param [Float] rate The number of expected readings per second
        def rate=(rate)
          @rate = rate
          # Restart sampling
          if @running
            stop
            start
          end
        end

        # Adds observer
        #
        # Observers will have their #update method called when a new value is available
        # @params [Object] obs Observer reference
        def add_observer(obs)
          @observers << obs
        end

        # Removes observer
        #
        # Removes an observer from the observers array
        # @params [Object] obs Observer reference to be removed
        def remove_observer(obs)
          @observers.delete(obs)
        end

        private

        # Tells all observers that a new value is available
        def notify_observers
          @observers.each do |obs|
            EM.next_tick { obs.update(self) }
          end
        end

        # Sets the sensors value
        #
        # @param [Int] val The actual sensor value.
        def value=(val)
          @value=val
        end
      end

      # AnalogSensorsClient initialization requires 4 rates to set up ADC reading rate
      #
      # The rates given will be used for AN0 to AN3. If no readings are necessary, rate should be set to 0
      #
      # @param [List] snesors A list of Sensors instances
      def initialize(*sensors)
        @adc = MCP342x.new
        @sensors = []

        sensors.each do |s|
          s.add_observer(self)
          s.chip = @adc
          @sensors << s
        end
      end

      # Returns AN sensor
      #
      # @param [Int] index Index of sensor to return
      def [](index)
        @sensors[index]
      end

      # Starts all ADC readings
      def start
        @sensors.each do |s|
          s.start
        end
      end

      # Stops all ADC readings
      def stop
        @sensors.each do |s|
          s.stop
        end
      end

      # Emits faye message when value is received
      #
      def update(sensor)
        Raspeomix.logger.debug "new value on sensor : #{sensor.value}"
        message = { :type => :analog_value,
                    :analog_value => {
                      :profile => sensor.profile.name,
                      :unit => sensor.profile.unit,
                      :raw_value => sensor.value,
                      :converted_value => RPNCalculator.evaluate(sensor.profile.convertion_formula.gsub('x', sensor.value)) }
        }
        publish("/sensors/analog/#{sensor.channel}", message.to_json)
      end
    end

  end
end

