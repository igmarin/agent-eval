# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
end

require 'minitest/autorun'
require 'mocha/minitest'
require 'webmock/minitest'

# Load the library via the canonical entry point
$LOAD_PATH << File.expand_path('../lib', __dir__)
require_relative '../lib/skill_bench'
