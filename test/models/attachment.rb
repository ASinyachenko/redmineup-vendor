class Attachment < ActiveRecord::Base
  belongs_to :author, :class_name => "User"

  def self.latest_attach(attachments, filename)
    # stub method for test
    # returned one attachment
  end
end
