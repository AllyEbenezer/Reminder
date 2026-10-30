json.extract! post, :id, :title, :platform, :scheduled_at, :caption, :reference_url, :status, :reminder_sent_at, :published_at, :created_at, :updated_at
json.url post_url(post, format: :json)
