require_relative '../db'
# Hanterar pizzor, både visning av alla pizzor och hantering av enskilda pizzor.
#
# @author Bogdan Olsson
class Pizza

  # Hämtar alla pizzor
  # @return [Array<Hash>] En array av hash-objekt, där varje hash representerar en pizza
  def self.all
    DB.execute("SELECT * FROM pizzas")
  end

  # Hämtar en pizza baserat på id
  # @param id [Integer] Pizzans id
  # @return [Hash, nil] En hash som representerar pizzan, eller nil om ingen pizza hittades
  def self.find(id)
    DB.execute("SELECT * FROM pizzas WHERE id=?", [id]).first
  end

  # Skapar en ny pizza
  # @param name [String] Pizzans namn
  # @param price [Numeric] Pizzans pris
  # @param toppings [String] Pizzans toppings, som en kommaseparerad sträng
  # @param picture [String] URL till pizzans bild
  # @return [void]
  def self.create(name, price, toppings, picture)
    DB.execute(
      "INSERT INTO pizzas (name, price, toppings, picture) VALUES (?,?,?,?)",
      [name, price, toppings, picture]
    )
  end

  # Uppdaterar en pizza baserat på id
  # @param id [Integer] Pizzans id
  # @param name [String] Pizzans namn
  # @param price [Numeric] Pizzans pris
  # @param toppings [String] Pizzans toppings, som en kommaseparerad sträng
  # @param picture [String] URL till pizzans bild
  # @return [void]
  def self.update(id, name, price, toppings, picture)
    DB.execute(
      "UPDATE pizzas SET name=?, price=?, toppings=?, picture=? WHERE id=?",
      [name, price, toppings, picture, id]
    )
  end

  # Tar bort en pizza baserat på id
  # @param id [Integer] Pizzans id
  # @return [void]
  def self.delete(id)
    DB.execute("DELETE FROM pizzas WHERE id=?", [id])
   end

  


end