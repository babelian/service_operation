require 'pry'
require 'service_operation'
require 'service_operation/spec/spec_helper'

RSpec.configure do |config|
  if ENV['_'].to_s.match?(/guard/)
    config.filter_run focus: true
    config.run_all_when_everything_filtered = true
  end
end