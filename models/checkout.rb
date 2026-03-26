require_relative '../db'

class Checkout

  def self.orders(userid)
    DB.execute("SELECT * FROM orders WHERE userid = ?", userid)
  end

  def self.all()
    DB.execute("SELECT * FROM orders")
  end

  def self.checkout(userid)
    cart = DB.execute("SELECT * FROM pizza_cart WHERE userid = ?", userid)

    DB.execute("INSERT INTO orders (userid, order_date) VALUES (?, datetime('now'))", userid)
    order_id = DB.last_insert_row_id

    cart.each do |item|
      DB.execute(
        "INSERT INTO order_items (orderid, pizzaid, amount) VALUES (?, ?, ?)",
        order_id, item["pizzaid"], item["amount"]
      )
    end

    DB.execute("DELETE FROM pizza_cart WHERE userid = ?", userid)
  end

end