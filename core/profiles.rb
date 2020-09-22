# For any profile related functionality

module Profiles
  include BookclubErrors, Repository, Resources

  def generate_profile(user_id)
    profile = {
      user_id: user_id,
    }
    profile_id = insert_profile(profile)
    profile[:profile_id] = profile_id
    profile
  end

  def get_profile(user_id)
    profile = get_user_profile(user_id)
    if profile.nil?
      raise ProfileError.new(404, "User does not exist or no profile data exists")
    end

    profile_fields = get_profile_fields()
    profile_response = {
      user_id: user_id,
    }

    profile_fields.each do |field|
      profile_response[field] = profile[field]
    end
    profile_response.to_json
  end

  def update_profile_fields(user_id, profile_updates)
    if !profile_updates.empty?
      update_profile(user_id, profile_updates)
      { :success => true }
    else
      raise ProfileError.new(400, "Empty or invalid update request")
    end
  end
end
