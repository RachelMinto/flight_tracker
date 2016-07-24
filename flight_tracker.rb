require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "redcarpet"
require "yaml"
require "bcrypt"

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

def require_signed_in_user
  unless session[:username]
    session[:message] = "Must be signed in to do that."
    redirect "/"
  end
end

def load_credentials
  credentials = if ENV["RACK-ENV"] == "test"
    File.expand_path("../data/users.yml", __FILE__)
  else
    File.expand_path("../users.yml", __FILE__)
  end
  YAML.load_file(credentials)
end

def correct_credentials?(username, password)
  credentials = load_credentials

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(credentials[username])
    bcrypt_password == password
  else
    false
  end
end

def flights_path
  if ENV["RACK-ENV"] == "test"
    File.expand_path("../test/flights.yml", __FILE__)
  else
    File.expand_path("../flights.yml", __FILE__)
  end
end

def load_flights
  YAML.load_file(flights_path)
end

def add_flight(nickname, flight_info)
  flights = load_flights
  flights[nickname] = flight_info
  File.open(flights_path, 'w') { |file| file.write flights.to_yaml }
  session[:message] = "Flight has been added successfully"
end

def delete_flight(flight)
  flight_doc = load_flights
  if flight_doc[flight]
    flight_doc.delete(flight)
    File.open("flights.yml", 'w') { |f| f.write flight_doc.to_yaml}
    session[:message] = "#{flight} was deleted successfully."
  else
    session[:message] = "#{flight} was not found."
  end
end

get "/" do
  @flights = load_flights if session[:username]
  erb :home
end

post "/signin" do
  username = params[:username]

  if correct_credentials?(username, params[:password])
    session[:username] = username
    session[:message] = "Successfully signed in as #{username}."
    redirect "/"
  else
    status 422
    session[:message] = "Invalid credentials."
    redirect "/"
  end
end

post "/signout" do
  session.delete(:username)
  session[:message] = "User has been successfully signed out."
  redirect "/"
end

get "/new" do
  require_signed_in_user
  erb :newflight
end

post "/addflight" do
  require_signed_in_user

  nickname = params[:nickname]
  airline = params[:airline]
  flightnum = params[:flightnum]
  date = params[:date]
  time = params[:time]
  departure = params[:departure]
  arrival = params[:arrival]

  new_flight = {:airline => airline, :flightnum => flightnum, :date => date, 
    :time => time, :departure => departure, :arrival => arrival}
  add_flight(nickname, new_flight)

  redirect "/"
end

post "/delete/:flightname" do
  require_signed_in_user
  flight = params[:flightname]
  delete_flight(flight)

  redirect "/"
end

# --
 # Make sure all user input is cleaned and secure.