class TeeLogWriter
  class NormalExit < Capistrano::Error; end #use this to exit cap but still have a zero exit code
  ##
  # This passes through the value and adds it to the redaction list
  #
  #  set(:mysql_client_user) { TeeLogWriter.redact(database_user) }
  #
  # So your capistrano variable has the correct value, but it will be redacted from TeeLogWriters output.
  def self.redact(secure_message)
    self.redactions = (self.redactions + [secure_message].flatten).uniq
    secure_message
  end

  def self.redaction_replacement
    @redaction_replacement ||= '######'
  end

  def self.redaction_replacement=(replacement)
    @redaction_replacement = replacement
  end

  def self.redacted(message)
    with_ensured_encoding(message) do |message|
      redactions.inject(message) do |message,redaction|
        message.gsub(redaction,redaction_replacement)
      end
    end
  end

  def with_redactions(message)
    yield self.class.redacted(message)
  end

  def puts(message)
    with_redactions(message) do |message|
      STDOUT.puts message
      file.puts "[#{log_timestamp}] #{message}"
    end
  end

  def tty?
    true
  end

  private


  def self.redactions
    @redactions ||= []
  end

  def self.redactions=(value)
    @redactions = value
  end

  def self.with_ensured_encoding(message)
    yield message.respond_to?(:force_encoding) ? message.force_encoding("UTF-8") : message
  end

  def file
    @file ||= File.open(File.join(logdir,"deploy.#{file_timestamp}.log"), "w")
  end

  def log_timestamp
    Time.now.strftime("%Y-%m-%d %H:%M:%S%z")
  end

  def file_timestamp
    Time.now.strftime("%Y%m%d-%H%M%S%z")
  end

  def caproot
    @caproot ||= File.dirname(capfile)
  end

  def logdir
    FileUtils.mkdir_p(File.join(caproot,'log')).first
  end

  def capfile
    previous = nil
    current  = File.expand_path(Dir.pwd)

    until !File.directory?(current) || current == previous
      filename = File.join(current, 'Capfile')
      return filename if File.file?(filename)
      current, previous = File.expand_path("..", current), current
    end
  end

end

require 'capistrano/configuration'

module Capistrano
  class CLI
    module Execute
      def handle_error(error) #:nodoc:
        case error
        when TeeLogWriter::NormalExit #used to force capistrano to end but without an error code.
          exit 0
        when Net::SSH::AuthenticationFailed
          abort "authentication failed for `#{TeeLogWriter.redacted(error.message)}'"
        when Capistrano::Error
          abort(TeeLogWriter.redacted(error.message))
        else
          puts TeeLogWriter.redacted(error.message)
          puts error.backtrace
          exit 1
        end
      end
    end
  end
end


Capistrano::Configuration.instance(true).load do
  #replace the running logger device with our own.
  self.logger.instance_variable_set(:@device,TeeLogWriter.new)
end
