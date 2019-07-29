require 'simplecov'

SimpleCov.start do
  add_filter '/test/'
end

require 'minitest/reporters'

Minitest::Reporters.use!

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'u-authorization'

require 'minitest/autorun'

module TestUtils
  def self.inspect_test_data?
    !ENV['INSPECT_TEST_DATA'].nil?
  end

  def self.inspect_test_data(content: nil)
    return unless inspect_test_data?

    yield
  end

  def self.strip_heredoc(heredoc)
    identation = heredoc.scan(/^\s*/).min_by{ |l| l.length }
    heredoc.gsub(/^#{identation}/, '')
  end

  def self.puts_heredoc(value)
    inspect_test_data do
      puts strip_heredoc(value)
    end
  end

  def self.puts_elapsed_time_in_ms(start_time)
    inspect_test_data do
      print 'Elapsed time in milliseconds: '
      puts (Time.now - start_time) * 1000.0
      puts ''
    end
  end
end
