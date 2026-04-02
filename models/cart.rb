require_relative '../db'

# Hanterar kundvagnen, både visning av innehållet i kundvagnen och hantering av att lägga till och ta bort pizzor från kundvagnen.
#
# @author Bogdan Olsson
class Cart

  # Hämtar alla pizzor i en användares kundvagn
  # @param userid [String] Användarens id
  # @return [Array<Hash>] En array av hash-objekt, där varje hash representerar en pizza i kundvagnen
  def self.all(userid)
    DB.execute("SELECT * FROM pizza_cart WHERE userid=?", [userid])
  end

  # Lägger till en pizza i en användares kundvagn, eller uppdaterar mängden om pizzan redan finns i kundvagnen
  # @param userid [String] Användarens id
  # @param pizzaid [Integer] Pizzans id
  # @param amount [Integer] Antal av pizzan som ska läggas till
  # @return [void]
  def self.add_to_cart(userid, pizzaid, amount)     
    existing = DB.execute(
      "SELECT amount FROM pizza_cart WHERE userid=? AND pizzaid=?",
      [userid, pizzaid]
    ).first

    if existing
      DB.execute(
        "UPDATE pizza_cart SET amount = amount + ? WHERE userid=? AND pizzaid=?",
        [amount, userid, pizzaid]
      )
    else
      DB.execute(
        "INSERT INTO pizza_cart (userid, pizzaid, amount) VALUES (?,?,?)",
        [userid, pizzaid, amount]
      )
    end
  end

  # Tar bort en pizza från en användares kundvagn
  # @param userid [String] Användarens id
  # @param pizzaid [Integer] Pizzans id
  # @return [void]
  def self.remove_from_cart(userid, pizzaid)
    DB.execute("DELETE FROM pizza_cart WHERE userid=? AND pizzaid=?", [userid, pizzaid])
  end

  # Tar bort alla pizzor från en användares kundvagn
  # @param userid [String] Användarens id
  # @return [void]
  def self.clear_cart(userid)
    DB.execute("DELETE FROM pizza_cart WHERE userid=?", [userid])
  end
end