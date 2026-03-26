require "sqlite3"
require_relative "../config"
require "fileutils"

class Seeder
  DB_PATH = "db/pizza.sqlite"

  def self.seed!
    puts "Using db file: #{DB_PATH}"
    puts "🧹 Resetting db file..."
    drop_tables
    reset_db_file

    puts "🧱 Creating tables..."
    create_tables

    puts "✅ Done seeding the database!"
    populate_pizzas
  end

  def self.reset_db_file
    @db&.close rescue nil
    @db = nil
    FileUtils.rm_f(DB_PATH)
    FileUtils.mkdir_p(File.dirname(DB_PATH))
  end

  def self.drop_tables
    db.execute('DROP TABLE IF EXISTS users')
    db.execute('DROP TABLE IF EXISTS pizzas')
    db.execute('DROP TABLE IF EXISTS pizza_cart')
    db.execute('DROP TABLE IF EXISTS orders')
    db.execute('DROP TABLE IF EXISTS order_items')
  end

  def self.create_tables
    db.execute <<~SQL
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        password TEXT NOT NULL
      )
    SQL

    db.execute <<~SQL
      CREATE TABLE pizzas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        toppings TEXT,
        picture TEXT
      )
    SQL

    db.execute <<~SQL
      CREATE TABLE pizza_cart(
        userid TEXT NOT NULL,
        pizzaid INTEGER NOT NULL,
        amount INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY(userid, pizzaid)
      )
    SQL

    db.execute <<~SQL
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userid TEXT NOT NULL,
        order_date TEXT NOT NULL,
        FOREIGN KEY (userid) REFERENCES users(id) ON DELETE CASCADE
      )
    SQL
    db.execute <<~SQL
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderid INTEGER NOT NULL,
        pizzaid INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        FOREIGN KEY (orderid) REFERENCES orders(id) ON DELETE CASCADE,
        FOREIGN KEY (pizzaid) REFERENCES pizzas(id) ON DELETE CASCADE
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
        "INSERT INTO pizzas (name, price, toppings, picture) VALUES (?,?,?,?)",
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