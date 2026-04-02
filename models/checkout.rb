require_relative '../db'

# Hanterar beställningar, både visning av tidigare beställningar och hantering av nya beställningar.
#
# @author Bogdan Olsson
class Checkout

  # Hämtar alla beställningar för en användare
  # @param userid [String] Användarens id
  # @return [Array<Hash>] En array av hash-objekt, där varje hash representerar en beställning
  def self.orders(userid)
    DB.execute("SELECT * FROM orders WHERE userid = ?", userid)
  end

  # Hämtar alla beställningar
  # @return [Array<Hash>] En array av hash-objekt, där varje hash representerar en beställning
  # @note Denna metod används endast av admin-användare
  def self.all()
    DB.execute("SELECT * FROM orders")
  end


  # Genomför en beställning för en användare
  # @param userid [String] Användarens id
  # @return [void]
  def self.checkout(userid)
    cart = DB.execute("SELECT * FROM pizza_cart WHERE userid = ?", userid)

    DB.execute("INSERT INTO orders (userid, order_date) VALUES (?, datetime('now'))", userid)
    order_id = DB.last_insert_row_id

    cart.each do |item|
      DB.execute(
        "INSERT INTO order_items (orderid, pizzaid, amount) VALUES (?, ?, ?)",
        [order_id, item["pizzaid"], item["amount"]]
      )
    end

    DB.execute("DELETE FROM pizza_cart WHERE userid = ?", userid)
  end

end