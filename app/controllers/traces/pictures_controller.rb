module Traces
  class PicturesController < ApplicationController
    before_action :authorize_web
    before_action :check_database_readable

    authorize_resource :trace

    def show
      id = params[:trace_id]
      trace = Trace.visible.find(id)

      if trace.public? || (current_user && current_user == trace.user)
        head :forbidden if Acl.no_trace_download(request.remote_ip)

        max_lat = Tracepoint.where(:trace => id).maximum(:latitude)
        min_lat = Tracepoint.where(:trace => id).minimum(:latitude)
        max_lon = Tracepoint.where(:trace => id).maximum(:longitude)
        min_lon = Tracepoint.where(:trace => id).minimum(:longitude)

        max_lat = max_lat.to_f / 10000000
        min_lat = min_lat.to_f / 10000000
        max_lon = max_lon.to_f / 10000000
        min_lon = min_lon.to_f / 10000000

        svg = to_svg(min_lat, min_lon, max_lat, max_lon, trace.points)

        send_data(svg, :file => "#{trace.id}.svg", :type => "image/svg+xml", :disposition => "inline")

      else
        head :not_found
      end
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    private

    def to_svg(min_lat, min_lon, max_lat, max_lon, points)
      nframes = 10
      max_pixels = 250

      points_per_frame = (points.count.to_f / nframes).ceil

      proj = OSM::MercatorSVG.new

      index = 1
      oldpx = 0.0
      oldpy = 0.0

      projected_points = points.map do |p|
        proj.mercator_projection(p.longitude.to_f / 10000000, p.latitude.to_f / 10000000)
      end

      width, height = proj.extent_of_projected_data(projected_points)
      mapped_points = proj.calc_zero_based_data(projected_points)
      scale = proj.calc_scale_factor(width, height, max_pixels)

      result = %(<svg width="#{width * scale}" height="#{height * scale}" viewBox="0 0 #{width * scale} #{height * scale}")
      result << %( version="1.1" id="icon" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg">)
      result << '<metadata xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dct="http://purl.org/dc/terms/">'
      result << "<dct:spatial>"
      result << '<Box projection="EPSG:4326" name="GPX Trace">'
      result << %(<northlimit>#{max_lat}</northlimit>)
      result << %(<eastlimit>#{max_lon}</eastlimit>)
      result << %(<southlimit>#{min_lat}</southlimit>)
      result << %(<westlimit>#{min_lon}</westlimit>)
      result << "</Box></dct:spatial></metadata>"

      result << '<g id="gpx" fill="none" stroke="gray">'

      mapped_points.each_slice(points_per_frame) do |a|
        result << %(<path id="path#{index}" d=")
        result << "m#{oldpx.round(5)},#{oldpy.round(5)}" if index > 1
        a.each_with_index do |p, pt|
          px, py = proj.scale_coords(p, height, scale)
          result << (index == 1 && pt.next == 1 ? "m" : "L")
          result << "#{px.round(5)},#{py.round(5)}"
          oldpx = px
          oldpy = py
        end
        result << '"/>'
        index += 1
      end

      result << "</g></svg>"
    end
  end
end
