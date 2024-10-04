module Traces
  class PicturesController < ApplicationController
    before_action :authorize_web
    before_action :check_database_readable

    authorize_resource :trace

    NFRAMES = 10
    MAX_PIXELS = 250
    PRECISION = 5
    SCALE_FACTOR = 10000000

    def show
      id = params[:trace_id]
      trace = Trace.visible.find(id)

      if trace.public? || (current_user && current_user == trace.user)
        head :forbidden if Acl.no_trace_download?(request.remote_ip)

        points = trace.points.order(:timestamp).limit(100000).pluck(:latitude, :longitude)

        unless points.empty?
          min_lat, max_lat = points.collect(&:first).minmax
          min_lon, max_lon = points.collect(&:second).minmax

          max_lat = max_lat.to_f / SCALE_FACTOR
          min_lat = min_lat.to_f / SCALE_FACTOR
          max_lon = max_lon.to_f / SCALE_FACTOR
          min_lon = min_lon.to_f / SCALE_FACTOR

          svg = to_svg(min_lat, min_lon, max_lat, max_lon, points)
        end

        send_data(svg, :file => "#{trace.id}.svg", :type => "image/svg+xml", :disposition => "inline")

      else
        head :forbidden
      end
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    private

    def to_svg(min_lat, min_lon, max_lat, max_lon, points)
      proj = OSM::MercatorSVG.new

      points_per_frame = (points.size.to_f / NFRAMES).ceil

      projected_points = points.map do |lat, lon|
        proj.mercator_projection(lat.to_f / SCALE_FACTOR, lon.to_f / SCALE_FACTOR)
      end

      width, height = proj.extent_of_projected_data(projected_points)
      mapped_points = proj.calc_zero_based_data(projected_points)
      scale = proj.calc_scale_factor(width, height, MAX_PIXELS)

      result = %(<svg width="#{width * scale}" height="#{height * scale}" viewBox="0 0 #{width * scale} #{height * scale}")
      result << %( version="1.1" id="icon" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg">)
      result << svg_metadata(min_lat, min_lon, max_lat, max_lon)
      result << '<g id="gpx" fill="none" stroke="gray">'

      px = 0.0
      py = 0.0

      mapped_points.each_slice(points_per_frame).with_index do |a, index|
        result << %(<path id="path#{index + 1}" d=")
        # new path starts at last point of previous path
        result << "m#{px.round(PRECISION)},#{py.round(PRECISION)}" if index.positive?
        a.each_with_index do |(x, y), index2|
          px, py = proj.scale_coords(x, y, height, scale)
          op = index.zero? && index2.zero? ? "m" : "L"
          result << "#{op}#{px.round(PRECISION)},#{py.round(PRECISION)}"
        end
        result << '"/>'
      end
      result << "</g>"
      result << "</svg>"
    end

    def svg_metadata(min_lat, min_lon, max_lat, max_lon)
      result = '<metadata xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dct="http://purl.org/dc/terms/">'
      result << "<dct:spatial>"
      result << '<Box projection="EPSG:4326" name="GPX Trace">'
      result << %(<northlimit>#{max_lat}</northlimit>)
      result << %(<eastlimit>#{max_lon}</eastlimit>)
      result << %(<southlimit>#{min_lat}</southlimit>)
      result << %(<westlimit>#{min_lon}</westlimit>)
      result << "</Box></dct:spatial></metadata>"
      result
    end
  end
end
