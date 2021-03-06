# Repositories is for any database-related actions
# TODO: Instead of deleting items, set them to `deleted: true`

require "mongo"
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
    result = client[:sessions].find({ "access_token": token }).delete_one
    client.close
    result.n > 0
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
          "user_id": user_id,
          "access_token": access_token,
        }
      ).first
    client.close
    result
  end

  def create_user(userdata)
    user_id = generate_uuid()
    userdata[:user_id] = user_id
    userdata[:date_created] = Time.now
    client = get_db
    result = client[:users].insert_one(userdata)
    client.close
    response = result.n > 0 ? user_id : nil
    response
  end

  def get_user_from_username(username)
    client = get_db
    user = client[:users].find("username": username).first
    client.close
    user
  end

  def insert_shelf(new_shelf)
    shelf_id = generate_uuid()
    new_shelf[:shelf_id] = shelf_id
    client = get_db
    result = client[:shelves].insert_one(new_shelf)
    client.close
    response = result.n > 0 ? shelf_id : nil
    response
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

  def get_user_profile(user_id)
    client = get_db
    profile = client[:profiles].find("user_id": user_id).first
    client.close
    profile
  end

  def insert_profile(new_profile)
    profile_id = generate_uuid()
    new_profile[:profile_id] = profile_id
    client = get_db
    result = client[:profiles].insert_one(new_profile)
    client.close
    response = result.n > 0 ? profile_id : nil
    response
  end

  def update_profile(user_id, profile_updates)
    client = get_db
    profile = client[:profiles].update_one(
      {
        "user_id": user_id,
      },
      { "$set": profile_updates },
    )
    client.close
    profile
  end

  def insert_review(new_review)
    review_id = generate_uuid()
    new_review[:review_id] = review_id
    new_review[:date_created] = Time.now
    client = get_db
    review = client[:reviews].insert_one(new_review)
    client.close
    response = review.n > 0 ? review_id : nil
    response
  end

  def get_reviews_by_volume_id(volume_id)
    client = get_db
    review = client[:reviews].find("volume_id": volume_id)
    client.close
    review
  end

  def get_reviews_by_user_id(user_id)
    client = get_db
    review = client[:reviews].find("user_id": user_id)
    client.close
    review
  end

  def get_review_by_volume_and_user(volume_id, user_id)
    client = get_db
    review = client[:reviews].find("volume_id": volume_id, "user_id": user_id).first
    client.close
    review
  end

  def delete_review(review_id)
    client = get_db
    result = client[:reviews].find({ "review_id": review_id }).delete_one
    client.close
    result.n > 0
  end
end
