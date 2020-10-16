# frozen_string_literal: true

class ApiCapability2
  include CanCan::Ability

  def initialize(doorkeeper_token)
    can [:details], User if authorize_if_got_token!(doorkeeper_token, [:read, :public])
    
=begin
    if Settings.status != "database_offline"
      can [:create, :comment, :close, :reopen], Note if capability?(token, :allow_write_notes)
      can [:show, :data], Trace if capability?(token, :allow_read_gpx)
      can [:create, :update, :destroy], Trace if capability?(token, :allow_write_gpx)
      can [:details], User if capability?(token, :allow_read_prefs)
      can [:gpx_files], User if capability?(token, :allow_read_gpx)
      can [:index, :show], UserPreference if capability?(token, :allow_read_prefs)
      can [:update, :update_all, :destroy], UserPreference if capability?(token, :allow_write_prefs)

      if token&.user&.terms_agreed?
        can [:create, :update, :upload, :close, :subscribe, :unsubscribe], Changeset if capability?(token, :allow_write_api)
        can :create, ChangesetComment if capability?(token, :allow_write_api)
        can [:create, :update, :delete], Node if capability?(token, :allow_write_api)
        can [:create, :update, :delete], Way if capability?(token, :allow_write_api)
        can [:create, :update, :delete], Relation if capability?(token, :allow_write_api)
      end

      if token&.user&.moderator?
        can [:destroy, :restore], ChangesetComment if capability?(token, :allow_write_api)
        can :destroy, Note if capability?(token, :allow_write_notes)
        if token&.user&.terms_agreed?
          can :redact, OldNode if capability?(token, :allow_write_api)
          can :redact, OldWay if capability?(token, :allow_write_api)
          can :redact, OldRelation if capability?(token, :allow_write_api)
        end
      end
    end
=end    
  end

  private

  def authorize_if_got_token!(doorkeeper_token, *scopes)
    doorkeeper_token&.acceptable?(*scopes)
  end  
end
