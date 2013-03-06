# If you require the TeeLogger then
class TeeLogWriter
  def initialize
    logdir = FileUtils.mkdir_p(File.join(caproot,'log')).first
    @file=File.open(File.join(logdir,'deploy.log'), "w")
  end

  def puts(message)
    message = message.respond_to?(:force_encoding) ? message.force_encoding("UTF-8") : message
    STDOUT.puts message
    @file.puts "[#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}] #{message}"
  end

  ##
  # return the directory that holds the capfile
  def caproot
    @caproot ||= File.dirname(capfile)
  end

  private

  ##
  # Find the location of the capfile
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

Capistrano::Configuration.instance(true).load do
  #replace the running logger device with our own.
  self.logger.instance_variable_set(:@device,TeeLogWriter.new)
end
