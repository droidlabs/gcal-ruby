module GCal
  class Event
    STATUS_REGEXP = /http\:\/\/schemas\.google\.com\/g\/[0-9]+\#event\./
    attr_accessor :id, :title, :link, :author_name, :author_email,
      :updated_at, :published_at, :status, :where, :who, :start_time, :end_time
      
    def confirmed?
      status == 'confirmed'
    end
    
    class << self
      def parse(calendar_id, entry)
        parse_time = Time.respond_to?(:parse)
        event = self.new
        
        # common info
        event.id = entry['id'][0].gsub("http://www.google.com/calendar/feeds/#{calendar_id}/private/full/", '')
        event.title = entry['title'][0]['content']
        event.link = entry['link'][0]['href']
        event.status = entry['eventStatus'][0]['value'].gsub(Event::STATUS_REGEXP, '')
        event.where = entry['where'][0]['valueString']
        event.who = entry['who'][0]['valueString']
        
        # time info
        time = entry['when'][0]
        event.start_time = parse_time ? Time.parse(time['startTime']) : time['startTime']
        event.end_time = parse_time ? Time.parse(time['endTime']) : time['endTime']
        event.updated_at = parse_time ? Time.parse(entry['updated'][0]) : entry['updated'][0]
        event.published_at = parse_time ? Time.parse(entry['published'][0]) : entry['published'][0]
        
        # author
        author = entry['author'][0]
        event.author_name = author['name'] ? author['name'][0] : ''
        event.author_email = author['email'] ? author['email'][0] : ''
        event
      end
      
      def prepare_options(options)
        options.symbolize_keys! if Hash.respond_to?(:symbolize_keys!)
        prepared_options = {}
        if options[:start_time]
          prepared_options['start-min'] = options[:start_time].strftime("%Y-%m-%dT%H:%M:%S")
        end
        if options[:end_time]
          prepared_options['start-max'] = options[:end_time].strftime("%Y-%m-%dT%H:%M:%S")
        end
        if options[:timezone]
          prepared_options['ctz'] = options[:timezone].gsub(' ', '_')
        end
        if prepared_options.size > 0 
          "?" + prepared_options.map{|k, v| "#{k}=#{v}" }.join('&')
        else
          ''
        end
      end
    end
  end
end