require "rubygame"

include Rubygame
include Rubygame::Events

file = '/media/external/P1040804.JPG'
screen = Screen.open( [1000,200] )
puts Screen.instance_methods
sleep 10

image = Surface.load file
image.blit screen, [0,0]

screen.update
screen.show_cursor = false
#image.blit( screen, [0,0] )

sleep 2
Screen.close
sleep 2

