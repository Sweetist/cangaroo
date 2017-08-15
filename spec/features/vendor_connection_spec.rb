require 'rails_helper'

RSpec.describe 'Push with vendor' do
  class FakePushJobb < Cangaroo::PushJob
    connection :test
    path '/webhook_path'
    def perform?
      type == 'orders' && payload['state'] == 'payed'
    end
  end

  let!(:test_connection_wo_vendor) { create(:cangaroo_connection, url: 'http://some', name: 'test') }
  let!(:test_connection_with_vendor) { create(:cangaroo_connection, url: 'http://some2', name: 'test_1') }
  let(:vendor_payload) { load_fixture('json_payload_with_vendor_id.json') }
  let(:wo_vendor_payload) { load_fixture('json_payload_ok.json') }
  let(:store) { create :store }
  let(:headers) {
    { 'Content-Type' => 'application/json',
      'X-Hub-Store' => store.key,
      'X-Hub-Access-Token' => store.token }
  }

  before do
    Rails.configuration.cangaroo.jobs = [FakePushJobb]
  end

  it 'destination connection with vendor' do
    expect(Cangaroo::Webhook::Client).to receive(:new)
      .with(test_connection_with_vendor, '/webhook_path').ordered

    post endpoint_index_path, params: vendor_payload, headers: headers
  end

  it 'destination connection without vendor' do
    expect(Cangaroo::Webhook::Client).to receive(:new)
      .with(test_connection_wo_vendor, '/webhook_path')

    post endpoint_index_path, params: wo_vendor_payload, headers: headers
  end
end
