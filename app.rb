%w(rubygems oa-oauth dm-core dm-sqlite-adapter dm-migrations sinatra).each { |dependency| require dependency }
require 'sinatra'
require 'dm-core'
require 'dm-migrations'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/data2.db")

class User
  include DataMapper::Resource
  property :id,         Serial
  property :uid,        String
  property :name,   String
  property :nickname,       String
  property :created_at, DateTime
  has n, :notes
end

class Note
  include DataMapper::Resource
    property :id, Serial
    property :user_id, String
    property :content, Text, :required => true
    property :complete, Boolean, :required => true, :default => false
    property :created_at, DateTime
    property :updated_at, DateTime
    belongs_to :user, :required => false
end

DataMapper.finalize
DataMapper.auto_upgrade!
APP_TITLE = "Mocknote"

use OmniAuth::Strategies::Twitter, 'l0kAScjfkrGN970LCRcwg', 'F5B5BZQCxcJGFts0OPAVmBCwQJYwUOpBJjT12oT5CA'

enable :sessions

helpers do
  def current_user
    @current_user ||= User.get(session[:user_id]) if session[:user_id]
  end
end

get '/auth/:name/callback' do
  auth = request.env['omniauth.auth']
  user = User.first_or_create({ :uid => auth["uid"]}, {
  :uid => auth["uid"],
  :name => auth["user_info"]["name"],
  :nickname => auth["user_info"]["nickname"],
  :created_at => Time.now })
  session[:user_id] = user.id
  redirect '/all'
end

# aany of the following routes should work to sign the user in: 
#   /sign_up, /signup, /sign_in, /signin, /log_in, /login
["/sign_in/?", "/signin/?", "/log_in/?", "/login/?", "/sign_up/?", "/signup/?"].each do |path|
  get path do
    redirect '/auth/twitter'
  end
end

# either /log_out, /logout, /sign_out, or /signout will end the session and log the user out
["/sign_out/?", "/signout/?", "/log_out/?", "/logout/?"].each do |path|
  get path do
    session[:user_id] = nil
    redirect '/'
  end
end

get '/' do
  if current_user
    redirect '/all'
  else
   # '<a href="/sign_up">create an account</a> or <a href="/sign_in">sign in with Twitter</a>'
    redirect '/home'
  end
end

post '/' do
  n = Note.new
  n.content = params[:content]
  n.created_at = Time.now
  n.updated_at = Time.now
  puts "USER WAS :: #{params[:user]}"
  n.user_id = params[:user]
  n.save
  redirect '/all'
end

put '/:id' do
  n = Note.get params[:id]
  n.content = params[:content]
  n.complete = params[:complete] ? 1 : 0
  n.updated_at = Time.now
  n.save
  redirect '/all'
end

get '/home' do
  erb :home
end

get '/books' do
  @notes = Note.all(:user_id => current_user.id) & Note.all(:content.downcase.like => '%book%')
  @title = 'Books you want to read.'
  erb :books
end

get '/movies' do
  @notes = Note.all(:user_id => current_user.id) & Note.all(:content.downcase.like => '%book%')
  @title = 'Movies you want to see.'
  erb :movies
end

get '/all' do
  puts "Curren user is #{current_user.id}"
  @notes = Note.all(:conditions => { :user_id => current_user.id })  
  @title = "All notes"
  erb :all
end

delete '/:id/' do
  n = Note.get params[:id]
  n.destory
  redirect '/'
end

get '/:id/edit' do
  @note = Note.get params[:id]
  @title = "Categorize ##{params[:id]}" 
  erb :edit
end

get '/:id/complete' do
  n = Note.get params[:id]
  #n.complete = n.complete ? 0 : 1
  #n.updated_at = Time.now
  n.destroy
  redirect '/'
end

get '/:id/complete' do
 n = Note.get params[:id]
 n.destroy
 redirect '/'
end

get '/about' do
  'Muxnote is a simplified mobile app to track movies you want to see and books you want to read.'
end

not_found do  
  halt 404, 'page not found'  
end 