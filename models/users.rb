require_relative '../db'
require 'bcrypt'

class User
  def self.find(id)
    DB.execute(
      "SELECT * FROM users WHERE id=?",
      id
    ).first
  end

  def self.find_by_username(username)
    DB.execute(
      "SELECT * FROM users WHERE username=?",
      username
    ).first
  end

  def self.create(username, password)
    encrypted = BCrypt::Password.create(password)

    DB.execute(
      "INSERT INTO users (id, username, password)
       VALUES (?,?,?)",
      ["#{username}_userid", username, encrypted]
    )
  end
end
