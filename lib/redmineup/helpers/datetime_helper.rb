module Redmineup
  module DatetimeHelper
    def convert_time_to_user_timezone(time)
      if User.current.time_zone
        time.in_time_zone(User.current.time_zone)
      else
        time.utc? ? time.localtime : time
      end
    end

    def convert_time_to_utc(time = Time.now)
      return Time.now.utc if time.blank?
      return time.utc if time.respond_to?(:utc)

      time_zone = User.current.time_zone
      return Time.parse(time).utc unless time_zone

      Time.use_zone(time_zone) do
        Time.zone.parse(time).utc
      end
    end
  end
end