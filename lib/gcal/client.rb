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
        calendars << parse_calendar(entry)
      end if xml['entry']
      calendars
    end
    
    def own_calendars
      xml = call("/default/owncalendars/full")
      calendars = []
      xml['entry'].each do |entry|
        calendars << parse_calendar(entry)
      end if xml['entry']
      calendars
    end
    
    def events(calendar_id)
      xml = call("/#{calendar_id}/private/full")
      events = []
      xml['entry'].each do |entry|
        event = GCal::Event.new
        
        # common info
        event.id = entry['id'][0].gsub("http://www.google.com/calendar/feeds/#{calendar_id}/private/full/", '')
        event.title = entry['title'][0]['content']
        event.link = entry['link'][0]['href']
        event.status = entry['eventStatus'][0]['value'].gsub(Event::STATUS_REGEXP, '')
        event.where = entry['where'][0]['valueString']
        event.who = entry['who'][0]['valueString']
        
        # time info
        time = entry['when'][0]
        event.start_time = parse_time? ? Time.parse(time['startTime']) : time['startTime']
        event.end_time = parse_time? ? Time.parse(time['endTime']) : time['endTime']
        event.updated_at = parse_time? ? Time.parse(entry['updated'][0]) : entry['updated'][0]
        event.published_at = parse_time? ? Time.parse(entry['published'][0]) : entry['published'][0]
        
        # author
        author = entry['author'][0]
        event.author_name = author['name'] ? author['name'][0] : ''
        event.author_email = author['email'] ? author['email'][0] : ''
        events << event
      end if xml['entry']
      events
    end
    
    protected
    def parse_calendar(entry)
      calendar = GCal::Calendar.new
      
      # common info
      calendar.id = entry['id'][0].gsub('http://www.google.com/calendar/feeds/default/allcalendars/full/', '')
      calendar.title = entry['title'][0]['content']
      calendar.link = entry['link'][0]['href']
      calendar.access_level = entry['accesslevel'][0]['value']
      calendar.color = entry['color'][0]['value']
      calendar.hidden = entry['hidden'][0]['value'] == 'true'
      calendar.selected = entry['selected'][0]['value'] == 'true'
      
      # time info
      calendar.timezone = entry['timezone'][0]['value']
      calendar.updated_at = parse_time? ? Time.parse(entry['updated'][0]) : entry['updated'][0]
      calendar.published_at = parse_time? ? Time.parse(entry['published'][0]) : entry['published'][0]
      
      # author
      author = entry['author'][0]
      calendar.author_name = author['name'] ? author['name'][0] : ''
      calendar.author_email = author['email'] ? author['email'][0] : ''
      calendar
    end
    
    def parse_time?
      Time.respond_to?(:parse)
    end
    
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