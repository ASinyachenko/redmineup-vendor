module Redmineup
  module Liquid
    class AttachmentDrop < ::Liquid::Drop
      delegate :id,
               :filename,
               :title,
               :description,
               :filesize,
               :content_type,
               :digest,
               :downloads,
               :created_on,
               :token,
               :visible?,
               :image?,
               :thumbnailable?,
               :is_text?,
               :readable?,
               to: :@attachment

      def initialize(attachment)
        @attachment = attachment
      end

      def url(options = {})
        Rails.application.routes.url_helpers.download_named_attachment_url(@attachment, { filename: filename,
                                                                                          host: Setting.host_name,
                                                                                          protocol: Setting.protocol }.merge(options))
      end

      def link
        link_to((@attachment.description.blank? ? @attachment.filename : @attachment.description), url)
      end

      def author
        @author ||= UserDrop.new @attachment.author
      end

      def read
        @content ||= if @attachment.is_text? && @attachment.filesize <= Setting.file_max_size_displayed.to_i.kilobyte
                       File.new(@attachment.diskfile, "rb").read
                     end
        @content
      end

      def to_s
        filename
      end

      def to_base64_string
        Base64.strict_encode64(File.read(@attachment.diskfile))
      end
    end
  end
end
