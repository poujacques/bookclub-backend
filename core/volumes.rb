require 'net/http'

def get_volumes_result(uri_path, query=nil)
    base_uri = "https://www.googleapis.com/books/v1"
    uri = URI(base_uri + uri_path)
    if !query.nil?
      params = { :q => query }
      uri.query = URI.encode_www_form(params)
    end
    Net::HTTP.get(uri)
  end