require 'eventmachine'
require 'faye'

project_root = File.dirname(File.absolute_path(__FILE__))
Dir.glob(project_root + '/raspeomix/*', &method(:require))
