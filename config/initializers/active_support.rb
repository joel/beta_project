require "active_support"

ActiveSupport::Dependencies.warnings_on_first_load = true

ActiveSupport::Dependencies.singleton_class.prepend(Module.new do
  def load_missing_constant(*args)

    Rails.logger.debug "#{__method__}(#{args.map(&:inspect).join(', ')})"

    super
  end
end)
