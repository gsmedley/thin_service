require 'rspec'
require 'thin_service'

RSpec.configure do |config|
  config.color_enabled = true
  config.formatter     = 'documentation'
end