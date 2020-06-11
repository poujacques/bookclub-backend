# Repositories is for any database-related actions

require "mongo"
require "securerandom"
require "date"

require "./core/resources.rb"

Mongo::Logger.logger.level = Logger::FATAL

# Init Database
MDB_STRING = get_db_string

def get_db()
  client = Mongo::Client.new(MDB_STRING)
  client
end

def delete_token(token)
  client = get_db
  result = client[:sessions].find({ access_token: token }).delete_one
  result.n
end

def generate_token(user_id)
  access_token = SecureRandom.uuid.gsub("-", "")
  refresh_token = SecureRandom.uuid.gsub("-", "")
  expiry = Time.now + 60 * 60 * 24 * 14
  token = {
    user_id: user_id,
    access_token: access_token,
    # refresh_token: refresh_token, # Temporarily deactivated until we build logic for this
    expiry: expiry,
  }
  client = get_db
  client[:sessions].insert_one(token)
  token
end

def get_token(user_id, access_token)
  client = get_db
  result =
    client[:sessions].find({ user_id: user_id, access_token: access_token })
      .first
  result
end

def create_user(userdata)
  user_id = SecureRandom.uuid.gsub("-", "")
  userdata["id"] = user_id
  client = get_db
  result = client[:users].insert_one(userdata)
  user_id if result.n > 0
end

def get_user_from_username(username)
  client = get_db
  user = client[:users].find("username": username).first
  user
end
