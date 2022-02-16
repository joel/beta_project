# frozen_string_literal: true

class AbilityCheck

  class AbilityInconsistency < StandardError; end

  def check!
    model_root_path = Pathname.new(Rails.root.join('app/models'))

    AbilityModel.mapping.each do |ability, models|

      Dir["#{model_root_path}/**/*.rb"].each do |file|
        begin
          absolute_path = Pathname.new(file)
          relative      = absolute_path.relative_path_from(model_root_path)
          klass_name    = relative.sub_ext('').to_s.classify

          constant = klass_name.safe_constantize

          if constant.is_a?(Class) && constant < ApplicationRecord
            content = file_content(absolute_path.to_s)

            if content.include?(ability)
              unless models.include?("#{constant}")
                raise AbilityInconsistency, "MISSING MAPPING FOR [#{constant}]"
              end
            end

          end
        rescue LoadError
        end
      end

    end
  end

  private

  def file_content(file_path)
    @file_content ||= {}
    @file_content[file_path] ||= File.open(file_path, "r") { |f| f.read }
  end
end
