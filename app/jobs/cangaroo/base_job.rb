module Cangaroo
  class BaseJob < Job
    include Cangaroo::ClassConfiguration

    class_configuration :connection
    class_configuration :path, ''
    class_configuration :parameters, {}
    class_configuration :process_response, true

    protected

    def connection_request
      Cangaroo::Webhook::Client.new(destination_connection, path)
                               .post(transform, job_id, parameters.merge(request_params))
    end

    def restart_flow(response)
      # if no json was returned, the response should be discarded
      return if response.blank?

      return unless process_response
      PerformFlow.call(
        source_connection: destination_connection,
        json_body: response,
        jobs: Rails.configuration.cangaroo.jobs.reject{ |job| job == self.class }
      )
    end

    def destination_connection
      return @destination_connection if @destination_connection
      if connection == :main_store || vendor.nil?
        return @destination_connection = Cangaroo::Connection.find_by!(name: connection)
      end

      @destination_connection = Cangaroo::Connection.find_by!(name: "#{connection}_#{vendor}")
    end

    def error_params(message)
      return request_params if message.nil? || message.dig('parameters').nil?
      return request_params unless message.dig('parameters')
      request_params.merge(message.dig('parameters'))
    end

    rescue_from(StandardError) do |exception|
      Cangaroo.logger.error 'Exception in Cangaroo',
                            message: exception.message,
                            cause: exception.cause,
                            backtrace: exception.backtrace,
                            type: type || '',
                            payload: payload || '',
                            vendor: vendor || '',
                            parameters: request_params
    end
    rescue_from(Cangaroo::Webhook::Error) do |exception|
      message = JSON.parse(exception.message) if exception.message
      Cangaroo.logger.error 'Exception in Integration',
                            message: message.dig('summary', 'message'),
                            cause: message.dig('cause'),
                            backtrace: message.dig('summary', 'backtrace'),
                            type: type || '',
                            payload: payload || '',
                            vendor: vendor || '',
                            parameters: error_params(message)
    end
  end
end
