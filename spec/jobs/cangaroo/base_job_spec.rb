require 'rails_helper'

module Cangaroo
  RSpec.describe PushJob, type: :job do
    class FakePushJobb < Cangaroo::PushJob
      connection :store
      path '/webhook_path'

      # def transform
      #   # ttt
      #     {}
      # end

      def perform?
        type == 'orders'
      end
    end

    let(:destination_connection) { create(:cangaroo_connection) }
    let(:type) { 'orders' }
    let(:payload) { { id: 'O123' } }
    let(:connection) { create(:cangaroo_connection) }
    let(:request_id) { '123456' }
    let(:parameters) { { email: 'info@nebulab.it' } }
    let(:url) { "http://#{connection.url}/api_path" }
    let(:connection_response) { parse_fixture('json_payload_connection_response.json') }

    let(:options) do
      { source_connection: destination_connection,
        type: type,
        payload: payload }
    end

    let(:client) do
      Cangaroo::Webhook::Client.new(destination_connection, '/webhook_path')
    end

    let(:fake_command) { double('fake perform flow command', success?: true) }

    before do
      # allow(client).to receive(:post).and_return(connection_response)
      allow(Cangaroo::Webhook::Client).to receive(:new).and_return(client)
      allow(Cangaroo::PerformFlow).to receive(:call).and_return(fake_command)
    end

    describe '#transform' do
      let(:failure_response) do
        '{"request_id":"c571579f-6ed3-4edf-bbd0-3d7923596942","summary":"Some items in your Order #R000801164 are backordered.","parameters":{"sync_action":null,"sync_type":"shipping_easy","vendor":9540,"sync_item":88}}'
      end
      it 'handle case' do
        stub_request(:post, "http://www.store.com/webhook_path").to_return(body: failure_response, status: 500)
        expect(Cangaroo.logger)
          .to receive(:error)
          .with("Exception in Sweet",
                hash_including(message: 'Some items in your Order #R000801164 are backordered.'))
        FakePushJobb.perform_now(options)
        # client.post(payload, request_id, parameters)
      end
      it 'log error if error' do
      end
    end
  end
end
