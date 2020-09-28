require "./core/repository.rb"
require "./core/errors.rb"

module Reviews
  extend Resources
  include BookclubErrors, Repository

  MIN_RATING, MAX_RATING = get_max_min_ratings()

  def get_volume_reviews(volume_id)
    get_reviews_by_volume_id(volume_id).map { |review| review }
  end

  def get_user_reviews(user_id)
    get_reviews_by_user_id(user_id).map { |review| review }
  end

  def remove_review(review_id)
    if delete_review(review_id)
      raise ReviewError.new(404, "Could not delete review: No such review found in database")
    end
  end

  def verify_review_input(volume_id, user_id, rating)
    if volume_id.nil? || volume_id.empty?
      raise ReviewError.new(400, "Missing `volume_id` in request")
    elsif user_id.nil? || user_id.empty?
      raise ReviewError.new(400, "Missing `user_id` in request")
    elsif rating.nil?
      raise ReviewError.new(400, "Missing `rating` in request")
    end
  end

  def get_user_volume_review(volume_id, user_id)
    get_review_by_volume_and_user(volume_id, user_id)
  end

  def add_review(volume_id, user_id, rating, review = nil)
    verify_review_input(volume_id, user_id, rating)

    if !get_user_volume_review(volume_id, user_id).nil?
      raise ReviewError.new(409, "Review for volume already exists for current user")
    end

    begin
      rating_int = Integer(rating)
      rating_int = [MIN_RATING, rating_int].max
      rating_int = [MAX_RATING, rating_int].min
    rescue ArgumentError => e
      raise ReviewError.new(400, "Invalid rating provided in request")
    end
    new_review = {
      :volume_id => volume_id,
      :user_id => user_id,
      :rating => rating_int,
      :review => review,
    }
    review_id = insert_review(new_review)
    if review_id.nil?
      raise ReviewError.new(500, "Unable to save result to db")
    end
    review_id
  end
end
