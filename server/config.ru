# config.ru
# bundle exec rackup -s thin -E production config.ru
require 'faye'
#require 'grape'

require File.expand_path('../app', __FILE__)

Faye::WebSocket.load_adapter('thin')

run App

