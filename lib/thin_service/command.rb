# Mongrel Copyright (c) 2005 Zed A. Shaw 
# You can redistribute it and/or modify it under the same terms as Ruby.
#
# Additional work donated by contributors.  See http://mongrel.rubyforge.org/attributions.html 
# for more information.
#
# Adapted for thin_service by Garth Smedley

require 'optparse'
require 'fileutils'
require 'thin_service/service_manager'


module ThinService

  module Command

    BANNER = "Usage: thin_service <command> [options]"
    COMMANDS = ['start', 'install', "installdaemon", 'remove']

    class Base

      attr_reader :valid, :done_validating 

      # Called by the implemented command to set the options for that command.
      # Every option has a short and long version, a description, a variable to
      # set, and a default value.  No exceptions.
      def options(opts)
        opts.each do |short, long, help, variable, default|
          self.instance_variable_set(variable, default)
          @opt.on(short, long, help) do |arg|
            self.instance_variable_set(variable, arg)
          end
        end
      end

      # Called by the subclass to setup the command and parse the argv arguments.
      # The call is destructive on argv since it uses the OptionParser#parse! function.
      def initialize(options={})
        argv = options[:argv] || []
        @opt = OptionParser.new
        @opt.banner = ThinService::Command::BANNER
        @valid = true
        @done_validating = false

        configure

        @opt.on_tail("-h", "--help", "Show this message") do
          @done_validating = true
          puts(@opt)
        end

        # I need to add my own -v definition to prevent the -v from exiting by default as well.
        @opt.on_tail("--version", "Show version") do
          @done_validating = true
          puts("Version #{ThinService::VERSION}")
        end

        @opt.parse! argv
      end

      def configure
        options []
      end

      # Returns true/false depending on whether the command is configured properly.
      def validate
        return @valid
      end

      # Returns a help message.  Defaults to OptionParser#help which should be good.
      def help
        @opt.help
      end

      # Runs the command doing it's job.  You should implement this otherwise it will
      # throw a NotImplementedError as a reminder.
      def run
        raise NotImplementedError
      end


      # Validates the given expression is true and prints the message if not, exiting.
      def valid?(exp, message)
        if !@done_validating && !exp
          failure message
          @valid = false
          @done_validating = true
        end
      end

      # Validates that a file exists and if not displays the message
      def valid_exists?(file, message)
        valid?(file != nil && File.exist?(file), message)
      end


      # Validates that the file is a file and not a directory or something else.
      def valid_file?(file, message)
        valid?(file != nil && File.file?(file), message)
      end

      # Validates that the given directory exists
      def valid_dir?(file, message)
        valid?(file != nil && File.directory?(file), message)
      end

      # Just a simple method to display failure until something better is developed.
      def failure(message)
        STDERR.puts "!!! #{message}"
      end
    end

    module Commands

      module ServiceInstall
        def validate_thin_service_exe
          # check if thin_service.exe is in ruby bindir.
          gem_root = File.join(File.dirname(__FILE__), "..", "..")
          gem_executable = File.join(gem_root, "resource/thin_service_wrapper.exe")
          bindir_executable = File.join(RbConfig::CONFIG['bindir'], '/thin_service_wrapper.exe')

          unless File.exist?(bindir_executable)
            STDERR.puts "** Copying native thin_service executable..."
            FileUtils.cp gem_executable, bindir_executable rescue nil
          end

          unless FileUtils.compare_file(bindir_executable, gem_executable)
            STDERR.puts "** Updating native thin_service executable..."
            FileUtils.rm_f bindir_executable rescue nil
            FileUtils.cp gem_executable, bindir_executable rescue nil
          end

          bindir_executable
        end

        def add_service( svc_name, svc_display, argv)
          begin
            ServiceManager.create(
              svc_name,
              svc_display,
              argv.join(' ')
            )
            puts "#{svc_display} service created."
          rescue ServiceManager::CreateError => e
            puts "There was a problem installing the service:"
            puts e
          end
        end
      end

      class Install < ThinService::Command::Base
        include ServiceInstall

        def configure
            options [
              ['-N', '--name SVC_NAME', "Required name for the service to be registered/installed.", :@svc_name, nil],
              ['-D', '--display SVC_DISPLAY', "Adjust the display name of the service.", :@svc_display, nil],
              ["-e", "--environment ENV", "Rails environment to run as", :@environment, ENV['RAILS_ENV'] || "development"],
              ['-p', '--port PORT', "Which port to bind to", :@port, 3000],
              ['-a', '--address ADDR', "Address to bind to", :@address, "0.0.0.0"],             
              ['-t', '--timeout TIME', "Timeout for requests in seconds", :@timeout, 30],             
              ['-c', '--chdir PATH', "Change to dir before starting (will be expanded)", :@cwd, Dir.pwd],   
              ['-D', '--debug', "Enable debugging mode", :@debug, false],
              [''  , '--max-persistent-conns INT', "Maximum number of persistent connections", :@max_persistent_conns, 512],
              [''  , '--ssl', "Enables SSL", :@ssl, nil],
              [''  , '--ssl-key-file PATH', "Path to private key", :@ssl_key_file, nil],
              [''  , '--ssl-cert-file PATH', "Path to certificate", :@ssl_cert_file, nil],
              [''  , '--ssl-verify', "Enables SSL certificate verification", :@ssl_verify, nil],
              [''  , '--prefix PATH', "URL prefix for Rails app", :@prefix, nil],
            ]
        end

        # When we validate the options, we need to make sure the --root is actually RAILS_ROOT
        # of the rails application we wanted to serve, because later "as service" no error
        # show to trace this.
        def validate
          @cwd = File.expand_path(@cwd)
          valid_dir? @cwd, "Invalid path to change to: #@cwd"

          # change there to start, then we'll have to come back after daemonize
          Dir.chdir(@cwd)

          valid? @svc_name != nil, "A service name is mandatory."
          valid? !ServiceManager.exist?(@svc_name), "The service already exist, please remove it first."

          # default service display to service name
          @svc_display = @svc_name if !@svc_display

          # start with the premise of app really exist.
          app_exist = true
          %w{app config log}.each do |path|
            if !File.directory?(File.join(@cwd, path))
              app_exist = false
              break
            end
          end

          valid?(@prefix[0].chr == "/" && @prefix[-1].chr != "/", "Prefix must begin with / and not end in /") if @prefix

          valid? app_exist == true, "The path you specified isn't a valid Rails application."

          return @valid
        end

        def run
          # check if thin_service.exe is in ruby bindir.
          bindir_executable = validate_thin_service_exe

          # build the command line
          argv = []

          # start using the native executable
          argv << '"' + bindir_executable + '"'

          # force indication of service mode
          argv << "start"

          # now the options
          argv << "-e #{@environment}" if @environment
          argv << "-p #{@port}"
          argv << "-a #{@address}"  if @address
          argv << "-c \"#{@cwd}\"" if @cwd
          argv << "-t #{@timeout}" if @timeout
          argv << "-D" if @debug
          argv << "--max-persistent-conns #{@max_persistent_conns}" if @max_persistent_conns
          argv << "--ssl" if @ssl
          argv << "--ssl-key-file \"#{@ssl_key_file}\"" if @ssl_key_file
          argv << "--ssl-cert-file \"#{@ssl_cert_file}\"" if @ssl_cert_file
          argv << "--ssl-verify" if @ssl_verify
          argv << "--prefix \"#{@prefix}\"" if @prefix

          # concat remaining non-parsed ARGV
          argv.concat(ARGV)

          add_service( @svc_name, @svc_display, argv)

         end
      end


      class Installdaemon   < ThinService::Command::Base
        include ServiceInstall
        
        def configure
            options [
              ['-N', '--name SVC_NAME', "Required name for the service to be registered/installed.", :@svc_name, nil],
              ['-D', '--display SVC_DISPLAY', "Adjust the display name of the service.", :@svc_display, nil],
              ['-t', '--task TASK', "Which task to run", :@command, "rake tm:background:start"],
              ['-c', '--chdir PATH', "Change to dir before starting (will be expanded)", :@cwd, Dir.pwd],   
             ]
        end

        def validate
          @cwd = File.expand_path(@cwd)
          valid_dir? @cwd, "Invalid path to change to: #@cwd"

          # change there to start, then we'll have to come back after daemonize
          Dir.chdir(@cwd)

          valid? @svc_name != nil, "A service name is mandatory."
          valid? !ServiceManager.exist?(@svc_name), "The service already exist, please remove it first."

          # default service display to service name
          @svc_display = @svc_name if !@svc_display

          # start with the premise of app really exist.
          app_exist = true
          %w{app config log}.each do |path|
            if !File.directory?(File.join(@cwd, path))
              app_exist = false
              break
            end
          end

          valid? app_exist == true, "The path you specified isn't a valid Rails application."

          return @valid
        end

        def run
          bindir_executable = validate_thin_service_exe

          # build the command line
          argv = []

          # start using the native executable
          argv << '"' + bindir_executable + '"'

          # force indication of daemon mode
          argv << "daemon"

          # now the options
          argv << "-c \"#{@cwd}\"" 
          argv << "\"#{@command}\""  


          # concat remaining non-parsed ARGV
          argv.concat(ARGV)

          add_service( @svc_name, @svc_display, argv)
        end
      end


      module ServiceValidation
        def configure
          options [
            ['-N', '--name SVC_NAME', "Required name for the service to be registered/installed.", :@svc_name, nil],
          ]
        end

        def validate
          valid? @svc_name != nil, "A service name is mandatory."

          # Validate that the service exists
          valid? ServiceManager.exist?(@svc_name), "There is no service with that name, cannot proceed."
          if @valid then
            ServiceManager.open(@svc_name) do |svc|
              valid? svc.binary_path_name.include?("thin_service"), "The service specified isn't a Thin service."
            end
          end

          return @valid
        end
      end

      class Remove   < ThinService::Command::Base
        include ServiceValidation

        def run
          display_name = ServiceManager.getdisplayname(@svc_name)

          begin
            puts "Stopping #{display_name} if running..."
            ServiceManager.stop(@svc_name)
          rescue ServiceManager::ServiceError => e
          end

          begin
            ServiceManager.delete(@svc_name)
          rescue ServiceManager::ServiceError => e
            puts e
          end

          unless ServiceManager.exist?(@svc_name) then
            puts "#{display_name} service removed."
          end
        end
      end
    end

    # Manages all of the available commands
    # and handles running them.
    class Registry

      # Builds a list of possible commands from the Command derivatives list
      def commands
        ThinService::Command::COMMANDS
      end

      # Prints a list of available commands.
      def print_command_list
        puts("#{ThinService::Command::BANNER}\nAvailable commands are:\n\n")

        self.commands.each do |name|
          puts(" - #{name}\n") unless name == "start"
        end

        puts("\nEach command takes -h as an option to get help.")

      end

      def constantize(class_name)
        unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ class_name
          raise NameError, "#{class_name.inspect} is not a valid constant name!"
        end

        Object.module_eval("::#{$1}", __FILE__, __LINE__)
      end


      # Runs the args against the first argument as the command name.
      # If it has any errors it returns a false, otherwise it return true.
      def run(args)
        # find the command
        cmd_name = args.shift

        if !cmd_name || cmd_name == "-?" || cmd_name == "--help"
          print_command_list
          return true
        elsif cmd_name == "--version"
          puts("ThinService #{ThinService::VERSION}")
          return true
        end

        begin
          cmd_class_name = "ThinService::Command::Commands::" + cmd_name.capitalize
          command = constantize(cmd_class_name).new( :argv => args  )
        rescue OptionParser::InvalidOption
          STDERR.puts "#$! for command '#{cmd_name}'"
          STDERR.puts "Try #{cmd_name} -h to get help."
          return false
        rescue
          STDERR.puts "ERROR RUNNING '#{cmd_name}': #$!"
          STDERR.puts "Use help command to get help"
          return false
        end

        if !command.done_validating 
          if !command.validate
            STDERR.puts "#{cmd_name} reported an error. Use thin_service #{cmd_name} -h to get help."
            return false
          else
            command.run
          end
        end

        return true
      end

    end
  end
end
