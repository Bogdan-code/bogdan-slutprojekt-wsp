require_relative '../db'

class Pizza

  def self.all
    DB.execute("SELECT * FROM pizzas")
  end

  def self.find(id)
    DB.execute("SELECT * FROM pizzas WHERE id=?", [id]).first
  end

  def self.create(name, price, toppings, picture)
    DB.execute(
      "INSERT INTO pizzas (name, price, toppings, picture) VALUES (?,?,?,?)",
      [name, price, toppings, picture]
    )
  end

  def self.update(id, name, price, toppings, picture)
    DB.execute(
      "UPDATE pizzas SET name=?, price=?, toppings=?, picture=? WHERE id=?",
      [name, price, toppings, picture, id]
    )
  end

  def self.delete(id)
    DB.execute("DELETE FROM pizzas WHERE id=?", [id])
   end

  


end