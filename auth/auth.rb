# Auth will take care of authentication

require "./core/errors.rb"
require "./core/repository.rb"
require "./core/resources.rb"

require "bcrypt"
require "date"

module Auth
  include BookclubErrors, Repository, Resources

  def verify_input(username, pw)
    if username.nil? || username.empty?
      raise AuthError.new(400, "Missing `username` in request")
    elsif pw.nil? || pw.empty?
      raise AuthError.new(400, "Missing `password` in request")
    end
  end

  def verify_registration_input(username, pw, email)
    verify_input(username, pw)
    if email.nil? || email.empty?
      raise AuthError.new(400, "Missing `email` in request")
    end
  end

  def register_user(username, pw, email)
    error = verify_registration_input(username, pw, email)
    return error if error

    user = get_user_from_username(username)
    if user
      raise AuthError.new(409, "User already exists")
    end

    hashed_password = BCrypt::Password.create(pw)
    userdata = {
      username: username,
      hashed_password: hashed_password,
      email: email,
      source: "bookclub",
    }
    user_id = create_user(userdata)
    if user_id.nil?
      raise AuthError.new(500, "Failed to create user")
    end
    response = generate_token(user_id)
    response[:username] = username
    response
  end

  def get_user(username)
    user = get_user_from_username(username)
    if user.nil?
      raise AuthError.new(404, "User does not exist")
    end
    user_response = {
      username: user["username"],
      user_id: user["user_id"],
    }
    user_response
  end

  def verify_user(username, pw)
    error = verify_input(username, pw)
    return error if error

    user = get_user_from_username(username)
    if user.nil?
      raise AuthError.new(404, "User does not exist")
    else
      hashed_password = user["hashed_password"]
      if (BCrypt::Password.new(hashed_password) != pw)
        raise AuthError.new(401, "Incorrect password")
      end
      response = generate_token(user["user_id"])
      response[:username] = username
      response
    end
  end

  def generate_token(user_id)
    access_token = generate_uuid()
    refresh_token = generate_uuid()
    expiry = Time.now + 60 * 60 * 24 * 14
    token = {
      user_id: user_id,
      access_token: access_token,
      expiry: expiry,
    }
    insert_token(token)
  end

  def deactivate_token(access_token)
    if access_token.nil? || access_token.empty?
      raise AuthError.new(400, "Missing `access_token` in Logout Request")
    elsif !delete_token(access_token)
      raise AuthError.new(404, "Could not delete token: No such token found in database")
    end
  end

  def verify_token(user_id, access_token)
    token = get_token(user_id, access_token)
    if token.nil?
      raise AuthError.new(401, "Invalid token/user_id combination")
    elsif Time.now >= token[:expiry]
      raise AuthError.new(401, "Token expired")
    end
  end
end
