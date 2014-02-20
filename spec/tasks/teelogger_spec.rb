require File.expand_path(File.join('..','..','spec_helper'), __FILE__)


describe 'TeeLogWriter' do
  before do
    @configuration = Capistrano::Configuration.new
    @configuration.load do
      require 'cap_recipes/tasks/teelogger'

      class TeeLogWriterMockCLI
        attr_reader :options

        def initialize
          @options = {}
        end

        include Capistrano::CLI::Execute
      end

    end
  end

  # https://github.com/donnoman/cap-recipes/issues/4
  # TeeLogWriter class does not handle error/exception classes without standard message constructor
  describe 'Capistrano::CLI::Execute#handle_error' do
    it "should handle exception classes that have a non-standard method signature and exit" do
      require 'psych'
      require 'psych/exception'
      error = Psych::SyntaxError.new(__FILE__, __LINE__, 1, 0, "Bogus Problem", "Unknown Context")
      expect { TeeLogWriterMockCLI.new.handle_error(error) }.to raise_error(SystemExit)
    end
  end

end
