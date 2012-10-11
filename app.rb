require 'rubygems'
require 'sinatra'
require 'rest-client'
require 'json'
require 'erb'

AUDIENCE = "example.com:4567"

configure do
  Sinatra::Application.reset!
  use Rack::Reloader
end

enable :sessions
set :session_secret, 'abc123'

error 400..510 do
  'http error...'
end

helpers do
  def logged_in?
    (@auth_email && !@auth_email.empty?) ? true : false
  end
end

get '/' do
  @params = params
  @auth_email = session[:auth_email] || ""
  erb :index
end

post '/logout' do
  session[:auth_email] = nil
  session.clear
  redirect '/'
end

post '/login' do
  content_type :json
  post_params = {
    :assertion => params["assertion"],
    :audience  => AUDIENCE,
  }
  resp = RestClient.post("https://verifier.login.persona.org/verify", post_params)
  data = JSON.parse(resp)
  if data["status"].eql?("okay")
    session[:auth_email] = data["email"]
    puts "successful login of #{session[:auth_email]}"
    data.to_json
  else
    puts "not sure about the data: #{data.inspect}"
    return {:status => "error"}.to_json
  end
end
