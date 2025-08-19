class OldRelationMembersController < OldElementsController
  include BrowseHelper

  def show
    @type = "relation"
    @current_feature = Relation.find(params[:id])
    @feature = OldRelation.preload(:old_members => :member).find([params[:id], params[:version]])
    @frame_id = "member_relation_#{@feature.id}"

    return deny_access(nil) if @feature.redacted? && !params[:show_redactions]

    prefetch_member_tags(@feature)

    render :partial => "browse/relation_member_frame", :locals => { :relation => @feature, :frame_id => @frame_id }
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end
end
