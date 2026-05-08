# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Cli
    class HelpPrinterTest < Minitest::Test
      def test_call_prints_usage
        assert_output(/Usage: skill-bench/) do
          HelpPrinter.call
        end
      end

      def test_call_returns_zero
        assert_equal 0, HelpPrinter.call
      end

      def test_call_lists_all_subcommands
        assert_output(/init.*run.*skill.*eval/m) do
          HelpPrinter.call
        end
      end
    end
  end
end
