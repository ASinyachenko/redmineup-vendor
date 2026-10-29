# redmineup

`redmineup` is a shared gem used by RedmineUP plugins. It provides common
ActiveRecord mixins, view helpers, assets, settings, and compatibility patches
so plugin code stays focused on domain logic.

The gem is used in production plugins such as `redmine_contacts`,
`redmine_people`, `redmine_products`, `redmine_questions`, `redmine_drive`,
`redmineup_tags`, `redmine_agile`, and others.

## What is included

- ActiveRecord mixins: `up_acts_as_taggable`, `up_acts_as_draftable`,
  `up_acts_as_viewed`, `up_acts_as_votable`, `up_acts_as_voter`,
  `up_acts_as_priceable`
- Tag helpers and tag UI helpers: `tag_link`, `tag_links`, `tag_cloud_links`,
  `tag_list_field_tag`, `FormBuilder#tag_list_field`
- Select2 and chart integration helpers: `select2_tag`, `transform_to_select2`,
  `redmineup_assets`, `chartjs_assets`
- Shared endpoint for tag autocompletion:
  `auto_complete_taggable_tags_path`
- Money and currency formatting (`Redmineup::MoneyHelper`,
  `Redmineup::Currency`, `Redmineup::Settings::Money`)
- Liquid filters and drops used across RedmineUP plugins

## Installation

Add to your Redmine or plugin `Gemfile`:

```ruby
gem 'redmineup'
```

Install dependencies:

```bash
bundle install
```

In plugin `init.rb`, guard the minimum supported version:

```ruby
requires_redmineup version_or_higher: '1.1.5'
```

## Quick start

### 1) Add taggable behavior to a model

```ruby
# db/migrate/XXXXXXXXXXXX_create_tags.rb
class CreateTags < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.create_taggable_table
  end
end
```

```ruby
class Contact < ApplicationRecord
  up_acts_as_taggable
end
```

### 2) Render tags using shared helpers

```ruby
# helper
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

```erb
<%= tag_cloud_links(Contact.available_tags(project: @project), :contact) %>
```

`tag_cloud_links(tags, :contact)` resolves links via `contact_tag_url(name)`.

### 3) Add Select2 tag editor to forms

```erb
<%= f.tag_list_field :tag_list, width: '95%' %>
```

or standalone:

```erb
<%= tag_list_field_tag 'contact[tag_list]', @contact.tag_list, taggable_type: 'Contact' %>
```

## Documentation

- [ActiveRecord mixins](doc/active-record-mixins.md)
- [Tagging and Select2 helpers](doc/tagging-and-select2.md)
- [Assets, money, and shared utilities](doc/assets-money-and-utilities.md)

## Development

Install dependencies:

```bash
bundle install
```

Run tests:

```bash
bundle exec rake test
```

Run tests against another DB adapter:

```bash
bundle exec rake test DB=postgresql
```

Available `DB` values: `sqlite`, `mysql`, `postgresql`.
