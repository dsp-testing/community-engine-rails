module BetterTogether
  class NavigationItem < ApplicationRecord
    include FriendlySlug
    include Protected

    slugged :title

    belongs_to :navigation_area
    belongs_to :linkable, polymorphic: true, optional: true

    # Association with parent item
    belongs_to :parent,
               class_name: 'NavigationItem',
               optional: true

    # Association with child items
    has_many :children,
             -> {
                ordered
              },
              class_name: 'NavigationItem',
              foreign_key: 'parent_id',
              dependent: :destroy

    # Define valid linkable classes
    LINKABLE_CLASSES = [
      '::BetterTogether::Page',
      'BetterTogether::Page'
    ].freeze

    validates :title, presence: true, length: { maximum: 255 }
    validates :url, format: { with: /\A(http|https):\/\/.+\z|\A#\z/, allow_blank: true, message: 'must be a valid URL or "#"' }
    validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :visible, inclusion: { in: [true, false] }
    validates :item_type, inclusion: { in: %w[link dropdown separator], allow_blank: true }
    validates :linkable_type, inclusion: { in: LINKABLE_CLASSES, allow_nil: true }

    scope :ordered, -> { order(:position) }

    # Scope to return top-level navigation items
    scope :top_level, -> { where(parent_id: nil) }

    scope :visible, -> { where(visible: true) }

    def child?
      parent_id.present?
    end

    def dropdown?
      item_type == 'dropdown'
    end

    def item_type
      return read_attribute(:item_type) if persisted? || read_attribute(:item_type).present?
      'link'
    end

    def position
      return read_attribute(:position) if persisted? || read_attribute(:position).present?

      max_position = self.navigation_area.navigation_items.maximum(:position)
      max_position ? max_position + 1 : 0
    end

    def url
      if linkable.present?
        linkable.url
      else
        _url = read_attribute(:url) # or super
        return _url if _url.present?
        '#'
      end
    end

    # Other validations and logic...
  end
end
