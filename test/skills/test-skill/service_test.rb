# frozen_string_literal: true

require 'test_helper'
require_relative '../../../skills/test-skill/service'

module SkillBench
  module Skills
    class TestSkillTest < Minitest::Test
      def test_call_returns_success_response
        result = TestSkill.call({})

        assert result[:success]
        assert_equal 'Test skill executed successfully', result[:response][:message]
      end

      def test_call_returns_standard_response_format
        result = TestSkill.call(nil)

        assert result.key?(:success)
        assert result.key?(:response)
        assert_instance_of Hash, result[:response]
      end
    end
  end
end
