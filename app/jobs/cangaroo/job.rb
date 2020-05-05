module Cangaroo
  class Job < ActiveJob::Base
    include Cangaroo::LoggerHelper

    queue_as :cangaroo

    def perform?
      fail NotImplementedError
    end

    def source_connection
      return unless arguments.first
      arguments.first.fetch(:source_connection)
    end

    def type
      return unless arguments.first
      arguments.first.fetch(:type)
    end

    def request_params
      return unless arguments.first
      arguments.first.fetch(:request_params, {})
    end

    def payload
      return unless arguments.first
      arguments.first.fetch(:payload)
    end

    def vendor
      return unless arguments.first
      arguments.first.fetch(:vendor, nil)
    end
  end
end
