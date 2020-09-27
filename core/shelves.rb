# For any shelf related functionality

require "./core/resources.rb"
require "./core/repository.rb"
require "./core/errors.rb"
require "./core/volumes.rb"
require "date"
require "json"

module Shelves #This should be a Class, or at least redesigned to account for custom shelves
  include BookclubErrors, Repository, Resources, Volumes

  def initialize_shelf(user_id)
    shelf = {
      user_id: user_id,
      type: "exclusive",
      volumes: [],
    }
    shelf_id = insert_shelf(shelf)
    shelf[:shelf_id] = shelf_id
    shelf
  end

  def get_user_shelf(user_id, query = nil)
    shelf = get_exclusive_shelf(user_id)
    if shelf.nil?
      raise AuthError.new(404, "User does not exist or no shelf data exists")
    end

    shelf_response = {}

    shelf[:volumes].each do |x|
      volume_api_result = JSON.parse(get_volumes_result("/volumes/" + x[:volume_id]))
      if !volume_api_result.key?("error")
        # TODO: There should be a better way to do the above check,
        # such as adding an exception to shelves if the upserted volume is not found in google books.
        if !shelf_response.key?(x[:shelf])
          shelf_response[x[:shelf]] = []
          shelf_response[x[:shelf] + "_count"] = 0
        end
        shelf_response[x[:shelf]].append(volume_api_result)
        shelf_response[x[:shelf] + "_count"] += 1
      end
    end
    shelf_response
  end

  def get_volume_from_shelf(volume_id, current_shelf)
    volume = nil
    if !current_shelf[:volumes].nil?
      current_shelf[:volumes].each do |current_volume|
        if current_volume[:volume_id] == volume_id
          volume = current_volume
        end
      end
    end
    volume
  end

  def get_currently_reading_from_shelf(current_shelf)
    volume = nil
    if !current_shelf[:volumes].nil?
      current_shelf[:volumes].each do |current_volume|
        if current_volume[:shelf] == "currently_reading"
          volume = current_volume
        end
      end
    end
    volume
  end

  def calculate_reading_time(volume)
    total_time = nil
    start_time = volume[:start_time]
    end_time = volume[:end_time]
    if start_time && end_time && start_time <= end_time
      total_time = end_time - start_time
    end
    total_time
  end

  def verify_shelf_operation_data(operation, volume_id, to_shelf)
    if operation.nil? || operation.empty?
      raise ShelfOpError.new(400, "Missing `op` in request")
    elsif volume_id.nil? || volume_id.empty?
      raise ShelfOpError.new(400, "Missing `volume_id` in request")
    elsif operation != "delete" && (to_shelf.nil? || to_shelf.empty?)
      raise ShelfOpError.new(400, "Missing `to_shelf` in request")
    end
  end

  ## Begin Shelf Primary Logic
  def modify_exclusive_shelves(user_id, operation, volume_id, to_shelf, set_completed = false)
    verify_shelf_operation_data(operation, volume_id, to_shelf)
    current_shelf = get_exclusive_shelf(user_id)
    if current_shelf.nil?
      current_shelf = initialize_shelf(user_id)
    end

    case operation
    when "upsert"
      handle_upsert_to_shelf(user_id, volume_id, to_shelf, set_completed, current_shelf)
    when "delete"
      handle_remove_from_shelf(user_id, volume_id)
    else
      raise ShelfOpError.new(400, "Invalid operation provided")
    end
  end

  def handle_remove_from_shelf(user_id, volume_id)
    result = remove_volume_from_exclusive_shelf(user_id, volume_id)
    "Delete completed"
  end

  def handle_upsert_to_shelf(user_id, volume_id, to_shelf, set_completed, current_shelf)
    # nil if the volume to move doesn't exists in the user's shelf
    current_volume_data = get_volume_from_shelf(volume_id, current_shelf)
    if !current_volume_data.nil? && (current_volume_data[:shelf] == to_shelf)
      # no op when trying to move a volume to the same shelf
      raise ShelfOpError.new(304, "No modifications needed")
    end

    new_volume_data = {
      volume_id: volume_id,
      shelf: to_shelf,
    }
    case to_shelf
    when "currently_reading"
      currently_reading = get_currently_reading_from_shelf(current_shelf)
      if !currently_reading.nil?
        bump_currently_reading(user_id, currently_reading[:volume_id], set_completed)
      end
      new_volume_data[:start_time] = Time.now
    when "previously_read"
      if !current_volume_data.nil? && current_volume_data[:shelf] == "currently_reading"
        new_volume_data[:start_time] = current_volume_data[:start_time]
        new_volume_data[:end_time] = Time.now
      end
    when "want_to_read"
      # Nothing special to be done here,
      # but we are purposely losing the time fields of any volumes moved here
    else
      raise ShelfOpError.new(400, "Invalid shelf provided")
      # This will eventually be replaced by creating a new shelf
    end
    upsert_to_shelf(user_id, new_volume_data, current_volume_data)
  end

  def bump_currently_reading(user_id, volume_id, set_completed)
    # Recursion
    transfer_shelf = set_completed ? "previously_read" : "want_to_read"
    modify_exclusive_shelves(user_id, "upsert", volume_id, transfer_shelf, false)
  end

  def upsert_to_shelf(user_id, new_volume_data, current_volume_data)
    if !current_volume_data.nil?
      result = update_volume_in_exclusive_shelf(user_id, new_volume_data)
    else
      result = add_volume_to_exclusive_shelf(user_id, new_volume_data)
    end
    "Upsert completed"
  end
end
