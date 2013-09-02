#!/usr/bin/env ruby

require 'raspeomix'

EM.run {
  client = Raspeomix::Client::Sound.new
}
