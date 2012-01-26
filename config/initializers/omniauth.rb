#require 'net/http'
Rails.application.config.middleware.use OmniAuth::Builder do
  #configure do |config|
  #  config.on_failure = Proc.new do |env|
  #    message_key = env['omniauth.error.type']
  #    new_path = "#{env['SCRIPT_NAME']}#{OmniAuth.config.path_prefix}/failure?message=#{message_key}"
  #    [302, {'Location' => new_path, 'Content-Type'=> 'text/html'}, []]
  #  end
  #end
  provider :shibboleth, {:uid_field => 'uid'}
  #provider :cas, {:cas_server => 'http://localhost:8443', :disable_ssl_verification => true}
end
