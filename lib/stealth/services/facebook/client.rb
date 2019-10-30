# frozen_string_literal: true

require 'faraday'

require 'stealth/services/facebook/message_handler'
require 'stealth/services/facebook/reply_handler'
require 'stealth/services/facebook/setup'

module Stealth
  module Services
    module Facebook
      class Client < Stealth::Services::BaseClient
        GRAPH_API_VERSION = '4.0'
        FB_ENDPOINT = "https://graph.facebook.com/v#{GRAPH_API_VERSION}/me"

        attr_reader :api_endpoint, :reply

        def initialize(reply:, endpoint: 'messages')
          @reply = reply
          access_token = "access_token=#{Stealth.config.facebook.page_access_token}"
          @api_endpoint = [[FB_ENDPOINT, endpoint].join('/'), access_token].join('?')
        end

        def transmit
          headers = { 'Content-Type' => 'application/json' }
          response = Faraday.post(api_endpoint, reply.to_json, headers)
          Stealth::Logger.l(topic: 'facebook', message: "Transmitting. Response: #{response.status}: #{response.body}")
        end

        def self.fetch_profile(recipient_id:, fields: nil)
          if fields.blank?
            fields = %i[first_name last_name profile_pic locale timezone gender is_payment_enabled last_ad_referral]
          end

          query_hash = {
            fields: fields.join(','),
            access_token: Stealth.config.facebook.page_access_token
          }

          uri = URI::HTTPS.build(
            host: 'graph.facebook.com',
            path: "/v#{GRAPH_API_VERSION}/#{recipient_id}",
            query: query_hash.to_query
          )

          response = Faraday.get(uri.to_s)
          Stealth::Logger.l(
            topic: 'facebook',
            message: "Requested user profile for #{recipient_id}. Response: #{response.status}: #{response.body}"
          )

          if response.status.in?(200..299)
            MultiJson.load(response.body)
          else
            raise(Stealth::Errors::ServiceError, "Facebook error #{response.status}: #{response.body}")
          end
        end
      end
    end
  end
end
