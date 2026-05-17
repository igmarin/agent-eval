# frozen_string_literal: true

require_relative 'step'

module SkillBench
  module Agent
    class ReactAgent
      # Executes the ReAct loop iterations until completion or max iterations.
      class LoopRunner
        # Executes the loop.
        #
        # @param initial_prompt [String] The user task the agent must complete.
        # @param max_iterations [Integer] The maximum allowed steps before aborting.
        # @param config [Hash] The configuration for the Step execution.
        # @return [Hash] A result hash indicating success or failure.
        def self.call(initial_prompt, max_iterations, config)
          messages = [{ role: 'user', content: initial_prompt }]
          iterations_log = []
          step_count = 0

          while step_count < max_iterations
            step_count += 1

            step_result = Step.call(messages, config)
            iterations_log << attach_step_number(step_result[:iteration], step_count) if step_result[:iteration]

            unless step_result[:continue]
              final_result = step_result[:result] || { success: false, response: { error: { message: 'Step returned no result' } } }
              return merge_iterations(final_result, iterations_log)
            end

            messages = step_result[:messages]
          end

          merge_iterations(
            { success: false, response: { error: { message: Agent::ReactAgent::MAX_ITERATIONS_REACHED } } },
            iterations_log
          )
        rescue StandardError => e
          SkillBench::ErrorLogger.log_error(e, 'ReactAgent Error')
          merge_iterations(
            { success: false, response: { error: { message: e.message } } },
            iterations_log
          )
        end

        def self.attach_step_number(iteration, step_count)
          iteration.merge(step_number: step_count)
        end

        def self.merge_iterations(result, iterations_log)
          response = result[:response] || {}
          result.merge(response: response.merge(iterations: iterations_log))
        end
      end
    end
  end
end
