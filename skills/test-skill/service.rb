# frozen_string_literal: true

# Test skill service for eval generation characterization testing.
module TestSkill
  # Executes a simple test skill and returns a standardized response.
  #
  # @param _context [Hash, nil] Unused context data
  # @return [Hash] Service response with :success and :response keys
  # @raise [StandardError] on unexpected failure (subclass may rescue internally)
  # @example Basic usage
  #   result = TestSkill.call({})
  #   result[:success] # => true
  def self.call(_context)
    { success: true, response: { message: 'Test skill executed successfully' } }
  end
end
