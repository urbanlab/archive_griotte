require 'sinatra'
require 'faye'

ROOT_DIR = File.expand_path('../', __FILE__)

set :root, ROOT_DIR
set :logging, false

get '/' do
  File.read(ROOT_DIR + '/public/index.html')
end

#get '/post' do
#  env['faye.client'].publish('/mentioning/*', {
#    :user => 'sinatra',
#    :message => params[:message]
#  })
#  params[:message]
#end
Faye::Logging.log_level = :debug
Faye.logger = lambda { |m| puts m }

App = Faye::RackAdapter.new(Sinatra::Application,
  :mount   => '/faye',
  :timeout => 25
)

