require 'rubyamf/rails/controller'
require 'rubyamf/rails/model'
require 'rubyamf/rails/request_processor'
require 'rubyamf/rails/routing'
require 'rubyamf/rails/time'
require 'action_controller'

# Hook up MIME type
Mime::Type.register RubyAMF::MIME_TYPE, :amf

# Hook routing into routes
ActionDispatch::Routing::Mapper.send(:include, RubyAMF::Rails::Routing)

# Add some utility methods to ActionController
ActionController::Base.send(:include, RubyAMF::Rails::Controller)

# Hook up ActiveRecord Model extensions
if defined?(ActiveRecord)
  ActiveRecord::Base.send(:include, RubyAMF::Rails::Model)
end

# Hook up rendering
ActionController::Renderers.add :amf do |amf, options|
  # Make sure Relation objects get converted to arrays so they serialize correctly
  if defined?(ActiveRecord) && amf.is_a?(ActiveRecord::Relation)
    amf = amf.to_a
  end

  @amf_response = amf
  @mapping_scope = options[:class_mapping_scope] || options[:mapping_scope] || nil
  self.content_type ||= Mime::AMF
  self.response_body = " "
end

# Add custom responder so respond_with works
class ActionController::Responder
  def to_amf
    display resource
  end
end

class RubyAMF::Railtie < Rails::Railtie #:nodoc:
  config.rubyamf = RubyAMF.configuration

  initializer "rubyamf.configured" do
    RubyAMF.bootstrap
  end

  initializer "rubyamf.middleware" do
    config.app_middleware.use RubyAMF::RequestParser
    config.app_middleware.use RubyAMF::Rails::RequestProcessor
  end
end