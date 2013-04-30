
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'

  add_group 'Libraries', 'lib'
  add_group 'Clients', 'clients'
  add_group 'Server', 'server'
end if ENV["COVERAGE"]

#require 'rack/test'
