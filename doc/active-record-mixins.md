# ActiveRecord mixins

This page documents the model mixins provided by `redmineup`.

## `up_acts_as_taggable`

Adds polymorphic tagging support.

### Migration

```ruby
class CreateTags < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.create_taggable_table
  end
end
```

Useful migration helpers:

- `ActiveRecord::Base.create_taggable_table`
- `ActiveRecord::Base.drop_taggable_table`
- `ActiveRecord::Base.add_tags_column(:tags, name: :color, type: :integer, default: nil)`
- `ActiveRecord::Base.remove_tags_columns(:tags, :color)`

### Model

```ruby
class Product < ApplicationRecord
  up_acts_as_taggable
end
```

### Runtime API

- `record.tag_list` / `record.tag_list = 'a, b'`
- `record.save_tags` (called via callbacks)
- `Model.available_tags(project: @project, limit: 30)`
- `Model.tagged_with(['tag1', 'tag2'])`
- `Model.find_related_tags('tag1')`

## `up_acts_as_draftable`

Adds draft save/restore workflow for unsaved or changed records.

### Migration

```ruby
class CreateDrafts < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.create_drafts_table
  end
end
```

Helpers:

- `ActiveRecord::Base.create_drafts_table`
- `ActiveRecord::Base.drop_drafts_table`

### Model

```ruby
class WikiPage < ApplicationRecord
  up_acts_as_draftable parent: :wiki
end
```

### Runtime API

- `record.save_draft`
- `record.update_draft(attrs)`
- `Model.drafts(User.current)`
- `Model.from_draft(draft_or_id)`

## `up_acts_as_viewed`

Tracks unique views by user (or IP) and total views.

### Migration

```ruby
class CreateViewings < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.create_viewings_table
  end
end
```

Optional helpers for models with embedded counters:

- `ActiveRecord::Base.generate_viewings_columns(table)`
- `Model.add_viewings_columns`
- `Model.remove_viewings_columns`
- `ActiveRecord::Base.drop_viewings_table`

### Model

```ruby
class Question < ApplicationRecord
  up_acts_as_viewed
end
```

### Runtime API

- `record.view(request.remote_ip, User.current)`
- `record.viewed?`
- `record.view_count`
- `record.viewed_by?(request.remote_ip, User.current)`

## `up_acts_as_votable` and `up_acts_as_voter`

Adds voting capabilities for content and users.

### Migration

```ruby
class CreateVotes < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.create_votable_table
  end
end
```

Helpers:

- `ActiveRecord::Base.create_votable_table`
- `ActiveRecord::Base.drop_votable_table`

### Models

```ruby
class Question < ApplicationRecord
  up_acts_as_votable
end

class User < ApplicationRecord
  up_acts_as_voter
end
```

## `up_acts_as_priceable`

Generates currency-aware `*_to_s` methods for price fields.

### Model

```ruby
class Deal < ApplicationRecord
  up_acts_as_priceable :amount, :tax_amount, :subtotal, :total
end
```

This creates methods like `amount_to_s`, `tax_amount_to_s`, etc., backed by
`Redmineup::MoneyHelper#object_price`.
