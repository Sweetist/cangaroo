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
      Cangaroo.logger.info 'Enqueu jobs:', enqueued_jobs: enqueued_jobs,
                                           skipped_jobs: skipped_jobs

      # Cangaroo.logger.info 'Enqueu jobs:', enqueued_jobs: enqueued_jobs,
      #                                      skipped_jobs: skipped_jobs,
      #                                      payload: payload
    end

    def initialize_jobs(type, payload)
      context.jobs.map do |klass|
        klass.new(
          source_connection: context.source_connection,
          vendor: context.vendor,
          sync_type: context.sync_type,
          type: type,
          payload: payload
        )
      end
    end
  end
end
