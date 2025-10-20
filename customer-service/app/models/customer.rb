class Customer < ApplicationRecord
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :address, presence: true, length: { minimum: 5, maximum: 255 }
  validates :phone, format: { with: /\A\+?[\d\s\-\(\)]+\z/, allow_blank: true }
  validates :orders_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_save :normalize_email

  scope :active, -> { where('orders_count > 0') }
  scope :recent, -> { order(created_at: :desc) }

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end

  def as_json(options = {})
    super(options.merge(
      except: [:updated_at]
    ))
  end
end
