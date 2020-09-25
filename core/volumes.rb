# For any volume related functionality

require "net/http"
require "json"

module Volumes
  extend Resources
  BASE_URI = "https://www.googleapis.com/books/v1"
  NYT_URI = "https://api.nytimes.com/svc/books/v3/lists/current/combined-print-and-e-book-fiction.json"
  NYT_API_TOKEN = get_nyt_api_token()

  def get_volumes_result(uri_path, query = nil)
    uri = URI(BASE_URI + uri_path)
    if query
      params = { q: query }
      uri.query = URI.encode_www_form(params)
    end
    Net::HTTP.get(uri)
  end

  def get_nyt_top_10()
    volume_list = []

    nyt_uri = URI(NYT_URI)
    params = { 'api-key': NYT_API_TOKEN }
    nyt_uri.query = URI.encode_www_form(params)
    nyt_response = JSON.parse(Net::HTTP.get(nyt_uri))
    nyt_volume_data = nyt_response[:results][:books]

    i = 0
    n = 10
    while i < n
      response_object = { :nyt => nyt_volume_data[i], :rank => nyt_volume_data[i][:rank] }
      isbn = nyt_volume_data[i][:primary_isbn13]
      response_object[:google_books] = JSON.parse(get_volumes_result("/volumes", "isbn:" + isbn))
      volume_list.append(response_object)
      i += 1
    end
    volume_list
  end
end
