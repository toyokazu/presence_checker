# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
#run PresenceChecker::Application
map ENV["RAILS_RELATIVE_URL_ROOT"] || "/" do
  run PresenceChecker::Application
end
