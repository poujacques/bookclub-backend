# Repositories is for any database-related actions

require "mongo"
require "securerandom"
require "date"
require "./core/resources.rb"

module Repository
  extend Resources

  Mongo::Logger.logger.level = Logger::FATAL
  # Init Database
  MDB_STRING = get_db_string()

  def get_db()
    client = Mongo::Client.new(MDB_STRING)
    client
  end

  def delete_token(token)
    client = get_db
    result = client[:sessions].find({ access_token: token }).delete_one
    client.close
    result.n
  end

  def insert_token(token)
    client = get_db
    client[:sessions].insert_one(token)
    client.close
    token
  end

  def get_token(user_id, access_token)
    client = get_db
    result =
      client[:sessions].find(
        {
          user_id: user_id,
          access_token: access_token,
        }
      ).first
    client.close
    result
  end

  def create_user(userdata)
    user_id = SecureRandom.uuid.gsub("-", "")
    userdata["id"] = user_id
    client = get_db
    result = client[:users].insert_one(userdata)
    client.close
    user_id if result.n > 0
  end

  def get_user_from_username(username)
    client = get_db
    user = client[:users].find("username": username).first
    client.close
    user
  end

  def insert_shelf(new_shelf)
    shelf_id = SecureRandom.uuid.gsub("-", "")
    new_shelf["shelf_id"] = shelf_id
    client = get_db
    shelf = client[:shelves].insert_one(new_shelf)
    client.close
    shelf
  end

  def get_exclusive_shelf(user_id)
    client = get_db
    shelf = client[:shelves].find("user_id": user_id, "type": "exclusive").first
    client.close
    shelf
  end

  def remove_volume_from_exclusive_shelf(user_id, volume_id)
    client = get_db
    shelf = client[:shelves].update_one({ "user_id": user_id, "type": "exclusive" }, { "$pull": { "volumes": { "volume_id": volume_id } } })
    client.close
    shelf
  end

  def add_volume_to_exclusive_shelf(user_id, volume_data)
    client = get_db
    shelf = client[:shelves].update_one({ "user_id": user_id, "type": "exclusive" }, { "$push": { "volumes": volume_data } })
    client.close
    shelf
  end

  def update_volume_in_exclusive_shelf(user_id, volume_data)
    client = get_db
    shelf = client[:shelves].update_one(
      {
        "user_id": user_id,
        "type": "exclusive",
      },
      { "$set": { "volumes.$[volume]": volume_data } },
      { array_filters: [{ "volume.volume_id" => volume_data[:volume_id] }] },
    )
    client.close
    shelf
  end
end
