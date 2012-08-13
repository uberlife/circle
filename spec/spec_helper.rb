require 'simplecov'
ENV["RAILS_ENV"] = "test"

require 'active_record'
require 'circle'
require 'rspec'
require 'shoulda/matchers'
require 'database_cleaner'
require 'fabrication'

Dir[File.join(File.dirname(__FILE__), 'spec/support/**/*.rb')].each {|f| require f}

ActiveRecord::Base.configurations = {'test' => {adapter: 'sqlite3', database: ':memory:'}}
ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])

load(File.join(File.dirname(__FILE__), 'schema.rb'))

RSpec.configure do |config|

 config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

end

class User < ActiveRecord::Base
  has_circle
end