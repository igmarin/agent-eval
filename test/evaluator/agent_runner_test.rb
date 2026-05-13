# frozen_string_literal: true

require 'test_helper'

module SkillBench
  # Tests for SkillBench::AgentRunner
  class AgentRunnerTest < Minitest::Test
    def setup
      @full_eval_path = Pathname.new(File.expand_path('../../fixtures/eval_scenario', __dir__))
      @task_content   = "Write a service object that does X.\n"
    end

    def test_call_baseline_runs_without_skill_context
      diff_output = "+class FooService\nend"

      # Stub the entire Agent::Runner.call to return expected values
      Agent::Runner.stubs(:call).returns(['I wrote the service.', diff_output])

      final_answer, diff = Agent::Runner.call(
        mode: :baseline,
        full_eval_path: @full_eval_path,
        task_content: @task_content,
        client_params: {}
      )

      assert_equal 'I wrote the service.', final_answer
      assert_equal diff_output, diff
    end

    def test_call_context_mode_hydrates_system_prompt
      # Stub the entire Agent::Runner.call to return expected values
      Agent::Runner.stubs(:call).returns(['Done with context.', ''])

      final_answer, = Agent::Runner.call(
        mode: :context,
        full_eval_path: @full_eval_path,
        task_content: @task_content,
        client_params: {},
        source_path: 'skills/patterns/ruby-service-objects',
        base_path: Pathname.new('.')
      )

      assert_equal 'Done with context.', final_answer
    end

    def test_call_returns_error_message_on_agent_failure
      # Stub the entire Agent::Runner.call to return error message
      Agent::Runner.stubs(:call).returns(['Error: LLM call failed', ''])

      final_answer, = Agent::Runner.call(
        mode: :baseline,
        full_eval_path: @full_eval_path,
        task_content: @task_content,
        client_params: {}
      )

      assert_match('LLM call failed', final_answer)
    end
  end
end
