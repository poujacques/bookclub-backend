# The driver. Defines the webserver and its endpoints.

require './auth/auth.rb'
require './core/resources.rb'
require './core/volumes.rb'

require 'sinatra'
require 'sinatra/cross_origin'
require 'sinatra/namespace'
require 'json'

port = get_port()

# CORS
configure do
  enable :cross_origin
end  

before do
  response.headers['Access-Control-Allow-Origin'] = '*'
end

set :port, port

# Webserver
namespace '/api/v1' do

  before do
    content_type :json
  end

  get '/volumes' do
    q = params[:q]
    get_volumes_result("/volumes", q)
  end

  get '/volumes/:volume_id' do |volume_id|
    get_volumes_result("/volumes/" + volume_id)
  end

  post '/register' do
    data = JSON.parse(request.body.read)
    username = data["username"]
    pw = data["password"]
    email = data["email"]
    register_user(username, pw, email)
  end

  post '/login' do
    data = JSON.parse(request.body.read)
    username = data["username"]
    pw = data["password"]
    verify_user(username, pw)
  end

  post '/deactivate' do
    data = JSON.parse(request.body.read)
    access_token = data["access_token"]
    deactivate_token(access_token)
  end

  get '/:user_id/protected_endpoint' do |user_id|
    access_token = request.env["HTTP_AUTHORIZATION"]
    if !access_token
      return "Missing Authorization header in request to protected endpoint"
    end
    
    access_token = access_token.sub("Bearer ", "")
    error = verify_token(user_id, access_token)
    if error
      return error
    end
    "Successfully accessed data using correct credentials"
  end

end
