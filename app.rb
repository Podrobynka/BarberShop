require 'rubygems'
require 'sinatra'
require 'pony'
require 'sqlite3'

# require 'sinatra/reloader'
def getting_db
  SQLite3::Database.new 'barbershop.db'
end

configure do
  db = getting_db
  db.execute %(
    CREATE TABLE IF NOT EXISTS
    "users"
    (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "username" TEXT,
      "phone" TEXT,
      "datestamp" TEXT,
      "barber" TEXT,
      "color" TEXT
    )
  )
  # db = getting_db
  db.execute %(
    CREATE TABLE IF NOT EXISTS
    "barbers"
    (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "barber" TEXT
    )
  )
end

get '/' do
  erb :main
end

post '/' do
  erb :main
  @login = params[:login]
  @password = params[:password]

  if @login == 'admin' && @password == 'secret'
    @users = File.readlines('public/userlist.txt')
    erb :users
  else
    @message = 'Access denied!'
  end
end

get '/about' do
  @error = 'something wrong!!!'
  erb :about
end

get '/admin' do
  db = getting_db
  db.results_as_hash = true
  @barbersdb = db.execute 'select * from barbers'
  erb :admin
end

post '/admin' do
  @barber = params[:barber]

  db = getting_db
  db.results_as_hash = true
  @barbersdb = db.execute 'select * from barbers'

  @barbersdb.each do |row|
    if row['barber'] == @barber
      @error = 'The barber already exists'
      return erb :admin
    end
  end

  db.execute 'insert into barbers (barber) values (?)', @barber
  erb :admin
end

get '/visit' do
  db = getting_db
  db.results_as_hash = true
  @barbersdb = db.execute 'select * from barbers order by id desc'
  erb :visit
end

post '/visit' do
  @username = params[:username]
  @phone = params[:phone]
  @datetime = params[:datetime]
  barber = params[:barber]
  color = params[:colorpicker]

  db = getting_db
  db.results_as_hash = true
  @barbersdb = db.execute 'select * from barbers order by id desc'
  hh = {
    username: 'Enter your name',
    phone: 'Enter your phone',
    datetime: 'Enter correct date and time'
  }

  hh.each do |key, _value|
    if params[key] == ''
      @error = hh[key]
      return erb :visit
    end
  end
  # db = getting_db
  db.execute %(
    insert into
    users
    (
      username,
      phone,
      datestamp,
      barber,
      color
    )
    values
    (?, ?, ?, ?, ?)
  ), @username, @phone, @datetime, barber, color

  @title = 'Thank you!'
  @message = "Dear #{@username}, we'll waiting for you at #{@datetime}."
  erb :visit
end

get '/showusers' do
  db = getting_db
  db.results_as_hash = true
  @usersdb = db.execute 'select * from users order by id desc'
  erb :showusers
end

get '/contacts' do
  erb :contacts
end

post '/contacts' do
  @name = params[:name]
  mail = params[:mail]
  body = params[:body]
  hh = {
    name: 'Enter your name',
    mail: 'Enter your email',
    body: 'Enter your message'
  }

  hh.each do |key, _value|
    if params[key] == ''
      @error = hh[key]
      return erb :contacts
    end
  end

  Pony.options = {
    subject: "Received from: #{@name} (#{mail})",
    body: body,
    via: :smtp,
    via_options: {
      address: 'smtp.gmail.com',
      port: '587',
      enable_starttls_auto: true,
      user_name: 'yfgurda@gmail.com',
      password: 'zxcvbn123',
      authentication: :plain,
      domain: 'localhost'
    }
  }

  Pony.mail(to: 'yfgurda@gmail.com')
  erb :success
end
