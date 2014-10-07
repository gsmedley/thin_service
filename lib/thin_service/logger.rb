# Note: Logger concepts are from a combination of:
#       AlogR: http://alogr.rubyforge.org
#       Merb:  http://merbivore.com
module ThinService

  class Log
    attr_accessor :logger
    attr_accessor :log_level

    Levels = { 
      :name   => { :emergency => 0, :alert => 1, :critical => 2, :error => 3, 
                   :warning => 4, :notice => 5, :info => 6, :debug => 7 },
      :id     => { 0 => :emergency, 1 => :alert, 2 => :critical, 3 => :error, 
                   4 => :warning, 5 => :notice, 6 => :info, 7 => :debug }
    }
    
    def initialize(log, log_level = :debug)
      @logger    = initialize_io(log)
      @log_level = Levels[:name][log_level] || 7

      if !RUBY_PLATFORM.match(/java|mswin|mingw/) && !(@log == STDOUT) && 
           @log.respond_to?(:write_nonblock)
        @aio = true
      end
      $ThinServiceLogger = self
    end
    
    # Writes a string to the logger. Writing of the string is skipped if the string's log level is
    # higher than the logger's log level. If the logger responds to write_nonblock and is not on 
    # the java or windows platforms then the logger will use non-blocking asynchronous writes.
    def log(*args)
      if args[0].is_a?(String)
        level, string = 6, args[0]
      else
        level = (args[0].is_a?(Fixnum) ? args[0] : Levels[:name][args[0]]) || 6
        string = args[1]
      end
      
      return if (level > log_level)

      if @aio
        @log.write_nonblock("#{Time.now} | #{Levels[:id][level]} | #{string}\n")
      else
        @log.write("#{Time.now} | #{Levels[:id][level]} | #{string}\n")
      end
    end
    
    private

    def initialize_io(log)
      if log.respond_to?(:write)
        @log = log
        @log.sync if log.respond_to?(:sync)
      elsif File.exist?(log)
        @log = open(log, (File::WRONLY | File::APPEND))
        @log.sync = true
      else
        FileUtils.mkdir_p(File.dirname(log)) unless File.exist?(File.dirname(log))
        @log = open(log, (File::WRONLY | File::APPEND | File::CREAT))
        @log.sync = true
        @log.write("#{Time.now} | info | Logfile created\n")
      end
    end

  end
  
  # Convenience wrapper for logging, allows us to use ThinService.log
  def self.log(*args)
    # If no logger has been defined yet at this point, log to STDOUT.
    $ThinServiceLogger ||= ThinService::Log.new(STDOUT, :debug)
    $ThinServiceLogger.log(*args)
  end
  
end
