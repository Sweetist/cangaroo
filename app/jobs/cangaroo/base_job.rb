module Cangaroo
  class BaseJob < Job
    include Cangaroo::ClassConfiguration

    class_configuration :connection
    class_configuration :path, ''
    class_configuration :parameters, {}
    class_configuration :process_response, true

    protected

    def connection_request
      Cangaroo::Webhook::Client.new(destination_connection, path).post(transform, job_id, parameters)
    end

    def restart_flow(response)
      # if no json was returned, the response should be discarded
      return if response.blank?

      return unless process_response

      command = PerformFlow.call(
        source_connection: destination_connection,
        json_body: response,
        jobs: Rails.configuration.cangaroo.jobs.reject{ |job| job == self.class }
      )

      # binding.pry
      # fail Cangaroo::Webhook::Error, command.message unless command.success?
    end

    def destination_connection
      return @destination_connection if @destination_connection
      return @destination_connection = Cangaroo::Connection.find_by!(name: connection) unless vendor

      @destination_connection = Cangaroo::Connection.find_by!(name: "#{connection}_#{vendor}")
    end

    rescue_from(StandardError) do |exception|
      current_type = type || ''
      current_payload = payload || ''
      Cangaroo.logger.error 'Exception in Cangaroo',
                            message: exception.message,
                            cause: exception.cause,
                            backtrace: exception.backtrace,
                            type: current_type,
                            payload: current_payload
      # context.fail!(message: exception.message, error_code: 500)
    end
  end
end
