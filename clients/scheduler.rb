#!/usr/bin/env ruby

require 'raspeomix'

EM.run {
  client = Raspeomix::Scheduler.new
  client.run_video_test_sequence
}
