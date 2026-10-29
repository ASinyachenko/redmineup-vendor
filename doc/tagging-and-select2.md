# Tagging and Select2 helpers

This page covers view helpers used by RedmineUP plugins for tag rendering,
tag editing, and select2-backed filters.

## Tag rendering helpers

Provided by `Redmineup::TagsHelper`:

- `tag_link(url, tag_name, options = {})`
- `tag_links(tag_list, options = {}) { |tag| url }`
- `tag_cloud(tags, classes) { |tag, css_class| ... }`
- `tag_cloud_links(tags, key, options = {})`

Since 1.1.16 (the display mode, sidebar style, counts and order come from the Tags plugin when it is installed; without it tags are colored chips in a cloud):

- `tag_display_mode` returns `color`, `plain` or `link`
- `tag_label(inner, color)` wraps markup in a chip (`span.tag-label.tag-label-color` / `.tag-label-plain`) or `span.tag-link`
- `tag_label_link(url, tag_name, options = {})`, `tag_label_links(tag_list, options = {}) { |tag| url }`, `tag_label_separator`
- `tag_sidebar_cloud(tags, key)` renders the sidebar tags (list, cloud or simple cloud) and resolves links through `{key}_tag_url`
- `tag_separator`

### Recommended pattern

Define `*_tag_url` per plugin context:

```ruby
def contact_tag_url(tag_name, options = {})
  {
    controller: 'contacts',
    action: 'index',
    set_filter: 1,
    fields: [:tags],
    values: { tags: [tag_name] },
    operators: { tags: '=' }
  }.merge(options)
end
```

Then render the cloud via convention:

```erb
<%= tag_cloud_links(Contact.available_tags(project: @project), :contact) %>
```

`tag_cloud_links(tags, :contact)` expects `contact_tag_url(name)` to be defined
in the current view context.

## Tag editors with Select2

Provided by `Redmineup::FormTagHelper`:

- `select2_tag(name, option_tags = nil, options = {})`
- `select2(...)` (alias)
- `tag_list_field_tag(name, value = [], options = {})`
- `transform_to_select2(type, options = {})`

`ActionView::Helpers::FormBuilder` is extended with:

- `f.tag_list_field(:tag_list, **options)`

### Example: form object API

```erb
<%= f.tag_list_field :tag_list, width: '95%' %>
```

### Example: standalone field API

```erb
<%= tag_list_field_tag 'product[tag_list]', @product.tag_list, taggable_type: 'Product' %>
```

### Example: query/filter select2 transform

```erb
<%= transform_to_select2 'product_tags',
      url: auto_complete_taggable_tags_path(project_id: @project, taggable_type: 'Product') %>
```

## Tag autocomplete endpoint

`redmineup` adds a shared route:

- `GET /auto_completes/taggable_tags`

Named route:

- `auto_complete_taggable_tags_path`

Typical params used by plugins:

- `taggable_type`: model class name (`Contact`, `Person`, `Product`, `Issue`, `DriveEntry`)
- `project_id`: optional project scope
- `limit`: optional result size limit

Response format:

```json
[
  { "id": "important", "text": "important" },
  { "id": "vip", "text": "vip" }
]
```

## Real plugin usage

Patterns above are used by:

- `redmine_contacts` (`contact_tag_url`, `contact_tag_links`, `f.tag_list_field`)
- `redmine_people` (`people_tag_url`, `tag_cloud_links`, bulk edit tag forms)
- `redmine_products` (`product_tag_url`, `tag_list_field_tag`, select2 filters)
- `redmine_questions` (`question_tag_url`, `tag_cloud_links`)
- `redmine_drive` (`drive_entry_tag_url`, select2 tag filters)
- `redmineup_tags` (issue tag forms with `tag_list_field_tag`)
