module Redmineup
  module ExternalAssetsHelper
    include ActionView::Helpers::JavaScriptHelper

    def redmineup_assets
      return if @redmineup_assets_included

      @redmineup_assets_included = true
      javascript_include_tag('consumer', plugin: GEM_NAME) +
        javascript_include_tag('select2', plugin: GEM_NAME) +
        javascript_include_tag('select2_helpers', plugin: GEM_NAME) +
        javascript_include_tag('jquery.colorPicker.min', plugin: GEM_NAME) +
        stylesheet_link_tag('redmineup', plugin: GEM_NAME) +
        javascript_tag("window.redmineupWorkerUrl = #{asset_path('consumer_worker.js', plugin: GEM_NAME).to_json};")
    end

    def select2_assets
      redmineup_assets
    end

    def chartjs_assets
      return if @chartjs_tag_included

      @chartjs_tag_included = true
      javascript_include_tag('chart.min', plugin: GEM_NAME)
    end
  end
end
