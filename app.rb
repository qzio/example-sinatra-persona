require 'rubygems'
require 'sinatra'
require 'rest-client'
require 'json'
require 'erb'

configure do
  Sinatra::Application.reset!
  use Rack::Reloader
end

# you need to change this accordingly
AUDIENCE = "http://example.com:4567"
# change session_secret for obvious reason
set :session_secret, 'you_must_change_me'

enable :sessions


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
  resp = RestClient::Resource.new("https://verifier.login.persona.org/verify",
                                  :verify_ssl => true
                                 ).post(post_params)
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
