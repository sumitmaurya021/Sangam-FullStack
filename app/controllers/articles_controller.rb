class ArticlesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_article, only: [:show, :edit, :update, :destroy]
  before_action :authorize_article_owner!, only: [:edit, :update, :destroy]

  def index
    @articles = Article.published.recent.includes(:user, :rich_text_content, cover_image_attachment: :blob)
  end

  def show
    @article.increment!(:views_count) unless current_user == @article.user
  end

  def new
    @article = current_user.articles.build
  end

  def create
    @article = current_user.articles.build(article_params)
    if @article.save
      redirect_to @article, notice: 'Article was successfully published.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @article.update(article_params)
      redirect_to @article, notice: 'Article was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy
    redirect_to articles_url, notice: 'Article was successfully deleted.'
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def authorize_article_owner!
    redirect_to articles_path, alert: 'You are not authorized to edit this article.' unless @article.user_id == current_user.id
  end

  def article_params
    params.require(:article).permit(:title, :content, :cover_image, :published)
  end
end
