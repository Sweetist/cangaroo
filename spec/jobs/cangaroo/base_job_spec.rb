require 'rails_helper'

module Cangaroo
  RSpec.describe PushJob, type: :job do
    class FakePushJobb < Cangaroo::PushJob
      connection :test
      path '/webhook_path'

      def transform
        ttt
      end

      def perform?
        type == 'orders'
      end
    end

    let(:destination_connection) { create(:cangaroo_connection) }
    let(:type) { 'orders' }
    let(:payload) { { id: 'O123' } }
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
      allow(client).to receive(:post).and_return(connection_response)
      allow(Cangaroo::Webhook::Client).to receive(:new).and_return(client)
      allow(Cangaroo::PerformFlow).to receive(:call).and_return(fake_command)
    end

    describe '#transform' do
      it 'log error if error' do
        expect(Cangaroo.logger).to receive(:error)
        FakePushJobb.perform_now(options)
      end
    end
  end
end
