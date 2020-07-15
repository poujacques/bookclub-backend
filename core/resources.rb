# Resources are for anything that should be universally accessible

module Resources
  def get_db_string()
    ENV["BOOKCLUB_MDB_STRING"]
  end

  def get_default_shelfnames()
    ["currently_reading", "previously_read", "want_to_read"]
  end

  def get_profile_fields()
    ["bio", "profile_picture", "favourite_book"]
  end
end

# TODO: Move UUID generator here (securerandom)
