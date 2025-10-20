require 'rails_helper'

RSpec.describe RabbitmqAdapter do
  let(:adapter) { described_class.new }

  describe '#initialize' do
    it 'creates connection to RabbitMQ' do
      expect(adapter.connected?).to be true
    end

    it 'creates channel' do
      expect(adapter.channel).to be_a(Bunny::Channel)
    end

    it 'creates exchange' do
      expect(adapter.exchange).to be_a(Bunny::Exchange)
    end
  end

  describe '#publish' do
    it 'publishes message to exchange' do
      message = { test: 'data', timestamp: Time.current.to_s }

      expect {
        adapter.publish('test.event', message)
      }.not_to raise_error
    end

    it 'accepts string messages' do
      expect {
        adapter.publish('test.event', '{"key":"value"}')
      }.not_to raise_error
    end

    it 'accepts hash messages' do
      expect {
        adapter.publish('test.event', { key: 'value' })
      }.not_to raise_error
    end
  end

  describe '#subscribe' do
    it 'creates queue and binds to exchange' do
      queue_created = false

      thread = Thread.new do
        adapter.subscribe('test.event') do |message|
          queue_created = true
          Thread.current.exit
        end
      end

      sleep 0.5
      adapter.publish('test.event', { test: 'data' })
      sleep 0.5

      thread.kill if thread.alive?
      expect(queue_created).to be true
    end
  end

  describe '#connected?' do
    it 'returns true when connected' do
      expect(adapter.connected?).to be true
    end

    it 'returns false after closing' do
      adapter.close
      expect(adapter.connected?).to be false
    end
  end

  describe '#close' do
    it 'closes connection and channel' do
      adapter.close
      expect(adapter.connected?).to be false
    end
  end
end
