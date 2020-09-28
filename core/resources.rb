# Resources are for anything that should be universally accessible
require "securerandom"

module Resources
  def get_db_string()
    ENV["BOOKCLUB_MDB_STRING"]
  end

  def get_nyt_api_token()
    ENV["NYT_API_TOKEN"]
  end

  def get_default_shelfnames()
    ["currently_reading", "previously_read", "want_to_read"]
  end

  def get_profile_fields()
    # TODO: We should probably try and enforce types here
    [
      "first_name", # String
      "last_name", # String
      "location", # String
      "birthday", # Date
      "bio", # String
      "profile_picture", # String, a link to something (with a default link provided if null)
      "favourite_book", # String, preferrably a Volume ID but I guess it can just be a title for now
    ]
  end

  def generate_uuid()
    SecureRandom.uuid.gsub("-", "")
  end

  def get_max_min_ratings()
    # Min, Max
    return 0, 5
  end
end
