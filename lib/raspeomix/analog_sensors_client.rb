#!/usr/bin/env ruby
#
#video client for Raspéomix
#handles communication between scheduler
#and OMXPlayer ruby wrapper

require "i2c"
require "i2c/i2c"

module Raspeomix

  # Class AnalogSensorsClient handles the 4 analog senors and sends read values on the wire
  #
  class AnalogSensorsClient

    # Class MCP342x handles MCP342x ADC communications
    class MCP342x
      include Raspeomix::Reporter

      # Constants for configuration register, datasheet page 18
      #
      # Sample rate selection bits (S1-S0)
      RESOLUTION = { :'12bits' => 0b00000000,
                     :'14bits' => 0b00000100,
                     :'16bits' => 0b00001000,
                     :'18bits' => 0b00001100,
                     :'240sps'  => 0b00000000,
                     :'60sps'   => 0b00000100,
                     :'15sps'   => 0b00001000,
                     :'3_75sps' => 0b00001100 }

      # PGA settings
      PGA = { :'1x' => 0b00000000,
              :'2x' => 0b00000001,
              :'4x' => 0b00000010,
              :'8x' => 0b00000011 }

      # Channels
      CHANNEL = { :an0 => 0b00000000,
                   :an1 => 0b00100000,
                   :an2 => 0b01000000,
                   :an3 => 0b01100000 }

      # LSB in µV (cf datasheet table 4-1 p15)
      LSB = { :'12bits'  => 1000,
              :'14bits'  => 250,
              :'16bits'  => 62.5,
              :'18bits'  => 15.625,
              :'240sps'  => 1000,
              :'60sps'   => 250,
              :'15sps'   => 62.5,
              :'3_75sps' => 15.625 }
      # Misc constants
      C_READY = 0b10000000   # ready bit
      C_OC_MODE = 0b00010000 # single shot mode

      # Resistors divider ratio (R20+R21)/R21 required to scale back input voltage
      # Cf https://raw.github.com/hugokernel/RaspiOMix/master/export/1.0.1/images/schema.png
      # Ratio for 4k7 / 10k
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
      def get_channel(channel=:an0, resolution=:'18bits', pga=:'1x')
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
      def initialize
      end

      # Returns last read sensor value
      #
      # @return [Int] the sensor value in µV
      def value
        @value
      end

      # Returns the current sensor reading rate
      #
      # @return [Float] the number of measurements per second
      def rate
        @rate
      end

      # Sets the sensors reading rate
      #
      # @param [Float] rate The number of expected readins per second
      def rate=(rate)
        @rate = rate
      end

      private

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
    # @param [Array] rates The rates to use for the 4 sensors
    def initialize(*rates)
      @sensors = Array.new(4) { Sensor.new }
      if rates.length != 4
        raise ArgumentError,
          "4 rates are required when initializing AnalogSensorsClient"
      end

      4.times do |n|
        @sensors[n].rate = rates[n]
      end
    end

    # Returns AN sensor
    #
    # @param [Int] index Index of sensor to return
    def [](index)
      @sensors[index]
    end

    # Starts ADC readings
    def start
    end

    # Stops ADC readings
    def stop
    end
  end

end
