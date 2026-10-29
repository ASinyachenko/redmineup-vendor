module Redmineup
  module Patches
    module Compatibility
      module SpritePatch
        def sprite_icon(icon_name, label = '', icon_only: false, size: '18', css_class: nil, sprite: "icons", plugin: nil, rtl: false)
          label
        end
      end
    end
  end
end

ApplicationHelper.prepend(Redmineup::Patches::Compatibility::SpritePatch)
