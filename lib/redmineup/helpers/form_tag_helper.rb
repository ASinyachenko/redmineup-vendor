module Redmineup
  module FormTagHelper
    # Allows include select2 into your views.
    #
    # ==== Examples
    #   select2_tag 'city_id', '<option value="1">Lisbon</option>...'
    #   select2_tag 'city_id', options_for_select(...)
    #   select2_tag 'tag_list', nil, :multiple => true, :data => [{ id: 0, text: 'deal' }, ...], :tags => true, :include_hidden => false %>
    #   select2_tag 'tag_list', options_for_select(...), :multiple => true, :style => 'width: 100%;', :url => '/tags', :placeholder => '+ add tag', :tags => true %>
    #
    # You may use select_tag options and additional options.
    #
    # ==== Additional options
    # * <tt>:url</tt> Allows searches for remote data using the ajax.
    # * <tt>:data</tt> Load dropdown options from a local array if +url+ option not set.
    # * <tt>:placeholder</tt> Supports displaying a placeholder value.
    # * <tt>:include_hidden</tt> Adds hidden field after select when +multiple+ option true. Default value true.
    # * <tt>:allow_clear</tt> Provides support for clearable selections. Default value false.
    # * <tt>:min_input_length</tt> Minimum number of characters required to start a search. Default value 0.
    # * <tt>:format_state</tt> Defines template of search results in the drop-down.
    # * <tt>:on_select</tt> Global JS callback name bound to `select2:select` event.
    # * <tt>:tags</tt> Used to enable tagging feature.
    #
    # <b>Note:</b> The HTML specification says when +multiple+ parameter passed to select and all options got deselected
    # web browsers do not send any value to server.
    #
    # In case if you don't want the helper to generate this hidden field you can specify
    # <tt>include_hidden: false</tt> option.
    #
    # <b>Note:</b> Select2 assets must be available on a page.
    #   To include select2 assets to a page, you need to use the helper select2_assets.
    #   For example:
    #     <% content_for :header_tags do %>
    #       <%= select2_assets %>
    #     <% end %>
    #
    # Also aliased as: select2
    #
    #   select2 'city_id', options_for_select(...)
    #
    def select2_tag(name, option_tags = nil, options = {})
      s = select_tag(name, option_tags, options)

      if options[:multiple] && options.fetch(:include_hidden, true)
        s << hidden_field_tag("#{name}[]", '')
      end

      s + javascript_tag("select2Tag('#{sanitize_to_id(name)}', #{options.to_json});")
    end

    alias select2 select2_tag

    # Renders a select2 tag field for a tag list (standalone, no form object).
    # Analogous to text_field_tag.
    #
    # ==== Example
    #   tag_list_field_tag 'entry[tag_list]', entry.tag_list,
    #     url: auto_complete_taggable_tags_path(taggable_type: 'DriveEntry')
    def tag_list_field_tag(name, value = [], options = {})
      url = options.delete(:url)
      taggable_type = options.delete(:taggable_type)
      width = options.delete(:width)
      project_id = options.delete(:project_id)
      placeholder = options.delete(:placeholder)
      select2_tag(
        name,
        options_for_select(value, value),
        {
          multiple:    true,
          style:       "width: #{width || '95%'};",
          width:       'style',
          url:         url || auto_complete_taggable_tags_path(taggable_type: taggable_type, project_id: project_id),
          placeholder: placeholder || l(:lable_redmineup_add_tag),
          tags:        true
        }.merge(options)
      )
    end

    # Transforms select filters of +type+ fields into select2
    #
    # ==== Examples
    #   transform_to_select2 'tags', url: auto_complete_tags_url
    #   transform_to_select2 'people', format_state: 'formatStateWithAvatar', min_input_length: 1, url: '/managers'
    #
    # ==== Options
    # * <tt>:url</tt> Defines URL to search remote data using the ajax.
    # * <tt>:format_state</tt> Defines template of search results in the drop-down.
    # * <tt>:min_input_length</tt> Minimum number of characters required to start a search. Default value 0.
    # * <tt>:width</tt> Sets the width of the control. Default value '60%'.
    # * <tt>:multiple</tt> Supports multi-value select box. If set to false the selection will not allow multiple choices. Default value true.
    #
    # <b>Note:</b> Select2 assets must be available on a page.
    #   To include select2 assets to a page, you need to use the helper select2_assets.
    #   For example:
    #     <% content_for :header_tags do %>
    #       <%= select2_assets %>
    #     <% end %>
    #
    def transform_to_select2(type, options = {})
      javascript_tag("setSelect2Filter('#{type}', #{options.to_json});") unless type.empty?
    end

    def format_datetime(time)
      formated_time = format_time(time, false)
      formated_date = ::I18n.l(time.to_date, format: '%Y-%m-%d')
      "#{formated_date} #{formated_time}"
    end

    def format_datetime_date(time)
      formated_date = ::I18n.l(time.to_date, format: '%Y-%m-%d')
      "#{formated_date}"
    end    

  end
end

# Extends Rails FormBuilder with tag_list_field, analogous to f.text_field.
#
# ==== Example
#   <%= f.tag_list_field :tag_list %>
ActionView::Helpers::FormBuilder.class_eval do
  def tag_list_field(method, **options)
    url = options.fetch(:url) {
      @template.auto_complete_taggable_tags_path(taggable_type: @object.class.name)
    }
    @template.tag_list_field_tag(
      "#{@object_name}[#{method}]",
      @object.public_send(method),
      {url: url}.merge(options.except(:url))
    )
  end
end
