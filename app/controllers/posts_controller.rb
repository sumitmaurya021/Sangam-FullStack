class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :authorize_post!, only: [:edit, :update, :destroy]

  POSTS_PER_PAGE = 5

  def index
    friend_ids = current_user.all_friends.pluck(:id)

    if friend_ids.any?
      @posts = Post.ranked_feed(current_user)
                   .page(params[:page])
                   .per(POSTS_PER_PAGE)
    else
      @posts = Post.visible_to(current_user)
                   .includes(:user, :likes, :comments, :shares)
                   .order(created_at: :desc)
                   .page(params[:page])
                   .per(POSTS_PER_PAGE)
    end

    @post  = Post.new
    @users = User.where.not(id: current_user.id).order("RANDOM()").limit(10)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          posts_html: render_to_string(partial: 'posts/post_card', collection: @posts, as: :post, formats: [:html]),
          next_page:   @posts.next_page,
          total_pages: @posts.total_pages
        }
      end
    end
  end

  def show
    @comments = @post.comments.top_level.includes(:user, :replies => :user).recent
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      respond_to do |format|
        format.html { redirect_to posts_path, notice: 'Post created successfully!' }
        format.turbo_stream
      end
    else
      @posts = Post.visible_to(current_user)
                   .includes(:user, :likes, :comments, :shares)
                   .order(created_at: :desc)
                   .page(1)
                   .per(POSTS_PER_PAGE)
      @users = User.where.not(id: current_user.id).limit(10)
      render :index, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @post.update(post_params.merge(edited_at: Time.current))
      respond_to do |format|
        format.html { redirect_to posts_path, notice: 'Post updated!' }
        format.turbo_stream
        format.json { render json: { success: true } }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    respond_to do |format|
      format.html { redirect_to posts_path, notice: 'Post deleted.' }
      format.turbo_stream
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def authorize_post!
    unless @post.user == current_user
      respond_to do |format|
        format.html { redirect_to posts_path, alert: 'Not authorized.' }
        format.json { render json: { error: 'Not authorized' }, status: :forbidden }
      end
    end
  end

  def post_params
    params.require(:post).permit(:content, :image, :visibility, images: [])
  end
end
