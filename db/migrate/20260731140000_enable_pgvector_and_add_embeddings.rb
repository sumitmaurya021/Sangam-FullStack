class EnablePgvectorAndAddEmbeddings < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    safety_enable_vector_extension

    if vector_extension_available?
      add_column :posts, :embedding, :vector, limit: 384 unless column_exists?(:posts, :embedding)
      add_column :articles, :embedding, :vector, limit: 384 unless column_exists?(:articles, :embedding)
      add_column :marketplace_listings, :embedding, :vector, limit: 384 unless column_exists?(:marketplace_listings, :embedding)
    else
      add_column :posts, :embedding_data, :text unless column_exists?(:posts, :embedding_data)
      add_column :articles, :embedding_data, :text unless column_exists?(:articles, :embedding_data)
      add_column :marketplace_listings, :embedding_data, :text unless column_exists?(:marketplace_listings, :embedding_data)
    end
  end

  private

  def safety_enable_vector_extension
    execute("CREATE EXTENSION IF NOT EXISTS vector;")
  rescue => e
    Rails.logger.warn("pgvector extension not installed in PG: #{e.message}")
  end

  def vector_extension_available?
    res = select_value("SELECT 1 FROM pg_extension WHERE extname = 'vector';")
    res.to_i == 1
  rescue
    false
  end
end
