require 'debug'
require "awesome_print"
require 'sinatra'
require 'securerandom'
require 'fiddle'

require_relative 'db'
require_relative 'models/pizza'
require_relative 'models/users'

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

      if BCrypt::Password.new(user["password"]) == params["password"]
        session[:user_id] = user["id"]
        redirect "/"
      else
        redirect "/user/login"
      end
    end

    get "/logout" do

      session.clear
      redirect('/')
  
    end

end
