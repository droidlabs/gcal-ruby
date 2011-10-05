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
  end
end