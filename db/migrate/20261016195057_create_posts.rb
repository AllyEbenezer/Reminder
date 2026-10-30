class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title
      t.string :platform
      t.datetime :scheduled_at
      t.text :caption
      t.string :reference_url
      t.string :status
      t.datetime :reminder_sent_at
      t.datetime :published_at

      t.timestamps
    end
  end
end
