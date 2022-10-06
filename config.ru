require 'sinatra'
require 'grape'
require "appsignal/integrations/sinatra"
require "appsignal/integrations/grape"
require "sequel"

Sequel::Database.register_extension(
  :appsignal_integration,
  Appsignal::Hooks::SequelLogConnectionExtension
)
Sequel::Database.extension(:appsignal_integration)

# connect to an in-memory database
DB = Sequel.sqlite

# create an items table
DB.create_table :items do
  primary_key :id
  String :name, unique: true, null: false
  Float :price, null: false
end


class Web < Sinatra::Base
  get '/' do
      # create a dataset from the items table
    items = DB[:items]

    # populate the table
    items.insert(name: 'a1', price: rand * 100)
    items.insert(name: 'a2', price: rand * 100)
    items.insert(name: 'a3', price: rand * 100)

    # print out the number of records
    puts "Item count: #{items.count}"

    # print out the average price
    puts "The average price is: #{items.avg(:price)}"

    'Hello world.'
  end
end

class API < Grape::API
  insert_before Grape::Middleware::Error, Appsignal::Grape::Middleware

  prefix "api"
  format :json

  get :hello do

    items = DB[:items]

    # populate the table
    items.insert(name: 'b1', price: rand * 100)
    items.insert(name: 'b2', price: rand * 100)
    items.insert(name: 'b3', price: rand * 100)

    # print out the number of records
    puts "Item count: #{items.count}"

    # print out the average price
    puts "The average price is: #{items.avg(:price)}"

    { hello: 'world' }
  end
end



use Rack::Session::Cookie
run Rack::Cascade.new [Web, API]
