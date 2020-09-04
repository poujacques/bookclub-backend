# For any volume related functionality

require "net/http"
require "json"

module Volumes # There should be a class for this
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
    # Will it always be 10? Why did I hardcode this? Silly mistakes ¯\_(ツ)_/¯
    top_ten = []

    nyt_uri = URI(NYT_URI)
    params = { 'api-key': NYT_API_TOKEN }
    nyt_uri.query = URI.encode_www_form(params)
    nyt_response = JSON.parse(Net::HTTP.get(nyt_uri))
    books_list = nyt_response["results"]["books"]

    for i in 0..9
      response_object = { "nyt": books_list[i], "rank": books_list[i]["rank"] }
      isbn = books_list[i]["primary_isbn13"]
      response_object["google_books"] = JSON.parse(get_volumes_result("/volumes", "isbn:" + isbn))
      top_ten.append(response_object)
    end
    top_ten.to_json
  end
end
