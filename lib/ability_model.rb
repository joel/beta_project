# frozen_string_literal: true

module AbilityModel
  module_function

  def ability(ability)
    mapping[ability.to_s] || []
  end

  def mapping
    @mapping ||= begin
      mapping_path = Pathname.new(Rails.root.join('config/ability_mapping.json'))
      JSON.load(mapping_path)
    end
  end

end
