# frozen_string_literal: true

module Redmineup
  module Hooks
    class ViewsLayoutsHook < Redmine::Hook::ViewListener
      render_on :view_layouts_base_html_head, partial: 'redmineup/additional_assets'
    end
  end
end
