require 'sqlite3'

DB = SQLite3::Database.new("db/pizza.sqlite")
DB.results_as_hash = true