# frozen_string_literal: true

require "test_helper"

class LoforoLoadEnvTest < Minitest::Test
  def test_load_env_file_reads_variables
    key = "LOFORO_DOTENV_TEST_KEY"
    original = ENV.delete(key)

    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".env"), "#{key}=from-file\n")
      Loforo.load_env_file(File.join(dir, ".env"))
      assert_equal "from-file", ENV[key]
    end
  ensure
    ENV.delete(key)
    ENV[key] = original if original
  end

  def test_load_env_file_does_not_override_existing_env
    key = "LOFORO_DOTENV_TEST_KEY"
    original = ENV[key]
    ENV[key] = "from-shell"

    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".env"), "#{key}=from-file\n")
      Loforo.load_env_file(File.join(dir, ".env"))
      assert_equal "from-shell", ENV[key]
    end
  ensure
    ENV.delete(key)
    ENV[key] = original if original
  end
end
