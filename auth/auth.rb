# Auth will take care of authentication

require "./core/repositories.rb"
require "bcrypt" # https://github.com/codahale/bcrypt-ruby
require "date"
# require 'sinatra'

def verify_input(username, pw)
  error = nil
  if username.nil? || username.empty?
    halt 400, "Missing `username` in request"
  elsif pw.nil? || pw.empty?
    halt 400, "Missing `password` in request"
  end
  error
end

def verify_registration_input(username, pw, email)
  error = verify_input(username, pw)
  halt 400, "Missing `email` in request" if email.nil? || email.empty?
  error
end

def register_user(username, pw, email)
  error = verify_registration_input(username, pw, email)
  return error if error

  user = get_user_from_username(username)
  halt 409, "User already exists" if user

  hashed_password = BCrypt::Password.create(pw)
  userdata = {
    username: username,
    hashed_password: hashed_password,
    email: email,
    source: "bookclub",
  }
  user_id = create_user(userdata)
  generate_token(user_id).to_json
end

def verify_user(username, pw)
  error = verify_input(username, pw)
  return error if error

  user = get_user_from_username(username)
  if !user
    halt 404, "User does not exist"
  else
    hashed_password = user["hashed_password"]

    if (BCrypt::Password.new(hashed_password) != pw)
      halt 401, "Incorrect password"
    end
    token = generate_token(user["id"]).to_json
    token
  end
end

def deactivate_token(access_token)
  if access_token.nil? || access_token.empty?
    halt 400, "Missing `access_token` in Logout Request"
  end
  modified = delete_token(access_token)
  if modified == 0
    halt 404, "Could not delete token: No such token found in database"
  end
  "Successfully deleted token"
end

def verify_token(user_id, access_token)
  token = get_token(user_id, access_token)
  halt 401, "Invalid token/user_id combination" if !token

  halt 401, "Token expired" if Time.now >= token["expiry"]
  nil
end
