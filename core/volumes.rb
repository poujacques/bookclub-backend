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
    # Input should be current date or something
    # or maybe just do it here idk why I would make the frontend work harder than it has to
    # oh I know, its so we can be able to get the data from any time duh
    top_ten = []

    nyt_uri = URI(NYT_URI)
    params = { 'api-key': NYT_API_TOKEN }
    nyt_uri.query = URI.encode_www_form(params)
    nyt_response = JSON.parse(Net::HTTP.get(nyt_uri))

    for i in 0..9
      isbn = nyt_response["results"]["books"][i]["primary_isbn13"]
      top_ten.append(JSON.parse(get_volumes_result("/volumes", "isbn:" + isbn)))
    end
    top_ten.to_json
  end
end
