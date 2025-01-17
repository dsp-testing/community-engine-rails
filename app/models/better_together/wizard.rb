# app/models/better_together/wizard.rb
module BetterTogether
  class Wizard < ApplicationRecord
    include FriendlySlug
    include Protected

    slugged :identifier

    has_many :wizard_step_definitions, -> { ordered }, dependent: :destroy
    has_many :wizard_steps, dependent: :destroy

    validates :name, presence: true
    validates :identifier, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
    validates :max_completions, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :current_completions, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    

    # Additional logic and methods as needed

    def limited_completions?
      max_completions.positive?
    end

    def mark_completed
      return if current_completions == max_completions
      
      self.current_completions += 1
      self.last_completed_at = DateTime.now
      self.first_completed_at = DateTime.now if self.first_completed_at.nil?

      save
    end

    def completed?
      # TODO: Adjust for wizards with multiple possible completions
      completed = wizard_steps.size == wizard_step_definitions.size &&
        wizard_steps.ordered.all?(&:completed)

      mark_completed
      completed
    end
  end
end
