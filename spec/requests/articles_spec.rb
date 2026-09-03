require 'rails_helper'

RSpec.describe "Articles", type: :request do
  let(:user) { create(:user) }
  let!(:article) do
    create(:article, user: user,
      title: 'My Test Article Title',
      content: 'Some article content here',
      published: true
    )
  end

  describe "GET /articles" do
    it "returns http success" do
      sign_in user
      get articles_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /articles/:id" do
    it "returns http success for published article" do
      sign_in user
      get article_path(article)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /articles/new" do
    it "requires authentication" do
      get new_article_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "returns http success when signed in" do
      sign_in user
      get new_article_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /articles" do
    before { sign_in user }

    context "with valid parameters" do
      it "creates a new article and redirects" do
        expect {
          post articles_path, params: {
            article: {
              title: 'A New Article Title Here',
              content: 'Content of the article',
              published: true
            }
          }
        }.to change(Article, :count).by(1)
        expect(response).to redirect_to(article_path(Article.last))
      end
    end

    context "with invalid parameters" do
      it "does not create article and re-renders form" do
        expect {
          post articles_path, params: { article: { title: 'ab', content: '' } }
        }.not_to change(Article, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /articles/:id" do
    before { sign_in user }

    it "updates the article when owner" do
      patch article_path(article), params: { article: { title: 'Updated Title Here' } }
      expect(response).to redirect_to(article_path(article))
      expect(article.reload.title).to eq('Updated Title Here')
    end

    it "prevents non-owner from editing" do
      other_user = create(:user)
      sign_in other_user
      patch article_path(article), params: { article: { title: 'Hacked Title' } }
      expect(response).to redirect_to(articles_path)
    end
  end

  describe "DELETE /articles/:id" do
    before { sign_in user }

    it "deletes the article" do
      expect {
        delete article_path(article)
      }.to change(Article, :count).by(-1)
      expect(response).to redirect_to(articles_url)
    end
  end
end
