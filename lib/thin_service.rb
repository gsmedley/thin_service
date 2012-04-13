require_relative "thin_service/version.rb"
require_relative "thin_service/command.rb"

module ThinService
  class Service
    def initialize( args )
      @args = args
    end

    def run!
      ThinService::Command::Registry.new.run(  @args )
    end

  end
end
