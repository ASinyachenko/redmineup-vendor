module Redmineup
  module TagsHelper
    # See the README for an example using tag_cloud.
    def tag_cloud(tags, classes)
      return if tags.empty?
      max_count = tags.sort_by(&:count).last.count.to_f
      tags.each do |tag|
        index = ((tag.count / max_count) * (classes.size - 1)).round
        yield tag, classes[index]
      end
    end

    def tag_link(url, tag_name, options = {})
      count      = options.delete(:count)
      inner      = link_to(tag_name, url, options)
      inner << content_tag('span', "(#{count})", class: 'tag-count') if count
      css        = monochrome? ? 'tag-label' : 'tag-label-color'
      style      = monochrome? ? {} : { style: "background-color: #{Redmineup::ActsAsTaggable::Tag.color_from_name(tag_name)}" }
      content_tag(:span, inner, { class: css }.merge(style))
    end

    def tag_separator
      ' '
    end

    def monochrome?
      @monochrome ||= defined?(RedmineupTags) && !RedmineupTags.use_colors?
    end

    def tag_links(tag_list, options = {}, &url_block)
      return if tag_list.blank?
      content_tag(:span, class: 'tag_list') do
        safe_join(tag_list.map { |tag| tag_link(url_block.call(tag), tag, options.dup) }, tag_separator)
      end
    end

    # Renders span.tag_list from an array of tag objects (respond to .name and .count).
    # Resolves URL via `{key}_tag_url(name)` in the current view context.
    #
    #   tag_cloud_links(contact.available_tags, :contact)   # → contact_tag_url(name)
    #   tag_cloud_links(tags_cloud, :people)                # → people_tag_url(name)
    def tag_cloud_links(tags, key, options = {})
      return if tags.blank?
      url_method = :"#{key}_tag_url"
      raise NoMethodError, "#{url_method} is not defined in view context" unless respond_to?(url_method, true)
      content_tag(:span, class: 'tag_list') do
        safe_join(tags.map { |tag|
          tag_link(send(url_method, tag.name), tag.name, options.merge(count: tag.count).dup)
        }, tag_separator)
      end
    end


    def tag_display_mode
      if defined?(RedmineupTags::TagDisplay)
        RedmineupTags::TagDisplay.mode
      elsif defined?(RedmineupTags) && RedmineupTags.respond_to?(:use_colors?)
        RedmineupTags.use_colors? ? 'color' : 'plain'
      else
        'color'
      end
    end

    def tag_label_separator
      tag_display_mode == 'link' ? ', ' : ' '
    end

    def tag_label(inner, color)
      case tag_display_mode
      when 'color' then content_tag(:span, inner, class: 'tag-label tag-label-color', style: "background-color: #{color}")
      when 'plain' then content_tag(:span, inner, class: 'tag-label tag-label-plain')
      else content_tag(:span, inner, class: 'tag-link')
      end
    end

    def tag_label_link(url, tag_name, options = {})
      options = options.dup
      count = options.delete(:count)
      color = options.delete(:color) || Redmineup::ActsAsTaggable::Tag.color_from_name(tag_name)
      inner = link_to(tag_name, url, options)
      inner << content_tag('span', "(#{count})", class: 'tag-count') if count
      tag_label(inner, color)
    end

    def tag_label_links(tag_list, options = {}, &url_block)
      return if tag_list.blank?

      content_tag(:span, class: 'tag_list') do
        safe_join(Array(tag_list).map { |tag| tag_label_link(url_block.call(tag), tag, options) }, tag_label_separator)
      end
    end

    def tag_sidebar_cloud(tags, key)
      return if tags.blank?

      settings = defined?(RedmineupTags::TagDisplay) ? RedmineupTags::TagDisplay : nil
      style = settings ? settings.sidebar_style : 'cloud'
      counts = settings ? settings.sidebar_counts? : true
      sort_by, sort_order = settings ? [settings.sort_by, settings.sort_order] : %w[name asc]

      url_method = :"#{key}_tag_url"
      raise NoMethodError, "#{url_method} is not defined in view context" unless respond_to?(url_method, true)

      tags = tags.to_a.sort_by { |tag| sort_by == 'count' ? tag.count.to_i : tag.name.downcase }
      tags.reverse! if sort_order == 'desc'
      group_by_letter = style == 'list' && sort_by == 'name'
      groups = group_by_letter ? tags.group_by { |tag| tag.name.downcase.first } : { nil => tags }
      list_el, item_el = style == 'list' ? %w[ul li] : %w[div span]
      separator = style == 'simple_cloud' ? tag_label_separator : ' '
      content = groups.map do |letter, grouped|
        items = []
        tag_cloud(grouped, (1..8).to_a) do |tag, weight|
          items << content_tag(item_el, tag_label_link(send(url_method, tag.name), tag.name, count: (tag.count if counts && tag.count.to_i > 0), color: (tag.color if tag.respond_to?(:color))), class: "tag-nube-#{weight}", style: ('font-size: 1em;' if style == 'simple_cloud'))
        end
        safe_join([(content_tag(item_el, letter.upcase, class: 'letter') if letter), safe_join(items, separator)])
      end
      content_tag(list_el, safe_join(content), class: 'tags-cloud', style: ('text-align: left;' if style == 'simple_cloud'))
    end

  end
end
