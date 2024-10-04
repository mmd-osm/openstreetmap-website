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

  def trace_picture(trace, options = {})
    if trace.image.content_type == "image/svg+xml"
      content_tag(:div, "", :class => "trace-picture", :"data-gpx-file" => trace_picture_path(trace.user, trace).to_s)

    else
      options[:class] ||= "trace_image"
      options[:alt] ||= ""

      image_tag trace_picture_path(trace.user, trace),
                options.merge(:size => 250)
    end
  end
end
