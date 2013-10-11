require 'sinatra'
require 'faye'

ROOT_DIR = File.expand_path('../', __FILE__)

set :root, ROOT_DIR
set :logging, false

# Change me
set :password, 'foobar'
set :app_id, 'raspeomix-123456'
set :token, (0...32).map { (97 + rand(26)).chr }.join

enable :sessions

# Authentication helpers
helpers do
  def admin? ; session[settings.app_id] == settings.token ; end
  def protected! ; halt [ 401, 'Not Authorized' ] unless admin? ; end
end

get '/favicon.ico' do
  halt 404
end

get '/login/' do
  redirect '/admin/' if admin?
  File.read(File.join(ROOT_DIR, 'public/login/index.html'))
end

get '/logout/' do
  session.clear
  redirect '/login/'
end

post '/login/' do
  if params['password'] == settings.password
    session[settings.app_id] = settings.token
    redirect '/admin/'
  else
    redirect '/login/'
  end
end

# Redirects to the same place with a / at the end
# Note that this prevents sinatra from serving file in the top directory
get '/:dir' do
  redirect "#{params[:dir]}/"
#  File.read(ROOT_DIR + "/public/#{params[:dir]}/index.html')
end

get '/admin/' do
  protected!
  File.read(File.join(ROOT_DIR, 'public/admin/index.html'))
end

get '/:dir/' do
  File.read(File.join(ROOT_DIR, 'public', params[:dir], 'index.html'))
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

