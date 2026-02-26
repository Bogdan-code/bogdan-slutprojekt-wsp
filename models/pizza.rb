require_relative '../db'

class Pizza

  def self.all
    DB.execute("SELECT * FROM pizza")
  end

  def self.find(id)
    DB.execute("SELECT * FROM pizza WHERE id=?", [id]).first
  end

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

    def self.remove_from_cart(userid, pizzaid)
      DB.execute("DELETE FROM pizza_cart WHERE userid=? AND pizzaid=?", [userid, pizzaid])
    end

    def self.clear_cart(userid)
      DB.execute("DELETE FROM pizza_cart WHERE userid=?", [userid])
    end
  
  end


end