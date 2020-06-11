def get_db_string()
  ENV['BOOKCLUB_MDB_STRING']
end

def get_port()
  port = ENV['DEFAULT_PORT']
  port = 8080 if !port
  port
end
