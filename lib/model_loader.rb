# frozen_string_literal: true

require "set"

class ModelLoader

  cattr_accessor :models_loaded

  self.models_loaded = false

  cattr_writer :models

  self.models = Set.new

  class << self

    def models
      load_all_models

      @@models
    end

    def load_all_models
      perform_load_all_models unless models_loaded

      self.models_loaded = true
    end

    private

    def perform_load_all_models
      model_root_path = Pathname.new(Rails.root.join('app/models'))

      Dir["#{model_root_path}/**/*.rb"].each do |file|
        # Rescue anything we find in the models dir that isn't really an AR
        # model like a module
        begin
          absolute_path = Pathname.new(file)
          relative      = absolute_path.relative_path_from(model_root_path)
          klass_name    = relative.sub_ext('').to_s.classify

          constant = klass_name.safe_constantize

          if constant.is_a?(Class) && constant < ApplicationRecord
            @@models << constant
          end
        rescue StandardError, LoadError
          # ignored
        end
      end
    end

  end

end
