module Cangaroo
  class PerformJobs
    include Interactor

    def call
      context.json_body.each do |type, payloads|
        payloads.each { |payload| enqueue_jobs(type, payload) }
      end
    end

    private

    def enqueue_jobs(type, payload)
      enqueued_jobs = []
      skipped_jobs = []
      initialize_jobs(type, payload).each do |job|
        if job.perform?
          enqueued_jobs << job.class.to_s
          job.enqueue
        else
          skipped_jobs << job.class.to_s
        end
      end

      jobs_response(enqueued_jobs, skipped_jobs, payload)
    end

    def jobs_response(enqueued_jobs, skipped_jobs, payload)
      Cangaroo.logger.info 'Enqueu jobs:', enqueued_jobs: enqueued_jobs,
                                           skipped_jobs: skipped_jobs
      return if enqueued_jobs.any?

      air_params = {
        time: Time.current,
        payload: payload,
        vendor: context.vendor
      }
      Airbrake.notify('No Enqueued Jobs', air_params) if defined? Airbrake
    end

    def initialize_jobs(type, payload)
      context.jobs.map do |klass|
        klass.new(
          source_connection: context.source_connection,
          vendor: context.vendor,
          type: type,
          payload: payload,
          request_params: context.request_params || {}
        )
      end
    end
  end
end
