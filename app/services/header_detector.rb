class HeaderDetector
  FIELD_ALIASES = {
    scheduled_at: [
      "date",
      "scheduled date",
      "posting date",
      "publish date",
      "publication date",
      "scheduled at",
      "datetime",
      "date and time"
    ],

    platform: [
      "platform",
      "social media",
      "social network",
      "channel",
      "social platform"
    ],

    caption: [
      "caption",
      "post content",
      "content",
      "copy",
      "post copy",
      "text"
    ],

    title: [
      "title",
      "post title",
      "subject",
      "headline"
    ],

    scheduled_time: [
      "time",
      "posting time",
      "publish time",
      "scheduled time"
    ]
  }.freeze

  def self.normalize(header)
    header.to_s
          .strip
          .downcase
          .gsub(/[_-]+/, " ")
          .gsub(/\s+/, " ")
  end

  def self.detect(headers)
    headers.each_with_object({}) do |header, matches|
      normalized = normalize(header)

      FIELD_ALIASES.each do |field, aliases|
        if aliases.include?(normalized)
          matches[field] ||= header
          break
        end
      end
    end
  end
end