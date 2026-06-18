class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :authorize_post!, only: [:edit, :update, :destroy]

  POSTS_PER_PAGE = 5

  def index
    @posts = FeedRankingService.new(current_user).get_feed(params[:page], POSTS_PER_PAGE)

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

    # Stimulus cancel button fetches /posts/:id via XHR and extracts the card
    if request.xhr?
      render partial: "posts/post_card", locals: { post: @post }
    else
      respond_to do |format|
        format.html
        format.json { render json: { success: true } }
      end
    end
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      # Schedule publishing job if needed
      if @post.scheduled_at.present? && !@post.published?
        PublishScheduledPostJob.set(wait_until: @post.scheduled_at).perform_later(@post.id)
      end

      respond_to do |format|
        format.html { redirect_to posts_path, notice: @post.scheduled? ? 'Post scheduled!' : 'Post created successfully!' }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html do
          @posts = Post.visible_to(current_user)
                       .includes(:user, :likes, :comments, :shares)
                       .order(created_at: :desc)
                       .page(1)
                       .per(POSTS_PER_PAGE)
          @users = User.where.not(id: current_user.id).limit(10)
          render :index, status: :unprocessable_entity
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "create-post-form-wrapper",
            partial: "posts/create_post_form",
            locals:  { post: @post }
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    # XHR requests (from Stimulus inline-edit) get the partial directly
    if request.xhr?
      render partial: "posts/inline_edit_form", locals: { post: @post }
    else
      # Normal browser navigation: render the standalone edit page
      render :edit
    end
  end

  def update
    if @post.update(post_params.merge(edited_at: Time.current))
      respond_to do |format|
        format.html { redirect_to posts_path, notice: 'Post updated!' }
        format.turbo_stream
        format.json { render json: { success: true } }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "post-#{@post.id}",
            partial: "posts/inline_edit_form",
            locals:  { post: @post }
          ), status: :unprocessable_entity
        end
      end
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
    params.require(:post).permit(
      :content, :image, :visibility, :scheduled_at, :published,
      :link_url, :link_title, :link_description, :link_image_url, :link_domain,
      :location_name, :latitude, :longitude,
      images: [],
      poll_attributes: [
        :question, :ends_at,
        poll_options_attributes: [:body, :position]
      ],
      fundraiser_attributes: [:title, :description, :goal_amount, :currency, :ends_at]
    )
  end
end
