require 'raspeomix/client'

module Raspeomix
  class System
    include FayeClient

    def initialize
      start
      puts "Raspeomix System started"
    end
  end
end
