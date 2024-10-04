module TraceHelper
  def link_to_tag(tag)
    link_to(tag, :tag => tag, :page => nil)
  end

  def trace_icon(trace, options = {})
    options[:class] ||= "trace_image"
    options[:alt] ||= ""

    image_tag trace_icon_path(trace.user, trace),
              options.merge(:size => 50)
  end

  def trace_picture(trace, _options = {})
    # use on-the-fly image generation endpoint instead
    content_tag(:div, "", :id => "trace-map", :"data-gpx-file" => trace_picture_path(trace.user, trace).to_s)
  end
end
