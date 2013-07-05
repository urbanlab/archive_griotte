#!/usr/bin/env ruby
#
#TODO
#volume en %
#initialisation (volume de départ, position de départ)
#position du lecteur en fonction de l'écran ?
#vitesse de lecture ?
#sous titres ?

require 'securerandom'

$DEBUG=true

class Fifo

  attr_reader :path

  def initialize(path="/tmp/fifo_#{SecureRandom.uuid}")
    @path = path
    @started = false
    %x{mkfifo #{@path}}
    puts "fifo initialized @ #{@path}" if $DEBUG
  end

  def start
    if $DEBUG
      print "starting"
      sleep(0.2)
     print"."
      sleep(0.2)
      print"."
      sleep(0.2)
      print"."
      sleep(0.2)
      print"."
      sleep(0.2)
      print"."
      sleep(0.2)
      puts"."
    else
      sleep(1)
    end
    sleep(0)
    send('.') unless @started
    @started = true
    puts "started" if $DEBUG
  end

  def send(char)
    open(@path, "w+") do |f|
      f.write char
      puts "command #{char} sent" if $DEBUG
      sleep(0.05)
    end
  end

  def close
    %x{rm #{@path}} #TODO coder ça en ruby
  end
end

class OMXWrapper
  PAUSECHAR = 'p'
  QUITCHAR = 'q'
  LVLDWN = '-'
  LVLUP = '+'

  def initialize
    @fifo = Fifo.new()
    @level = 0
    @playing = false
  end

  def setlvl(lvl, options = { :units => :percent })
    #TODO gerer les %
    buff_lvl = @level
    real_lvl = (lvl/3.round)*3
    puts "lvl asked is #{lvl}, real lvl is #{real_lvl}"
    while @level != real_lvl
      if @level > real_lvl
        @fifo.send(LVLDWN)
        @level -= 3
      else
        @fifo.send(LVLUP)
        @level += 3
      end
    end
    puts "level changed from #{buff_lvl} to #{@level}" if $DEBUG
  end

  def load(file)
    @pipe = IO.popen("omxplayer -l 20 #{file} < #{@fifo.path}")
    puts "spawned #{@pipe.pid}\n\n" if $DEBUG
    @fifo.start
    @playing = true
  end

  def play
    toggle_play unless @playing
  end

  def pause
    toogle_play if @playing
  end

  def stop
    @fifo.send(QUITCHAR)
    Process::waitpid(@pipe.pid)
    puts "process seems finished" if $DEBUG
    @fifo.close
    puts "fifo deleted" if $DEBUG
  end

  def toogle_play
    @fifo.send(PAUSECHAR)
    @playing = !@playing
  end

end

# Use case

#puts "starting test"
#player = OMXWrapper.new
#player.load("/media/external/videofinale.mp4")
#sleep(5)
#player.setlvl(-50)
#sleep(10)
#player.pause
#sleep(3)
#player.stop
#puts "ending test"
