# Assets, money, and shared utilities

## Asset helpers

Provided by `Redmineup::ExternalAssetsHelper`:

- `redmineup_assets`
- `select2_assets` (alias for `redmineup_assets`)
- `chartjs_assets`

`redmineup_assets` includes:

- `consumer.js`
- `select2.js`
- `select2_helpers.js`
- `redmineup.css`

The gem also hooks `view_layouts_base_html_head` and renders
`redmineup/_additional_assets`, so shared assets can be included globally.
Helpers are idempotent and safe to call from plugin views.

## Money and currency

### Settings API

`Redmineup::Settings::Money` provides access to plugin-level money settings:

- `default_currency`
- `major_currencies`
- `default_tax`
- `tax_type`, `tax_exclusive?`
- `thousands_delimiter`
- `decimal_separator`
- `disable_taxes?`

### Formatting helpers

`Redmineup::MoneyHelper` provides:

- `price_to_currency(price, currency, options = {})`
- `object_price(record, :price)`
- `prices_collection_by_currency(hash, hide_zeros: true)`
- `collection_for_currencies_select`
- `all_currencies`

`up_acts_as_priceable` uses these helpers to generate `*_to_s` methods on
models.

### Admin UI

`Redmineup::Currency.add_admin_money_menu` registers a Redmine admin menu item
that points to:

- `redmineup_settings_path(:money)`

## Misc shared helpers and patches

- `Redmineup::CalendarsHelper#calendar_day_css_classes`
- Liquid patch for numeric conversion in `Liquid::StandardFilters`
- Liquid filters/drops under `lib/redmineup/liquid/**`
- Compatibility and ActionCable patches loaded at gem boot

## Version requirements in plugins

Plugins typically guard compatibility in `init.rb`:

```ruby
requires_redmineup version_or_higher: '1.1.5'
```

Use this to fail fast when a plugin depends on newer helper or API behavior.
