require 'logger'
#require 'faye'

class NullObject
  def method_missing(*args, &block)
    nil
  end
end

module Raspeomix

  # FayeLogger class sends log to faye channel /log
  #
  class FayeLogger
    include Client::FayeClient

    LEVELS = { 'D' => 'debug',
               'I' => 'info',
               'W' => 'warn',
               'E' => 'error',
               'F' => 'fatal', }

    # Writes logs to faye
    #
    # @param [String] message message to send to the Faye log
    def write(message)
      publish("/log/#{LEVELS[message[0]]}", { :message => message })
    end

    # Required to be a logger
    #
    def close
      true
    end
  end

  def self.logger
    @logger ||= initialize_log
  end

  def self.logger=(logger)
    @logger = logger
  end

  # Initilizes logger
  #
  # @todo check if file is passed, and activate log trimming (shift_age = 0,
  # shift_size = 1048576)
  def self.initialize_log
    #
    # If RASP_LOG is not defined, we return a Null logger
    return NullObject.new unless ENV['RASP_LOG']

    # Set log to RASP_LOG environment variable
    log = ENV['RASP_LOG'] if (ENV['RASP_LOG'])
    
    # STDOUT logging mode
    log = STDOUT if (ENV['RASP_LOG'] == 'STDOUT')

    # FAYE logging mode
    log = FayeLogger.new if log == 'FAYE'

    # RASP_LOG was defined but empty, return Null logger
    return NullObject.new if log == ""

    begin
      Logger.new(log)
    rescue Exception => e
      puts "Unable to open log : #{e.message} - using STDOUT"
      Logger.new(STDOUT)
    end
  end
end

