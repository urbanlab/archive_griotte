#!/usr/bin/dev ruby

require 'raspeomix'
require 'eventmachine'



EM.run {
  s = Raspeomix::ScenarioHandler.new
  omxclient = Raspeomix::Client::Video.new
  omxclient.load("/media/external/videofinale.mp4")
  omxclient.start(0)

  EM.add_timer(2) {
    omxclient.pause
  }
  
  EM.add_timer(10) {
    omxclient.play
  }

}
