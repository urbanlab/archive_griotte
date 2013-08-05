require "rubygame"

include Rubygame
include Rubygame::Events

file = '/media/external/P1040804.JPG'
screen = Screen.open( [1000,200] )

image = Surface.load file
image.blit screen, [0,0]

screen.update
screen.show_cursor = false
#image.blit( screen, [0,0] )

sleep 5
