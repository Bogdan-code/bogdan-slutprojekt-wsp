require 'debug'
require "awesome_print"
require 'sinatra'
require 'securerandom'
require 'fiddle'

require_relative 'db'
require_relative 'models/pizza'
require_relative 'models/users'
require_relative 'models/cart'
require_relative 'models/checkout'


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
    helpers do
      def login_locked?
        session[:login_locked_until] && Time.now.to_i < session[:login_locked_until]
      end
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
      if login_locked?
        @error = "Vänta #{session[:login_locked_until] - Time.now.to_i} sekunder innan du försöker igen."
        return erb(:"user/login")
      end
      user = User.find_by_username(params["username"])

      if params[:username] == "admin" && BCrypt::Password.new(user["password"]) == params["password"]
        session[:admin] = true
      end
      if user && BCrypt::Password.new(user["password"]) == params["password"]
        session[:user_id] = user["id"]
        session[:login_attempts] = 0
        session[:login_locked_until] = nil
        redirect "/"
      else
        p session[:login_attempts]
        session[:login_attempts] ||= 0
        session[:login_attempts] += 1
        if session[:login_attempts] >= 3
          session[:login_locked_until] = Time.now.to_i + 3
          session[:login_attempts] = 0
          @error = "För många försök. Vänta 5 sekunder."
        else
          @error = "Felaktigt användarnamn eller lösenord. Försök igen." 
        end
        erb(:"user/login")
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

    get "/pizzas/create" do
      erb(:"/pizzas/create")
    end

    post "/pizzas/create" do
      Pizza.create(params["name"], params["price"], params["toppings"], params["picture"])
      redirect "/main"
    end

    get "/pizzas/:id/edit" do |id|
      @pizza = Pizza.find(id)
      erb(:"/pizzas/edit")
    end

    post "/pizzas/:id/edit" do |id|
      Pizza.update(id, params["name"], params["price"], params["toppings"], params["picture"])
      redirect "/pizzas/#{id}"
    end

    get "/pizzas/:id" do |id|
      @pizza = Pizza.find(id)
      erb(:"/pizzas/show")
    end

    get "/checkout/cart" do
      redirect "/user/login" unless @logged_in
      @pizzas = {}
      Pizza.all.each do |pizza|
        @pizzas[pizza["id"]] = pizza
      end
      @cart_items = Cart.all(session[:user_id])
      erb(:"/checkout/cart")
    end

    post "/cart/add" do
      redirect "/user/login" unless @logged_in
      pizza_id = params["pizza_id"]
      amount = params["amount"].to_i
      amount = 1 if amount < 1
      Cart.add_to_cart(session[:user_id], params["pizza_id"], params["amount"].to_i)
      redirect "/checkout/cart"
    end

    post "/cart/remove" do
      redirect "/user/login" unless @logged_in
      p params["pizza_id"]
      Cart.remove_from_cart(session[:user_id], params["pizza_id"])
      redirect "/checkout/cart"
    end

    get "/checkout/orders" do
      redirect "/user/login" unless @logged_in
      @all_orders = ::Checkout.all()
      @orders = ::Checkout.orders(session[:user_id])
      erb(:"/checkout/orders")
    end

    get "/checkout" do
      redirect "/user/login" unless @logged_in
      ::Checkout.checkout(session[:user_id])
      redirect "/checkout/orders"
    end


end
