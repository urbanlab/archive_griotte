require 'logger'

class NullObject
  def method_missing(*args, &block)
    nil
  end
end

module Raspeomix
  def self.logger
    @logger ||= initialize_log
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.initialize_log
    return NullObject.new unless ENV['RASP_LOG']

    @do_log = true
    log = ENV['RASP_LOG'] if (ENV['RASP_LOG'])
    log = STDOUT if (ENV['RASP_LOG'] == 'STDOUT')

    begin
      Logger.new(log)
    rescue Exception => e
      puts "Unable to open log : #{e.message} - using STDOUT"
      Logger.new(STDOUT)
    end
  end
end

