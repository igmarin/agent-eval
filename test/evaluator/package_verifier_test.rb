# frozen_string_literal: true

require 'test_helper'
require 'rubygems/package'

module SkillBench
  class PackageVerifierTest < Minitest::Test
    def test_returns_success_envelope_when_package_contains_required_files
      package = stub(spec: stub(files: %w[README.md LICENSE lib/runner.rb]))
      Gem::Package.expects(:new).with('ruby-skill-bench-0.1.0.gem').returns(package)

      result = PackageVerifier.call(
        package_path: 'ruby-skill-bench-0.1.0.gem',
        required_files: %w[README.md LICENSE]
      )

      assert result[:success]
      assert_equal({ missing_files: [], packaged_files: %w[README.md LICENSE lib/runner.rb] }, result[:response])
    end

    def test_returns_failure_envelope_when_package_omits_required_files
      package = stub(spec: stub(files: ['README.md']))
      Gem::Package.expects(:new).with('ruby-skill-bench-0.1.0.gem').returns(package)

      result = PackageVerifier.call(
        package_path: 'ruby-skill-bench-0.1.0.gem',
        required_files: %w[README.md LICENSE]
      )

      refute result[:success]
      assert_equal({ error: { message: 'Missing packaged files: LICENSE' } }, result[:response])
    end
  end
end
