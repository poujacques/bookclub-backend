def get_db_string()
  ENV['BOOKCLUB_MDB_STRING']
end

def get_port()
  port = ENV['DEFAULT_PORT']
  if !port 
    port = 8080
  end
  port
end