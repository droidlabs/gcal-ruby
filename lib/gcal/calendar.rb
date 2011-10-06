module GCal
  class Calendar
    attr_accessor :id, :title, :link, :author_name, :author_email,
      :access_level, :color, :hidden, :selected, :timezone,
      :updated_at, :published_at
    
    def hidden?
      hidden
    end
    
    def visible
      !hidden?
    end
    
    def selected?
      selected
    end
    
    class << self
      def parse(entry, path)
        calendar_home_url = 'http://www.google.com/calendar/feeds'
        parse_time = Time.respond_to?(:parse)
        calendar = self.new
        
        # common info
        calendar.id = entry['id'][0].gsub(calendar_home_url + path, '')
        calendar.title = entry['title'][0]['content']
        calendar.link = entry['link'][0]['href']
        calendar.access_level = entry['accesslevel'][0]['value']
        calendar.color = entry['color'][0]['value']
        calendar.hidden = entry['hidden'][0]['value'] == 'true'
        calendar.selected = entry['selected'][0]['value'] == 'true'

        # time info
        calendar.timezone = entry['timezone'][0]['value']
        calendar.updated_at = parse_time ? Time.parse(entry['updated'][0]) : entry['updated'][0]
        calendar.published_at = parse_time ? Time.parse(entry['published'][0]) : entry['published'][0]

        # author
        author = entry['author'][0]
        calendar.author_name = author['name'] ? author['name'][0] : ''
        calendar.author_email = author['email'] ? author['email'][0] : ''
        calendar
      end
    end
  end
end