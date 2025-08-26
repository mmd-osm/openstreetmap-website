class LanguagesController < ApplicationController
  before_action :authorize_web
  before_action :set_locale
  authorize_resource :class => false

  def show
    @source_page = params[:source]
    render :partial => "layouts/select_language_list_frame"
  end
end
