# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class ReactAgent
    class ToolExecutorTest < Minitest::Test
      def test_call_executes_tools_and_returns_messages
        tool_calls = [
          { 'id' => 'call_1', 'function' => { 'name' => 'read_file', 'arguments' => '{"path":"test.txt"}' } }
        ]

        Tools.expects(:execute).with('read_file', '{"path":"test.txt"}', Dir.pwd, nil).returns('file content')

        result = Agent::ReactAgent::ToolExecutor.call(tool_calls, Dir.pwd)

        assert_equal 1, result.length
        assert_equal 'tool', result.first[:role]
        assert_equal 'call_1', result.first[:tool_call_id]
        assert_equal 'file content', result.first[:content]
      end

      def test_call_returns_tool_error_message_when_tool_fails
        tool_calls = [
          { 'id' => 'call_1', 'function' => { 'name' => 'read_file', 'arguments' => '{"path":"/absolute"}' } }
        ]

        Tools.expects(:execute).raises(StandardError, 'Absolute paths are not allowed')

        result = Agent::ReactAgent::ToolExecutor.call(tool_calls, Dir.pwd)

        assert_kind_of Array, result, "Expected Array, got #{result.class}"
        assert_equal 1, result.length
        assert_equal 'tool', result.first[:role]
        assert_equal 'call_1', result.first[:tool_call_id]
        assert_includes result.first[:content], 'Absolute paths are not allowed'
      end

      def test_call_returns_tool_error_message_when_function_name_missing
        tool_calls = [
          { 'id' => 'call_1', 'function' => {} }
        ]

        result = Agent::ReactAgent::ToolExecutor.call(tool_calls, Dir.pwd)

        assert_kind_of Array, result, "Expected Array, got #{result.class}"
        assert_equal 1, result.length
        assert_equal 'tool', result.first[:role]
        assert_includes result.first[:content], 'Missing function name'
      end

      def test_call_returns_all_results_when_multiple_tools_one_fails
        tool_calls = [
          { 'id' => 'call_1', 'function' => { 'name' => 'read_file', 'arguments' => '{"path":"good.txt"}' } },
          { 'id' => 'call_2', 'function' => { 'name' => 'read_file', 'arguments' => '{"path":"/bad"}' } }
        ]

        Tools.expects(:execute).with('read_file', '{"path":"good.txt"}', Dir.pwd, nil).returns('good content')
        Tools.expects(:execute).with('read_file', '{"path":"/bad"}', Dir.pwd, nil).raises(StandardError, 'bad path')

        result = Agent::ReactAgent::ToolExecutor.call(tool_calls, Dir.pwd)

        assert_kind_of Array, result, "Expected Array, got #{result.class}"
        assert_equal 2, result.length

        assert_equal 'tool', result[0][:role]
        assert_equal 'good content', result[0][:content]

        assert_equal 'tool', result[1][:role]
        assert_includes result[1][:content], 'bad path'
      end
    end
  end
end
