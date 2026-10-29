require 'liquid'

module Redmineup
  module Liquid
    module Filters
      module Additional
        def parse_inline_attachments(text, obj)
          attachments = obj.attachments if obj.respond_to?(:attachments)

          if attachments.present?
            text.gsub!(/src="([^\/"]+\.(bmp|gif|jpg|jpe|jpeg|png))"(\s+alt="([^"]*)")?/i) do |m|
              filename, ext, alt, alttext = $1, $2, $3, $4
              # search for the picture in attachments
              if found = Attachment.latest_attach(attachments, CGI.unescape(filename))
                desc = found.description.to_s.delete('"')
                alt = " title=\"#{desc}\" alt=\"#{desc}\"" if !desc.blank? && alttext.blank?
                "src='data:image/#{found.content_type};base64,#{found.to_base64_string}' #{alt}"
              else
                m
              end
            end
          end

          text
        end
      end

      ::Liquid::Template.register_filter(Redmineup::Liquid::Filters::Additional)
    end
  end
end
