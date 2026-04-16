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

# Huvudklassen för applikationen, som hanterar alla routes och sessioner.
#
# @author Bogdan Olsson
class App < Sinatra::Base

  setup_development_features(self)

  # Funktion för att prata med databasen.
  #
  # Exempel på användning:
  #   db.execute('SELECT * FROM fruits')
  #
  # @return [SQLite3::Database] databasanslutningen
  def db
    return @db if @db

    @db = SQLite3::Database.new("db/pizza.sqlite")
    @db.results_as_hash = true

    @db
  end

  # Konfiguration för sessioner.
  configure do
    enable :sessions
    set :session_secret, SecureRandom.hex(64)
  end

  # Hjälpfunktioner för att hantera inloggning och användarsessioner.
  helpers do
    # Kontrollerar om inloggning är låst på grund av för många misslyckade försök.
    #
    # @return [Boolean] true om inloggning är låst, annars false
    def login_locked?
      session[:login_locked_until] && Time.now.to_i < session[:login_locked_until]
    end
  end

  # Kontrollerar om det finns en giltig användare i sessionen.
  #
  # @return [Boolean] true om det finns en giltig användare, annars false
  def real_user_id?
    return false unless session[:user_id]
    !!User.find(session[:user_id])
  end

  # @!method prepare_request_state
  #   Route-filter: BEFORE
  #   Körs innan varje route och sätter variabler för inloggning, adminstatus och sessions-id.
  #   @return [void]
  before do
    @logged_in = real_user_id?
    @isadmin = session[:admin]
    session[:id] ||= SecureRandom.uuid
  end

  # @!method root_page
  #   Route: GET /
  #   Startsidan som omdirigerar till /main.
  #   @return [void]
  get '/' do
    session[:user_id] = session["session_id"] unless session[:user_id]
    redirect("/main")
  end

  # @!method main_page
  #   Route: GET /main
  #   Visar alla pizzor på huvudsidan.
  #   @return [String] renderad ERB-sida
  get '/main' do
    @pizzas = Pizza.all()
    erb(:"/main/index")
  end

  # @!method signup_form
  #   Route: GET /user/signup
  #   Visar sidan för att skapa en ny användare.
  #   @return [String] renderad ERB-sida
  get '/user/signup' do
    erb(:"user/signup")
  end

  # @!method create_user
  #   Route: POST /user/signup
  #   Skapar en ny användare och loggar in den.
  #   @return [void]
  post '/user/signup' do
    return redirect("/user/signup") if User.find_by_username(params["username"])

    User.create(params["username"], params["password"])
    session[:user_id] = User.find_by_username(params["username"])["id"]

    redirect "/main"
  end

  # @!method login_form
  #   Route: GET /user/login
  #   Visar inloggningssidan.
  #   @return [String] renderad ERB-sida
  get '/user/login' do
    erb(:"user/login")
  end

  # @!method login_user
  #   Route: POST /user/login
  #   Hanterar inloggning och låser tillfälligt efter för många misslyckade försök.
  #   @return [String, void] renderad ERB-sida eller redirect
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

  # @!method logout_user
  #   Route: GET /user/logout
  #   Loggar ut användaren genom att rensa sessionen.
  #   @return [void]
  get "/user/logout" do
    session.clear
    redirect('/')
  end

  # @!method delete_user
  #   Route: GET /deleteuser
  #   Tar bort den inloggade användaren och rensar sessionen.
  #   @return [void]
  get "/deleteuser" do
    redirect "/user/login" unless @logged_in && @isadmin

    User.delete(session[:user_id])
    session.clear
    redirect('/')
  end

  # @!method create_pizza_form
  #   Route: GET /pizzas/create
  #   Visar formuläret för att skapa en ny pizza.
  #   @return [String] renderad ERB-sida
  get "/pizzas/create" do
    redirect "/user/login" unless @logged_in && @isadmin

    erb(:"/pizzas/create")
  end

  # @!method create_pizza
  #   Route: POST /pizzas/create
  #   Skapar en ny pizza och omdirigerar till huvudsidan.
  #   @return [void]
  post "/pizzas/create" do
    redirect "/user/login" unless @logged_in && @isadmin
    Pizza.create(params["name"], params["price"], params["toppings"], params["picture"])
    redirect "/main"
  end

  # @!method edit_pizza_form
  #   Route: GET /pizzas/:id/edit
  #   Visar redigeringssidan för en pizza.
  #   @param id [String] pizzans id
  #   @return [String] renderad ERB-sida
  get "/pizzas/:id/edit" do |id|
    redirect "/user/login" unless @logged_in && @isadmin

    @pizza = Pizza.find(id)
    erb(:"/pizzas/edit")
  end

  # @!method update_pizza
  #   Route: POST /pizzas/:id/edit
  #   Uppdaterar en pizza baserat på id.
  #   @param id [String] pizzans id
  #   @return [void]
  post "/pizzas/:id/edit" do |id|
    redirect "/user/login" unless @logged_in && @isadmin

    Pizza.update(id, params["name"], params["price"], params["toppings"], params["picture"])
    redirect "/pizzas/#{id}"
  end

  # @!method show_pizza
  #   Route: GET /pizzas/:id
  #   Visar en specifik pizza.
  #   @param id [String] pizzans id
  #   @return [String] renderad ERB-sida
  get "/pizzas/:id" do |id|
    @pizza = Pizza.find(id)
    erb(:"/pizzas/show")
  end

  # @!method show_cart
  #   Route: GET /checkout/cart
  #   Visar användarens kundvagn.
  #   @return [String, void] renderad ERB-sida eller redirect
  get "/checkout/cart" do
    redirect "/user/login" unless @logged_in
    @pizzas = {}
    Pizza.all.each do |pizza|
      @pizzas[pizza["id"]] = pizza
    end
    @cart_items = Cart.all(session[:user_id])
    erb(:"/checkout/cart")
  end

  # @!method add_to_cart
  #   Route: POST /cart/add
  #   Lägger till en pizza i kundvagnen.
  #   @return [void]
  post "/cart/add" do
    redirect "/user/login" unless @logged_in
    pizza_id = params["pizza_id"]
    amount = params["amount"].to_i
    amount = 1 if amount < 1
    Cart.add_to_cart(session[:user_id], params["pizza_id"], params["amount"].to_i)
    redirect "/checkout/cart"
  end

  # @!method remove_from_cart
  #   Route: POST /cart/remove
  #   Tar bort en pizza från kundvagnen.
  #   @return [void]
  post "/cart/remove" do
    redirect "/user/login" unless @logged_in
    p params["pizza_id"]
    Cart.remove_from_cart(session[:user_id], params["pizza_id"])
    redirect "/checkout/cart"
  end

  # @!method show_orders
  #   Route: GET /checkout/orders
  #   Visar alla beställningar för den inloggade användaren.
  #   @return [String, void] renderad ERB-sida eller redirect
  get "/checkout/orders" do
    redirect "/user/login" unless @logged_in
    @all_orders = ::Checkout.all()
    @orders = ::Checkout.orders(session[:user_id])
    erb(:"/checkout/orders")
  end

  # @!method checkout_order
  #   Route: GET /checkout
  #   Genomför en beställning och omdirigerar till orders-sidan.
  #   @return [void]
  get "/checkout" do
    redirect "/user/login" unless @logged_in
    ::Checkout.checkout(session[:user_id])
    redirect "/checkout/orders"
  end
end