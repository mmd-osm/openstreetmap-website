class RelationMembersController < ElementsController
  include BrowseHelper

  def show
    @type = "relation"
    @feature = Relation.preload(:relation_members => :member).find(params[:id])
    @frame_id = "member_relation_#{@feature.id}"

    prefetch_member_tags(@feature)

    render :partial => "browse/relation_member_frame", :locals => { :relation => @feature, :frame_id => @frame_id }
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end
end
