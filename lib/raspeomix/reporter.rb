require 'logger'

module Raspeomix
  module Reporter

    @log = nil

    def initialize_log
      if ENV['RASP_LOG'] == 'STDOUT'
        @log = ::Logger.new(STDOUT)
      else 
        @log = ::Logger.new(ENV['RASP_LOG']) rescue "No logging defined"
      end
      @log
    end

    def log
      @log or initialize_log
    end
  end
end

