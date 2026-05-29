class PostsController < ApplicationController
  before_action :set_post, only: [:destroy]

  POSTS_PER_PAGE = 5

  def index
    @posts = Post.includes(:user, :likes, :comments, :shares)
                 .order(created_at: :desc)
                 .page(params[:page])
                 .per(POSTS_PER_PAGE)
    @post = Post.new
    @users = User.where.not(id: current_user.id).limit(10)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          posts_html: render_to_string(partial: 'posts/post_card', collection: @posts, as: :post, formats: [:html]),
          next_page: @posts.next_page,
          total_pages: @posts.total_pages
        }
      end
    end
  end

  def create
    @post = current_user.posts.build(post_params)
    
    if @post.save
      redirect_to posts_path, notice: 'Post created successfully!'
    else
      @posts = Post.includes(:user, :likes, :comments, :shares)
                   .order(created_at: :desc)
                   .page(1)
                   .per(POSTS_PER_PAGE)
      @users = User.where.not(id: current_user.id).limit(10)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    if @post.user == current_user
      @post.destroy
      redirect_to posts_path, notice: 'Post deleted successfully!'
    else
      redirect_to posts_path, alert: 'You can only delete your own posts.'
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:content, :image, images: [])
  end
end
