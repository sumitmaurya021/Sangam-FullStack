class GroupsController < ApplicationController
  before_action :set_group, only: [:show, :edit, :update, :destroy, :join, :leave, :approve_member, :remove_member]
  before_action :authorize_admin!, only: [:edit, :update, :destroy, :approve_member, :remove_member]

  def index
    @my_groups       = current_user.groups.order(:name)
    @suggested_groups = Group.public_groups
                             .where.not(id: current_user.group_memberships.select(:group_id))
                             .order(members_count: :desc)
                             .limit(10)
  end

  def show
    @posts = @group.posts
                   .includes(:user, :likes, :comments)
                   .order(created_at: :desc)
                   .page(params[:page]).per(10)
    @members        = @group.group_memberships.active.includes(:user).limit(12)
    @pending_members = @group.group_memberships.pending.includes(:user) if @group.admin?(current_user)
    @is_member      = @group.member?(current_user)
    @is_admin       = @group.admin?(current_user)
    @new_post       = Post.new
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params.merge(owner: current_user))
    if @group.save
      redirect_to @group, notice: 'Group created!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @group.update(group_params)
      redirect_to @group, notice: 'Group updated!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @group.destroy
    redirect_to groups_path, notice: 'Group deleted.'
  end

  def join
    if @group.privacy == 'public'
      membership = @group.group_memberships.create!(user: current_user, role: 'member', status: 'active')
      render json: { joined: true, members_count: @group.reload.members_count }
    else
      # Private group — create pending membership
      @group.group_memberships.create!(user: current_user, role: 'member', status: 'pending')
      render json: { pending: true, message: 'Join request sent!' }
    end
  rescue ActiveRecord::RecordInvalid
    render json: { error: 'Already a member' }, status: :unprocessable_entity
  end

  def leave
    membership = @group.group_memberships.find_by(user: current_user)
    if membership && membership.role != 'owner'
      membership.destroy
      render json: { left: true, members_count: @group.reload.members_count }
    else
      render json: { error: 'Cannot leave' }, status: :unprocessable_entity
    end
  end

  def approve_member
    membership = @group.group_memberships.find_by(user_id: params[:user_id], status: 'pending')
    if membership&.update(status: 'active')
      render json: { approved: true }
    else
      render json: { error: 'Not found' }, status: :not_found
    end
  end

  def remove_member
    membership = @group.group_memberships.find_by(user_id: params[:user_id])
    if membership && membership.role != 'owner'
      membership.destroy
      render json: { removed: true }
    else
      render json: { error: 'Cannot remove' }, status: :unprocessable_entity
    end
  end

  private

  def set_group
    @group = Group.find(params[:id])
  end

  def authorize_admin!
    redirect_to groups_path, alert: 'Not authorized.' unless @group.admin?(current_user)
  end

  def group_params
    params.require(:group).permit(:name, :description, :privacy, :cover_photo, :avatar)
  end
end
