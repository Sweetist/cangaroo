module Cangaroo
  class Connection < ActiveRecord::Base
    serialize :parameters

    validates :name, presence: true, uniqueness: true
    validates :url, :token, presence: true
    validates :key, presence: true, if: -> { !Rails.configuration.cangaroo.basic_auth }

    after_initialize :set_default_parameters

    def self.authenticate(key, token)
      where(key: key, token: token).first
    end

    private

    def set_default_parameters
      self.parameters ||= {}
    end
  end
end
