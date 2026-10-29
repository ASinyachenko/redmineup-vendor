require File.dirname(__FILE__) + '/test_helper'

class TagsHelperViewTest < ActionView::TestCase
  include Redmineup::TagsHelper
  include Redmineup::FormTagHelper

  def stub_tag_url(name) 
    "/stub_tags/#{name}" # URL stub for tag_cloud_links(tags, :stub)
  end

  def test_tag_link
    result = tag_link('/tags/error', 'error', count: 3)
    assert_includes result, 'tag-label-color'
    assert_includes result, 'background-color: #'
    assert_includes result, '(3)'
  end

  def test_tag_links
    result = tag_links(['error', 'bug']) { |t| "/tags/#{t}" }
    assert_includes result, 'class="tag_list"'
    assert_nil tag_links([]) { |t| "/tags/#{t}" }
  end

  def test_tag_cloud_links
    result = tag_cloud_links(Issue.tag_counts, :stub)
    assert_includes result, 'class="tag_list"'
    assert_includes result, '/stub_tags/'
    assert_nil tag_cloud_links([], :stub)
    assert_raises(NoMethodError) { tag_cloud_links(Issue.tag_counts, :unknown_xyz) }
  end

  def with_tag_display(mode, style: 'cloud', counts: true)
    settings = Module.new do
      define_singleton_method(:mode) { mode }
      define_singleton_method(:sidebar_style) { style }
      define_singleton_method(:sidebar_counts?) { counts }
      define_singleton_method(:sort_by) { 'name' }
      define_singleton_method(:sort_order) { 'asc' }
    end
    created = !Object.const_defined?(:RedmineupTags)
    Object.const_set(:RedmineupTags, Module.new) if created
    RedmineupTags.const_set(:TagDisplay, settings)
    yield
  ensure
    RedmineupTags.send(:remove_const, :TagDisplay) if RedmineupTags.const_defined?(:TagDisplay, false)
    Object.send(:remove_const, :RedmineupTags) if created
  end

  def test_tag_label_without_tags_plugin_is_color
    result = tag_label('x', '#112233')
    assert_includes result, 'tag-label tag-label-color'
    assert_includes result, 'background-color: #112233'
    assert_equal ' ', tag_label_separator
  end

  def test_tag_label_modes
    with_tag_display('plain') do
      assert_includes tag_label('x', '#112233'), 'tag-label tag-label-plain'
      assert_not_includes tag_label('x', '#112233'), 'background-color'
    end
    with_tag_display('link') do
      assert_equal '<span class="tag-link">x</span>', tag_label('x', '#112233')
      assert_equal ', ', tag_label_separator
    end
  end

  def test_tag_label_link_and_links
    result = tag_label_link('/tags/error', 'error', count: 3, color: '#abcdef', class: 'x')
    assert_includes result, 'background-color: #abcdef'
    assert_includes result, '(3)'
    assert_includes result, 'class="x"'
    links = tag_label_links(%w[a b]) { |t| "/tags/#{t}" }
    assert_includes links, 'class="tag_list"'
    assert_includes links, '/tags/a'
    assert_nil tag_label_links([]) { |t| "/tags/#{t}" }
  end

  def test_tag_sidebar_cloud_styles
    tags = Issue.tag_counts
    assert_nil tag_sidebar_cloud([], :stub)
    assert_includes tag_sidebar_cloud(tags, :stub), 'class="tags-cloud"'
    with_tag_display('plain', style: 'list') do
      result = tag_sidebar_cloud(tags, :stub)
      assert_includes result, '<ul'
      assert_includes result, 'class="letter"'
    end
    with_tag_display('color', counts: false) do
      assert_not_includes tag_sidebar_cloud(tags, :stub), 'tag-count'
    end
    assert_raises(NoMethodError) { tag_sidebar_cloud(tags, :unknown_xyz) }
  end

  def test_tag_list_field_tag
    result = tag_list_field_tag('issue[tag_list]', ['bug'],
                                url: '/auto_completes/taggable_tags',
                                width: '60%', tags: false,
                                placeholder: '+ add tag')
    assert_includes result, 'name="issue[tag_list][]"'
    assert_includes result, 'style="width: 60%;"'
    assert_includes result, '"width":"style"'
    assert_includes result, '"tags":false'
  end

  def test_tag_list_field_tag_with_default_width
    result = tag_list_field_tag('issue[tag_list]', [],
                                url: '/auto_completes/taggable_tags',
                                placeholder: '+ add tag')
    assert_includes result, 'style="width: 95%;"'
    assert_includes result, '"width":"style"'
  end
end
