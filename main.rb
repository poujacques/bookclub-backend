require 'sinatra'
require 'sinatra/cross_origin'
require 'sinatra/namespace'
require 'net/http'

# env variables
port = ENV['DEFAULT_PORT']
if !port
  port = 8080
end

configure do
  enable :cross_origin
end  

before do
  response.headers['Access-Control-Allow-Origin'] = '*'
end

set :port, port

# puts ENV['BOOKS_API_TOKEN'] # API Token not necessary for search

def get_volumes_result(uri_path, query=nil)
  base_uri = "https://www.googleapis.com/books/v1"
  uri = URI(base_uri + uri_path)
  if !query.nil?
    params = { :q => query }
    uri.query = URI.encode_www_form(params)
  end
  Net::HTTP.get(uri)
end

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

end

## Todo
# abstract functions into new modules
# create a webserver object and have a uri variable
