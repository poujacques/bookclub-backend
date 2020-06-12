# Resources are for anything that should be universally accessible

module Resources
  def get_db_string()
    ENV["BOOKCLUB_MDB_STRING"]
  end
end
