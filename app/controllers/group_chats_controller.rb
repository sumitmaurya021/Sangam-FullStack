class GroupChatsController < ApplicationController
  before_action :set_group_chat, only: [:show, :destroy, :add_member, :remove_member, :leave]
  before_action :require_member!, only: [:show]
  before_action :require_admin!,  only: [:add_member, :remove_member]
  before_action :require_owner!,  only: [:destroy]

  # GET /group_chats
  def index
    @group_chats = current_user.group_chats
                               .recent_activity
    @direct_conversations = current_user.conversations
                                        .includes(:sender, :recipient)
  end

  # GET /group_chats/:id
  def show
    @messages = @group_chat.group_chat_messages
                            .visible
                            .includes(:user, attachment_attachment: :blob)
                            .recent
                            .last(50)
    @members = @group_chat.group_chat_members.includes(:user)
  end

  # POST /group_chats
  def create
    @group_chat = GroupChat.new(group_chat_params)
    @group_chat.owner = current_user

    if @group_chat.save
      # Add selected members
      member_ids = params[:member_ids].to_a.map(&:to_i).uniq
      User.where(id: member_ids).each do |user|
        next if user == current_user
        @group_chat.add_member!(user)
      end

      respond_to do |format|
        format.html { redirect_to group_chat_path(@group_chat), notice: 'Group chat created!' }
        format.json { render json: group_chat_json(@group_chat), status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: group_chats_path, alert: @group_chat.errors.full_messages.join(', ') }
        format.json { render json: { errors: @group_chat.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /group_chats/:id
  def destroy
    @group_chat.destroy
    redirect_to group_chats_path, notice: 'Group deleted.'
  end

  # POST /group_chats/:id/add_member
  def add_member
    user = User.find(params[:user_id])
    @group_chat.add_member!(user)

    respond_to do |format|
      format.html { redirect_back fallback_location: group_chat_path(@group_chat), notice: "#{user.name} added." }
      format.json { render json: { success: true, member: member_json(user) } }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_back fallback_location: group_chat_path(@group_chat), alert: 'User not found.' }
      format.json { render json: { error: 'User not found' }, status: :not_found }
    end
  end

  # DELETE /group_chats/:id/remove_member
  def remove_member
    user = User.find(params[:user_id])
    return render_forbidden if user == @group_chat.owner

    @group_chat.remove_member!(user)

    respond_to do |format|
      format.html { redirect_back fallback_location: group_chat_path(@group_chat), notice: "#{user.name} removed." }
      format.json { render json: { success: true } }
    end
  end

  # DELETE /group_chats/:id/leave
  def leave
    return redirect_to group_chats_path, alert: "Owner can't leave — delete the group instead." if @group_chat.owner == current_user

    @group_chat.remove_member!(current_user)
    redirect_to group_chats_path, notice: 'You left the group.'
  end

  private

  def set_group_chat
    @group_chat = GroupChat.find(params[:id])
  end

  def require_member!
    unless @group_chat.member?(current_user)
      redirect_to group_chats_path, alert: 'You are not a member of this group.'
    end
  end

  def require_admin!
    unless @group_chat.admin?(current_user)
      render_forbidden
    end
  end

  def require_owner!
    unless @group_chat.owner == current_user
      render_forbidden
    end
  end

  def render_forbidden
    respond_to do |format|
      format.html { redirect_back fallback_location: group_chats_path, alert: 'Not authorized.' }
      format.json { render json: { error: 'Forbidden' }, status: :forbidden }
    end
  end

  def group_chat_params
    params.require(:group_chat).permit(:name, :description, :avatar)
  end

  def group_chat_json(gc)
    {
      id:           gc.id,
      name:         gc.name,
      description:  gc.description,
      members_count: gc.members_count,
      owner_id:     gc.owner_id,
      avatar_url:   gc.avatar.attached? ? url_for(gc.avatar) : nil,
      created_at:   gc.created_at.iso8601
    }
  end

  def member_json(user)
    {
      id:     user.id,
      name:   user.name,
      avatar: user.avatar.attached? ? url_for(user.avatar) : nil,
      online: user.online
    }
  end
end
