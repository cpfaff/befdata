# frozen_string_literal: true

class LayoutHelper
  layout = SITE_CONFIG[:layout] || 'standard'

  BEF_LAYOUT = layout
  LAYOUT_IS_DEFAULT = (layout == 'standard')
end
