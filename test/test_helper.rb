# frozen_string_literal: true

require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/test/'
end

require 'minitest/autorun'
require 'mocha/minitest'
require 'webmock/minitest'

# Load all library files
$LOAD_PATH << File.expand_path('../lib', __dir__)
Dir.glob(File.join(__dir__, '../lib', '**', '*.rb')).each(&method(:require))
