require 'debug'
require "awesome_print"
require 'sinatra'
require 'securerandom'
require 'fiddle'

require_relative 'db'
require_relative 'models/pizza'
require_relative 'models/users'
require_relative 'models/cart'

class App < Sinatra::Base

    setup_development_features(self)

    # Funktion för att prata med databasen
    # Exempel på användning: db.execute('SELECT * FROM fruits')
    def db
      return @db if @db

      @db = SQLite3::Database.new("db/pizza.sqlite")
      @db.results_as_hash = true

      return @db
    end
    
    configure do
      enable :sessions
      set :session_secret, SecureRandom.hex(64)
    end

    def real_user_id?
      return false unless session[:user_id]
      !!User.find(session[:user_id])
    end

    before do
      @logged_in = real_user_id?
      @isadmin = session[:admin]
    end
    # Routen /
    get '/' do
        session[:user_id] = session["session_id"] unless session[:user_id]

        redirect("/main")
    end

    before do   
        session[:id] ||= SecureRandom.uuid
    end

    get '/main' do
        @pizzas = Pizza.all()
        erb(:"/main/index")
    end
    get '/user/signup' do 
      erb(:"user/signup")
    end
    
    post '/user/signup' do
      return redirect("/user/signup") if User.find_by_username(params["username"])

      User.create(params["username"], params["password"])
      session[:user_id] =
        User.find_by_username(params["username"])["id"]

      redirect "/main"
    end
     

    get '/user/login' do 
      erb(:"user/login")
    end

    post '/user/login' do
      user = User.find_by_username(params["username"])
      redirect "/user/login" unless user
      ap user
      if params[:username] == "admin" && BCrypt::Password.new(user["password"]) == params["password"]
        session[:admin] = true
      end
      if BCrypt::Password.new(user["password"]) == params["password"]
        session[:user_id] = user["id"]
        redirect "/"
      else
        redirect "/user/login"
      end

    end

    get "/user/logout" do
      session.clear
      redirect('/')
    end

    get "/deleteuser" do
      User.delete(session[:user_id])
      session.clear
      redirect('/')
    end

    get "/main/create" do
      erb(:"/main/create")
    end

    post "/main/create" do
      Pizza.create(params["name"], params["price"], params["toppings"], params["picture"])
      redirect "/main"
    end

    get "/pizza/:id/edit" do |id|
      @pizza = Pizza.find(id)
      erb(:"/main/edit")
    end

    post "/pizza/:id/edit" do |id|
      Pizza.update(id, params["name"], params["price"], params["toppings"], params["picture"])
      redirect "/index/#{id}"
    end
    get "/index/:id" do |id|
      @pizza = Pizza.find(id)
      erb(:"/main/show")
    end

    get "/main/cart" do
      redirect "/user/login" unless @logged_in
      @pizzas = {}
      Pizza.all.each do |pizza|
        @pizzas[pizza["id"]] = pizza
      end
      @cart_items = Cart.all(session[:user_id])
      erb(:"/main/cart")
    end

    post "/cart/add" do
      redirect "/user/login" unless @logged_in
      pizza_id = params["pizza_id"]
      amount = params["amount"].to_i
      amount = 1 if amount < 1
      Cart.add_to_cart(session[:user_id], params["pizza_id"], params["amount"].to_i)
      redirect "/main/cart"
    end

    post "/cart/remove" do
      redirect "/user/login" unless @logged_in
      p params["pizza_id"]
      Cart.remove_from_cart(session[:user_id], params["pizza_id"])
      redirect "/main/cart"
    end


end
