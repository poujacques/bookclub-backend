# For any shelf related functionality

require "./core/resources.rb"
require "./core/repository.rb"
require "./core/errors.rb"
require "date"

module Shelves #This should be a Class
  include BookclubErrors, Repository, Resources

  def initialize_shelf(user_id)
    shelf = {
      user_id: user_id,
      type: "exclusive",
      volumes: [],
    }
    insert_shelf(shelf)
    shelf
  end

  def get_user_shelf(user_id, query = nil)
    shelf = get_exclusive_shelf(user_id)
    if shelf.nil?
      shelf = initialize_shelf(user_id)
    end

    shelf_response = {}

    shelf["volumes"].each do |x|
      if !shelf_response.key?(:a)
        shelf_response[x["shelf"]] = []
        shelf_response[x["shelf"] + "_count"] = 0
      end
      shelf_response[x["shelf"]].append(x) #Actually let's append the book data from the api
      shelf_response[x["shelf"] + "_count"] += 1
    end

    shelf_response.to_json
  end

  def get_volume_from_shelf(volume_id, current_shelf)
    volume = nil
    if !current_shelf["volumes"].nil?
      current_shelf["volumes"].each do |e|
        if e["volume_id"] == volume_id
          volume = e
        end
      end
    end
    volume
  end

  def get_currently_reading_from_shelf(current_shelf)
    volume = nil
    if !current_shelf["volumes"].nil?
      current_shelf["volumes"].each do |e|
        if e["shelf"] == "currently_reading"
          volume = e
        end
      end
    end
    volume
  end

  def calculate_reading_time(volume)
    total_time = nil
    start_time = volume["start_time"]
    end_time = volume["end_time"]
    if start_time && end_time && start_time <= end_time
      total_time = end_time - start_time
    end
    total_time
  end

  def verify_shelf_operation_data(operation, volume_id, to_shelf)
    if operation.nil? || operation.empty?
      raise ShelfOpError.new(400, "Missing `operation` in request")
    elsif volume_id.nil? || volume_id.empty?
      raise ShelfOpError.new(400, "Missing `volume_id` in request")
    elsif operation != "delete" && (to_shelf.nil? || to_shelf.empty?)
      raise ShelfOpError.new(400, "Missing `to_shelf` in request")
    end
  end

  def modify_exclusive_shelves(user_id, operation, volume_id, to_shelf, set_completed = false)
    verify_shelf_operation_data(operation, volume_id, to_shelf)
    current_shelf = get_exclusive_shelf(user_id)
    if current_shelf.nil?
      current_shelf = initialize_shelf(user_id)
    end

    # True if the volume to modify is also the user's currently reading
    currently_reading = get_currently_reading_from_shelf(current_shelf)

    case operation
    when "upsert"
      handle_upsert_to_shelf(user_id, volume_id, to_shelf, set_completed, current_shelf, currently_reading)
    when "delete"
      handle_remove_from_shelf(user_id, volume_id)
    else
      puts "no op"
      raise ShelfOpError.new(400, "Invalid operation provided")
    end
  end

  def handle_remove_from_shelf(user_id, volume_id)
    result = remove_volume_from_exclusive_shelf(user_id, volume_id)
    { volumes_deleted: result.modified_count }.to_json
  end

  def handle_upsert_to_shelf(user_id, volume_id, to_shelf, set_completed, current_shelf, currently_reading)
    # Not nil if the volume already exists in the user's shelf
    current_volume_data = get_volume_from_shelf(volume_id, current_shelf)

    if current_volume_data && (current_volume_data["shelf"] == to_shelf)
      # no op when trying to move a volume to the same shelf
      raise ShelfOpError.new(304, "Not Modified")
    end

    new_volume_data = {
      volume_id: volume_id,
      shelf: to_shelf,
    }

    case to_shelf
    when "currently_reading"
      if !currently_reading.nil?
        transfer_shelf = set_completed ? "previously_read" : "want_to_read"
        modify_exclusive_shelves(user_id, "upsert", currently_reading["volume_id"], transfer_shelf, false)
      end
      # bump_currently_reading(user_id, current_shelf, set_completed)

      new_volume_data["start_time"] = Time.now
    when "previously_read"
      if !currently_reading.nil?
        new_volume_data["start_time"] = currently_reading["start_time"]
        new_volume_data["end_time"] = Time.now
      end
    when "want_to_read"
      # Nothing special to be done here, but eventually we should reset both the start and end fields
    else
      raise ShelfOpError.new(400, "Invalid shelf provided")
    end
    upsert_to_shelf(user_id, new_volume_data, current_volume_data)
  end

  # def bump_currently_reading(user_id, current_shelf, set_completed)
  # end

  def upsert_to_shelf(user_id, new_volume_data, current_volume_data)
    puts "before"
    puts get_exclusive_shelf(user_id)
    if !current_volume_data.nil?
      puts "updating now"
      result = update_volume_in_exclusive_shelf(user_id, new_volume_data)
      puts "after"
      puts get_exclusive_shelf(user_id)
      puts
      { volumes_modified: result.modified_count }.to_json
    else
      puts "adding now"
      result = add_volume_to_exclusive_shelf(user_id, new_volume_data)
      puts "after"
      puts get_exclusive_shelf(user_id)
      puts
      { volumes_added: result.modified_count }.to_json
    end
  end
end
