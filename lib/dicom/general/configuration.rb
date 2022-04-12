require 'logger'

module DICOM
  module Configuration
    ##
    # Logger for {#debug}, default is `DICOM::Logger.new(STDOUT)`, but
    # you can override it, for example if you want the logs to be written to
    # a file.
    #
    # @return [Logger]
    #
    attr_accessor :logger

    def self.extended(base)
      base.logger = Logger.new($stdout).tap { |l| l.level = Logger::INFO }
    end

    ##
    # @yield [self]
    # @example
    #   DICOM.configure do |config|
    #     config.logger = Logger.new
    #   end
    #
    def configure
      yield self
    end
  end
end
