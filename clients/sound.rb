#!/usr/bin/ruby

require 'raspeomix'

EM.run {
  client = Raspeomix::Sound.new(Raspeomix::SoundHandlerAlsa.new)
}

