# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "stringio"
require "loforo"

module LoforoTestHelpers
  def success_response
    status = Struct.new(:success?).new(true)
    Struct.new(:status).new(status)
  end

  def failure_response
    status = Struct.new(:success?).new(false)
    Struct.new(:status).new(status)
  end

  def fake_client(responses = {})
    posted = []
    default = success_response
    Class.new do
      define_method(:initialize) do
        @posted = posted
        @responses = responses
        @default = default
      end
      define_method(:post_file) do |path, **|
        @posted << path
        @responses[path] || @default
      end
      define_method(:posted) { @posted }
    end.new
  end
end

class Minitest::Test
  include LoforoTestHelpers
end
