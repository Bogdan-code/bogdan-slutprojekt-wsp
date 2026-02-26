require "sqlite3"
require_relative "../config"
require "fileutils"

class Seeder
  DB_PATH = "db/pizza.sqlite"

  def self.seed!
    puts "Using db file: #{DB_PATH}"
    puts "🧹 Resetting db file..."
    reset_db_file
    puts "🧱 Creating tables..."
    create_tables
    puts "✅ Done seeding the database!"
  end

  def self.reset_db_file
    @db&.close rescue nil
    @db = nil
    FileUtils.rm_f(DB_PATH)
    FileUtils.mkdir_p(File.dirname(DB_PATH))
  end

def self.create_tables
  db.execute <<~SQL
    CREATE TABLE IF NOT EXISTS users(
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      password TEXT NOT NULL
    )
  SQL

  db.execute <<~SQL
    CREATE TABLE IF NOT EXISTS pizza(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      price INTEGER NOT NULL,
      toppings TEXT,
      picture TEXT
    )
  SQL

  db.execute <<~SQL
    CREATE TABLE IF NOT EXISTS pizza_cart(
      userid TEXT NOT NULL,
      pizzaid INTEGER NOT NULL,
      amount INTEGER NOT NULL,
      PRIMARY KEY(userid, pizzaid)
    )
  SQL

  db.execute <<~SQL
    CREATE TABLE IF NOT EXISTS orders(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userid TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  SQL

  db.execute <<~SQL
    CREATE TABLE IF NOT EXISTS order_items(
      order_id INTEGER NOT NULL,
      pizzaid INTEGER NOT NULL,
      amount INTEGER NOT NULL,
      price_each INTEGER NOT NULL
    )
  SQL
end

  def self.populate_pizzas
    pizzas = [
      ["Margherita", 100, "Tomatsås, mozzarella", "margherita"],
      ["Vesuvio", 110, "Tomatsås, mozzarella, skinka", "vesuvio"],
      ["Capricciosa", 120, "Tomatsås, mozzarella, skinka, champinjoner", "capricciosa"],
      ["Hawaii", 115, "Tomatsås, mozzarella, skinka, ananas", "hawaii"],
      ["Kebabpizza", 125, "Tomatsås, mozzarella, kebab, lök, sås", "kebabpizza"]
    ]

    pizzas.each do |name, price, toppings, picture|
      db.execute(
        "INSERT INTO pizza (name, price, toppings, picture) VALUES (?,?,?,?)",
        [name, price, toppings, picture]
      )
    end
  end

  private

  def self.db
    return @db if @db
    @db = SQLite3::Database.new(DB_PATH)
    @db.results_as_hash = true
    @db
  end
end

Seeder.seed!