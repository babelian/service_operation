# frozen_string_literal: true

module ServiceOperation
  # Extensions to ServiceOperation::Base for sending notifications via the ServiceNotifications gem.
  module ServiceNotification
    VALID_SERVICE_NOTIFICATION_STATUSES = [:created, :ok].freeze

    def self.included(base)
      base.extend ClassMethods
    end

    # ClassMethods
    module ClassMethods
      # in a Class Method to avoid using allow_any_instance_of in tests
      def service_notifications_post(payload)
        uri = URI payload.delete(:url)

        request = Net::HTTP::Post.new(uri)
        request.body = payload.to_json

        response = http(uri).request(request)

        # status, body
        [
          Rack::Utils::SYMBOL_TO_STATUS_CODE.invert[response.code],
          JSON.parse(response.body, symbolize_names: true)
        ]
      end

      private

      def http(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http
      end
    end

    #
    # Instances
    #

    # modify to suit in sub class
    def call
      context.response ||= notify
    end

    private

    # @return [Hash] response from ServiceNotifications
    def notify(options = nil)
      options ||= payload
      options = service_notifications_defaults.merge(options)

      status, body = self.class.service_notifications_post options

      unless VALID_SERVICE_NOTIFICATION_STATUSES.include?(status)
        context.service_notifications_response = body
        fail!(status)
      end

      body
    end

    # A standard ServiceNotification payload for {#notify} to use
    # @abstract
    # @return [Hash]
    def payload
      raise 'define in subclass'
    end

    def service_notifications_defaults
      {
        url: service_notifications_url,
        api_key: service_notifications_api_key,
        instant: true, notification: 'inline'
      }
    end

    # define in sub class or pass in payload
    # @abstract
    # @return [String]
    def service_notifications_api_key
      raise 'define in subclass'
    end

    def service_notifications_url
      ENV['SERVICE_NOTIFICATIONS_URL']
    end
  end
end