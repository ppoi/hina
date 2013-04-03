APP_ENVIRONMENT = :test
require File.expand_path('../../hina', __FILE__)

def truncate_tables
  ['Thread','Post'].each do |table|
    Groonga[table].truncate
  end
end

RSpec.configure do |conf|
  conf.include Rack::Test::Methods

  conf.before(:suite) do
    truncate_tables
  end

  conf.after(:each) do
    truncate_tables
  end
end


def app
  Hina::Application
end
