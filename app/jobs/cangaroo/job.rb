module Cangaroo
  class Job < ActiveJob::Base
    include Cangaroo::LoggerHelper

    queue_as :cangaroo

    def perform?
      fail NotImplementedError
    end

    def source_connection
      arguments.first.fetch(:source_connection)
    end

    def type
      arguments.first.fetch(:type)
    end

    def payload
      arguments.first.fetch(:payload)
    end

    def vendor
      arguments.first.fetch(:vendor, nil)
    end

    def sync_type
      arguments.first.fetch(:sync_type, nil)
    end
  end
end
