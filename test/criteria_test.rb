# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class CriteriaTest < Minitest::Test
    def test_loads_valid_criteria_json
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'criteria.json'), valid_criteria_json)

        result = Criteria.call(path: File.join(dir, 'criteria.json'))

        assert result[:success]
        criteria = result[:response][:criteria]

        assert_equal 5, criteria.dimensions.size
        assert_equal 'Evaluate whether the skill helps build a proper API REST collection', criteria.context
        assert_equal 70, criteria.pass_threshold
        assert_equal 10, criteria.minimum_delta
      end
    end

    def test_merges_eval_descriptions_with_defaults
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'criteria.json'), criteria_with_override_json)

        result = Criteria.call(path: File.join(dir, 'criteria.json'))

        assert result[:success]
        criteria = result[:response][:criteria]
        dim = criteria.dimensions.find { |d| d.name == 'skill_adherence' }

        assert_equal 'Did the agent follow the .call pattern?', dim.description
      end
    end

    def test_returns_error_when_dimensions_do_not_sum_to_one_hundred
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'criteria.json'), invalid_sum_json)

        result = Criteria.call(path: File.join(dir, 'criteria.json'))

        refute result[:success]
        assert_match(/must sum to 100/, result[:response][:error][:message])
      end
    end

    def test_returns_error_when_dimensions_have_nil_max_score
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'criteria.json'), criteria_with_nil_max_score_json)

        result = Criteria.call(path: File.join(dir, 'criteria.json'))

        refute result[:success]
        assert_match(/correctness/, result[:response][:error][:message])
        assert_match(/missing or invalid max_score/, result[:response][:error][:message])
      end
    end

    def test_returns_error_when_file_missing
      Dir.mktmpdir do |dir|
        missing_path = File.join(dir, 'criteria.json')
        result = Criteria.call(path: missing_path)

        refute result[:success]
        assert_match(/does not exist/, result[:response][:error][:message])
      end
    end

    def test_returns_error_on_invalid_json
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'criteria.json'), 'not json')

        result = Criteria.call(path: File.join(dir, 'criteria.json'))

        refute result[:success]
        assert_match(/Invalid JSON/, result[:response][:error][:message])
      end
    end

    def test_accepts_custom_dimensions_beyond_core
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'criteria.json'), criteria_with_custom_dimension_json)

        result = Criteria.call(path: File.join(dir, 'criteria.json'))

        assert result[:success]
        criteria = result[:response][:criteria]

        assert_equal 6, criteria.dimensions.size
        assert_includes criteria.dimensions.map(&:name), 'performance'
        assert_equal 'Is the solution performant and scalable?', criteria.dimensions.find { |d| d.name == 'performance' }&.description
      end
    end

    def test_returns_error_when_core_dimension_missing
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'criteria.json'), criteria_missing_core_json)

        result = Criteria.call(path: File.join(dir, 'criteria.json'))

        refute result[:success]
        assert_match(/missing required core dimensions/, result[:response][:error][:message])
        assert_match(/documentation/, result[:response][:error][:message])
      end
    end

    def test_returns_error_when_custom_and_core_sum_exceeds_one_hundred
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'criteria.json'), criteria_custom_over_sum_json)

        result = Criteria.call(path: File.join(dir, 'criteria.json'))

        refute result[:success]
        assert_match(/must sum to 100/, result[:response][:error][:message])
      end
    end

    def test_accepts_zero_threshold_and_delta
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'criteria.json'), zero_threshold_json)

        result = Criteria.call(path: File.join(dir, 'criteria.json'))

        assert result[:success]
        criteria = result[:response][:criteria]

        assert_equal 0, criteria.pass_threshold
        assert_equal 0, criteria.minimum_delta
      end
    end

    private

    def zero_threshold_json
      {
        context: 'Evaluate',
        dimensions: [
          { name: 'correctness', max_score: 30 },
          { name: 'skill_adherence', max_score: 25 },
          { name: 'code_quality', max_score: 20 },
          { name: 'test_coverage', max_score: 15 },
          { name: 'documentation', max_score: 10 }
        ],
        pass_threshold: 0,
        minimum_delta: 0
      }.to_json
    end

    def valid_criteria_json
      {
        context: 'Evaluate whether the skill helps build a proper API REST collection',
        dimensions: [
          { name: 'correctness', max_score: 30 },
          { name: 'skill_adherence', max_score: 25 },
          { name: 'code_quality', max_score: 20 },
          { name: 'test_coverage', max_score: 15 },
          { name: 'documentation', max_score: 10 }
        ],
        pass_threshold: 70,
        minimum_delta: 10
      }.to_json
    end

    def criteria_with_override_json
      {
        context: 'Evaluate API',
        dimensions: [
          { name: 'correctness', max_score: 30 },
          { name: 'skill_adherence', max_score: 25, description: 'Did the agent follow the .call pattern?' },
          { name: 'code_quality', max_score: 20 },
          { name: 'test_coverage', max_score: 15 },
          { name: 'documentation', max_score: 10 }
        ],
        pass_threshold: 70,
        minimum_delta: 10
      }.to_json
    end

    def invalid_sum_json
      {
        context: 'Evaluate API',
        dimensions: [
          { name: 'correctness', max_score: 20 },
          { name: 'skill_adherence', max_score: 20 },
          { name: 'code_quality', max_score: 20 },
          { name: 'test_coverage', max_score: 20 },
          { name: 'documentation', max_score: 15 }
        ],
        pass_threshold: 70,
        minimum_delta: 10
      }.to_json
    end

    def criteria_with_nil_max_score_json
      {
        context: 'Evaluate API',
        dimensions: [
          { name: 'correctness', max_score: nil },
          { name: 'skill_adherence', max_score: 25 },
          { name: 'code_quality', max_score: 20 },
          { name: 'test_coverage', max_score: 15 },
          { name: 'documentation', max_score: 10 }
        ],
        pass_threshold: 70,
        minimum_delta: 10
      }.to_json
    end

    def criteria_with_custom_dimension_json
      {
        context: 'Evaluate API',
        dimensions: [
          { name: 'correctness', max_score: 25 },
          { name: 'skill_adherence', max_score: 20 },
          { name: 'code_quality', max_score: 15 },
          { name: 'test_coverage', max_score: 15 },
          { name: 'documentation', max_score: 10 },
          { name: 'performance', max_score: 15, description: 'Is the solution performant and scalable?' }
        ],
        pass_threshold: 70,
        minimum_delta: 10
      }.to_json
    end

    def criteria_missing_core_json
      {
        context: 'Evaluate API',
        dimensions: [
          { name: 'correctness', max_score: 30 },
          { name: 'skill_adherence', max_score: 25 },
          { name: 'code_quality', max_score: 20 },
          { name: 'test_coverage', max_score: 25 }
        ],
        pass_threshold: 70,
        minimum_delta: 10
      }.to_json
    end

    def criteria_custom_over_sum_json
      {
        context: 'Evaluate API',
        dimensions: [
          { name: 'correctness', max_score: 30 },
          { name: 'skill_adherence', max_score: 25 },
          { name: 'code_quality', max_score: 20 },
          { name: 'test_coverage', max_score: 15 },
          { name: 'documentation', max_score: 10 },
          { name: 'performance', max_score: 15 }
        ],
        pass_threshold: 70,
        minimum_delta: 10
      }.to_json
    end
  end
end
