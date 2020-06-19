# For any volume related functionality

require "net/http"

module Volumes # There should be a class for this
  BASE_URI = "https://www.googleapis.com/books/v1"

  def get_volumes_result(uri_path, query = nil)
    uri = URI(BASE_URI + uri_path)
    if query
      params = { q: query }
      uri.query = URI.encode_www_form(params)
    end
    Net::HTTP.get(uri)
  end
end
