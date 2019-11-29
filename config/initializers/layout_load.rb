class LayoutHelper
  layout = SITE_CONFIG[:layout] || 'default'

  BEF_LAYOUT = layout
  LAYOUT_IS_DEFAULT = (layout == 'default')
end
