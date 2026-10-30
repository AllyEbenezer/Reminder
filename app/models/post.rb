
class Post < ApplicationRecord
  PLATFORMS = %w[X Instagram LinkedIn Facebook TikTok].freeze
  STATUSES = %w[planned ready published].freeze

  validates :title, presence: true
  validates :platform, inclusion: { in: PLATFORMS }
  validates :scheduled_at, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :upcoming, -> {
    where(status: %w[planned ready])
      .where("scheduled_at >= ?", Time.current)
      .order(:scheduled_at)
  }

  scope :overdue, -> {
    where(status: %w[planned ready])
      .where("scheduled_at < ?", Time.current)
      .order(:scheduled_at)
  }
end
