class Order < ApplicationRecord
  validates :customer_id, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :product_name, presence: true, length: { minimum: 2, maximum: 255 }
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending processing completed cancelled] }

  enum :status, {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    cancelled: 'cancelled'
  }, default: :pending

  scope :recent, -> { order(created_at: :desc) }
  scope :by_customer, ->(customer_id) { where(customer_id: customer_id) }
  scope :completed, -> { where(status: 'completed') }

  def total
    quantity * price
  end

  def as_json(options = {})
    super(options.merge(
      methods: [:total],
      except: [:updated_at]
    ))
  end
end
