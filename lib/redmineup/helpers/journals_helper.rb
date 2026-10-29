module Redmineup
  module JournalsHelper
    def up_journal_detail(detail, journal, options = {})
      formatter = journal.journalized.up_journalized_options[:detail_formatter]
      text = formatter&.call(detail, journal)
      return text if text

      label, old_value, value = up_journal_detail_values(detail, journal)
      text =
        if detail.old_value.blank? && detail.value.present?
          l(:text_journal_set_to, label: label, value: value)
        elsif detail.value.blank?
          l(:text_journal_deleted, label: label, old: old_value)
        else
          l(:text_journal_changed, label: label, old: old_value, new: value)
        end
      options[:no_html] ? text : text.html_safe
    end

    def up_render_journal_history(journals, show_notes: true)
      render partial: 'redmineup/journals/history', locals: { journals: journals, show_notes: show_notes }
    end

    def up_journal_new_markup?
      Gem::Version.new(Redmine::VERSION.to_s) >= Gem::Version.new('6.1')
    end

    private

    def up_journal_detail_values(detail, journal)
      record = journal.journalized
      if detail.property == 'cf'
        field = CustomField.find_by(id: detail.prop_key)
        return [h(detail.prop_key), h(detail.old_value), h(detail.value)] unless field

        format = ->(v) { v.blank? ? '' : field.format.formatted_value(self, field, v, record, false) }
        [h(field.name), h(format.call(detail.old_value)), h(format.call(detail.value))]
      else
        key = detail.prop_key.to_s
        name = key.delete_suffix('_id')
        reflection = record.class.reflect_on_association(name) if name != key
        format = lambda do |v|
          next '' if v.blank?
          next v.to_s unless reflection

          target = reflection.klass.find_by(id: v)
          target && (!target.respond_to?(:visible?) || target.visible?) ? target.to_s : v.to_s
        end
        [h(l("field_#{key}", default: l("field_#{name}", default: name.humanize))), h(format.call(detail.old_value)), h(format.call(detail.value))]
      end
    end
  end
end
