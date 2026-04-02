require_relative '../db'
require 'bcrypt'

# Hanterar användare, både inloggning och skapande av nya användare. 
#
# @author Bogdan Olsson
class User

  # Hämtar en användare baserat på id
  # @param id [String] Användarens id
  # @return [Hash, nil] En hash som representerar användaren, eller nil om ingen användare hittades
  def self.find(id)
    DB.execute(
      "SELECT * FROM users WHERE id=?",
      id
    ).first
  end

  # Hämtar en användare baserat på användarnamn
  # @param username [String] Användarens namn
  # @return [Hash, nil] En hash som representerar användaren, eller nil om ingen användare hittades
  def self.find_by_username(username)
    DB.execute(
      "SELECT * FROM users WHERE name=?",
      username
    ).first
  end

  # Skapar en ny användare
  # @param username [String] Användarens namn
  # @param password [String] Användarens lösenord
  # @return [void]
  def self.create(username, password)
    encrypted = BCrypt::Password.create(password)

    DB.execute(
      "INSERT INTO users (id, name, password)
       VALUES (?,?,?)",
      ["#{username}_userid", username, encrypted]
    )
  end
  
  # Tar bort en användare baserat på id
  # @param id [String] Användarens id
  # @return [void]
  def self.delete(id)
    DB.execute(
      "DELETE FROM users WHERE id=?",
      id
    )
  end
end
