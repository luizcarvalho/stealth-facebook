# frozen_string_literal: true

module Stealth
  module Services
    module Facebook
      class MessageEvent
        attr_reader :service_message, :params

        def initialize(service_message:, params:)
          @service_message = service_message
          @params = params
        end

        def process
          fetch_message
          fetch_location
          fetch_attachments
        end

        private

        def fetch_message
          if params['message']['quick_reply'].present?
            service_message.payload = params['message']['quick_reply']['payload']
          elsif params['message']['text'].present?
            service_message.message = params['message']['text']
          end
        end

        def fetch_location
          if params['message']['attachments'].present? && params['message']['attachments'].is_a?(Array)
            params['message']['attachments'].each do |attachment|
              next unless attachment['type'] == 'location'

              lat = attachment['payload']['coordinates']['lat']
              lng = attachment['payload']['coordinates']['long']

              service_message.location = {
                lat: lat,
                lng: lng
              }
            end
          end
        end

        def fetch_attachments
          if params['message']['attachments'].present? && params['message']['attachments'].is_a?(Array)
            params['message']['attachments'].each do |attachment|
              service_message.attachments << {
                type: attachment['type'],
                url: attachment['payload']['url']
              }
            end
          end
        end
      end
    end
  end
end
