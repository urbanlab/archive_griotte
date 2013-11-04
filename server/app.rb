require 'sinatra'
require 'faye'

ROOT_DIR = File.expand_path('../', __FILE__)

#set :root, ROOT_DIR
set :logging, true
#set :public, ROOT_DIR.'/public/'
set :static, true
 
# Change me
set :password, 'foobar'
set :app_id, 'raspeomix-123456'
set :token, (0...32).map { (97 + rand(26)).chr }.join

enable :sessions

# Authentication helpers
helpers do
  def admin? ; session[settings.app_id] == settings.token ; end
  def protected! ; redirect '/login/' unless admin? ; end
end

get '/favicon.ico' do
  halt 404
end

get '/login/?' do
  redirect '/admin/' if admin?
  pass
end

get '/logout/?' do
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

get '/admin/?' do
  protected!
  pass
end

# # Redirects to the same place with a / at the end
# # Note that this prevents sinatra from serving file in the top directory
# get '/:dir' do
#   redirect "#{params[:dir]}/"
# #  File.read(ROOT_DIR + "/public/#{params[:dir]}/index.html')
# end
# 

get '/cartels/:id/?' do
  lang = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
  localized = File.join(ROOT_DIR, 'public', 'cartels', params[:id], lang, 'index.html')
  puts "lang is #{lang} / localized path could be #{localized}"
  redirect "/cartels/#{params[:id]}/#{lang}/index.html" if File.exists?(localized)
  pass 
end

#get '/:dir/' do
#  File.read(File.join(ROOT_DIR, 'public', params[:dir], 'index.html'))
#end
# 

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

