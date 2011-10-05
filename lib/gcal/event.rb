module GCal
  class Event
    STATUS_REGEXP = /http\:\/\/schemas\.google\.com\/g\/[0-9]+\#event\./
    attr_accessor :id, :title, :link, :author_name, :author_email,
      :updated_at, :published_at, :status, :where, :who, :start_time, :end_time
      
    def confirmed?
      status == 'confirmed'
    end
  end
end