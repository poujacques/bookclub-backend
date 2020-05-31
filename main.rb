require 'sinatra'
require 'sinatra/namespace'
require 'net/http'

# env variables
port = ENV['DEFAULT_PORT']
if !port
  port = 8080
end

set :port, port

# puts ENV['BOOKS_API_TOKEN'] # API Token not necessary for search

def get_result(query)
  uri = URI("https://www.googleapis.com/books/v1/volumes")
  params = { :q => query }
  uri.query = URI.encode_www_form(params)
  Net::HTTP.get(uri)
end

namespace '/api/v1' do

  before do
    content_type :json
  end

  get '/search' do
    q = params[:q]
    get_result(q)
  end

end

## Todo
# abstract functions into new modules
# create a webserver object and have a uri variable