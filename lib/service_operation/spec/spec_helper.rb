# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'service_operation/spec/support/operation_contexts'

# Stub ServiceNotifications
module StubServiceNotifications
  # @example
  #   stub_service_notifications(YourOperation, email: user.email)
  # @example
  #   stub_service_notifications(objects: a_hash_including(plain: a_string_matching(/Welcome/)))
  def stub_service_notifications(*args)
    options, klass = args.reverse
    klass ||= described_class

    stubber = allow(klass).to receive(:service_notifications_post)
    stubber = stubber.with stub_service_notifications_options(options) if options
    stubber.and_return [:created, { test: true }]
  end

  private

  def stub_service_notifications_options(options)
    recipient = options.delete(:recipient) ||
                { email: options.delete(:email), uid: options.delete(:uid) }.compact

    options[:recipients] ||= [a_hash_including(recipient)] if recipient[:email]

    options = {
      url: ENV['SERVICE_NOTIFICATIONS_URL'], api_key: a_string_matching(/^(.*){32}$/)
    }.merge options

    a_hash_including options
  end
end

RSpec.configure do |config|
  config.include StubServiceNotifications
  config.include_context 'operation', type: :operation
end