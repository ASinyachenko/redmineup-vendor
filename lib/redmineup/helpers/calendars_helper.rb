module Redmineup
  module CalendarsHelper

    def calendar_day_css_classes(calendar, day)
      css = day.month==calendar.month ? +'even' : +'odd'
      css << " today" if User.current.today == day
      css << " nwday" if non_working_week_days.include?(day.cwday)
      css
    end

    def non_working_week_days
      @non_working_week_days ||= begin
        days = Setting.non_working_week_days
        if days.is_a?(Array) && days.size < 7
          days.map(&:to_i)
        else
          []
        end
      end
    end
  end
end