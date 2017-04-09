
module PageHelper
  @@no_banner = true
  @@banner_image = nil
  @@has_content = true
  @@body_class = nil

  def title(page_title)
    content_for(:title) { page_title.to_s }
  end

  def description(page_description)
    content_for(:description) { page_description.to_s }
  end

  def banner_image(banner_image, name: nil, id: nil, user_id: nil, src: nil)
    @@no_banner = false
    @@banner_image = banner_image
    content_for(:banner_image) { banner_image.to_s }
  end

  def has_content?
    @@has_content
  end

  def add_stylesheet(sheet)
    @stylesheets ||= []
    @stylesheets << sheet unless @stylesheets.include?(sheet)
  end

  def stylesheets
    html = ''
    Rack::MiniProfiler.step('inject_css') do
      html += inject_css!
    end
    (@stylesheets || []).each do |css|
      Rack::MiniProfiler.step("inject_css #{css}") do
        html += inject_css! css.to_s
      end
    end
    html += stylesheet_link_tag 'i18n-debug' if request.params['i18nDebug']
    return html.html_safe
  end

  def add_inline_script(script)
    @_inline_scripts ||= []
    script = Rails.application.assets.find_asset("#{script.to_s}.js").to_s
    @_inline_scripts << script unless @_inline_scripts.include?(script)
  end

  def inline_scripts
    return '' unless @_inline_scripts.present?
    "<script>#{@_inline_scripts.join("\n")}</script>".html_safe
  end

  def dom_ready(&block)
    content_for(:dom_ready, &block)
  end

  def body_class(c)
    @@body_class ||= Array.new
    @@body_class << (c.is_a?(Array) ? c.join(' ') : c)
  end

  def page_style
    classes = Array.new

    classes << 'no-content' unless @@has_content
    classes << 'has-banner-image' if @@banner_image
    classes << @@body_class.join(' ') if @@body_class

    if params[:controller]
      classes << params[:action]
      unless params[:controller] == 'application'
        classes << params[:controller] 

        if params[:action]
          classes << "#{params[:controller]}-#{params[:action]}"
        end
      end
    end
    return classes
  end

  def yield_or_default(section, default = '')
    content_for?(section) ? content_for(section) : default
  end
end
