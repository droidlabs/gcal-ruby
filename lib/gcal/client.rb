require 'oauth'
require 'oauth/request_proxy/typhoeus_request'
require 'xmlsimple'
module GCal
  class Client
    BASE_URL = 'https://www.google.com'
    API_URL = "#{BASE_URL}/calendar/feeds"
    
    def initialize(api_key = nil, api_secret = nil, token = nil, secret = nil)
      @api_key, @api_secret = api_key, api_secret
      @client = ::Typhoeus::Hydra.new
      # if api call protected, create token and consumer
      if protected_api_call?
        @consumer = ::OAuth::Consumer.new(api_key, api_secret, :site => BASE_URL)
        @token = ::OAuth::Token.new(token, secret)
      end
    end
    
    def call(uri)
      request = ::Typhoeus::Request.new(API_URL + uri)
      authorize_request!(request) if protected_api_call?
      @client.queue(request)
      @client.run
      XmlSimple.xml_in(request.response.body)
    end
    
    def all_calendars
      xml = call("/default/allcalendars/full")
      calendars = []
      xml['entry'].each do |entry|
        calendars << GCal::Calendar.parse(entry)
      end if xml['entry']
      calendars
    end
    
    def own_calendars
      xml = call("/default/owncalendars/full")
      calendars = []
      xml['entry'].each do |entry|
        calendars << GCal::Calendar.parse(entry)
      end if xml['entry']
      calendars
    end
    
    def events(calendar_id, options = {})
      xml = call("/#{calendar_id}/private/full#{GCal::Event.prepare_options(options)}")
      events = []
      xml['entry'].each do |entry|
        events << GCal::Event.parse(calendar_id, entry)
      end if xml['entry']
      events
    end
    
    protected
    
    def protected_api_call?
      !@api_key.nil?
    end
    
    def authorize_request!(request)
      oauth_helper = ::OAuth::Client::Helper.new(
        request, {
          :consumer => @consumer, 
          :token => @token,
          :request_uri => request.url
        }
      )
      request.headers.merge!({"Authorization" => oauth_helper.header})
    end
  end
end