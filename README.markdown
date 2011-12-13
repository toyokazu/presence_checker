# Presence Checker

Presence Cheker checks students presence by authenticating user using Single Sign On (SSO) and source IP address. It can be used with Moodle to omitting user information input (However if you do not federate Moodle with SSO, user must be authenticated twice by Moodle and SSO).


## Installation

You can checkout latest version from github.com

    ### clone latest commit
    % git clone git://github.com/toyokazu/presence_checker.git
    ### change place to application directory
    % cd presence_checker

This application requires the following Gems:

bundle >= 1.0.0
rails >= 3.0.0 (rails, activesupport, activerecord, actionpack)
omniauth >= 1.0.0
omniauth-shibboleth >= 1.0.0

About installation of RubyGems, refer the URL below:
(http://docs.rubygems.org/read/chapter/3)

After installing RubyGems and bundle gem, you can install required gems by the command below:

    % bundle install


## Application configuration

    % cp config/app_config.yml.sample config/app_config.yml

then edit admin user name (admin) and source network addresses (networks) where you want to permit presence registrations.

## DB configuration

If you use SQLite3 as a repository, just copy config/database.yml.sample to config/database.yml.

    % cp config/database.yml.sample config/database.yml

Then initalize database,

    % rake db:migrate

You can create initial data by using db/seeds.rb script.

    ### edit seeds.rb
    % vi db/seeds.rb
    ### then apply seeds.rb
    % rake db:seed


## Starting server and Shibboleth configuration

For testing, just use WEBrick.

    % script/server

and access http://localhost:3000/.

For production, omniauth (Shibboleth strategy) requires that Shibboleth SP provides attributes via environment variables. Currently we can do it by using Phusion Passenger as an application container.

    ### example httpd.conf configuration
    % sudo vi /etc/apache2/httpd.conf
    <Directory "/Library/WebServer/Documents">
    ...
        Options FollowSymLinks
    ...
    </Directory>
    ### Virtual Host and Passenger Settings
    PassengerRoot /Users/username/.rvm/gems/ruby-1.9.2-p290/gems/passenger-3.0.11
    PassengerRuby /Users/username/.rvm/wrappers/ruby-1.9.2-p290/ruby
    PassengerMaxPoolSize 10
    PassengerUser username
    PassengerGroup groupname
    
    ### example SSL configuration
    <VirtualHost _default_:443>
    ...
      RackBaseURI /presence_checker
      <Directory /Library/WebServer/Documents/presence_checker>
        Options -MultiViews
      </Directory>
    
    </VirtualHost>

    ### create a link to public directory of the rails project    
    % ln -s /Users/username/rails-apps/presence_checker/public /Library/WebServer/Documents/presence_checker
    
    ### example mod_shib configuration
    LoadModule mod_shib /opt/local/lib/shibboleth/mod_shib_22.so
    <IfModule mod_alias.c>
      <Location /shibboleth-sp>
        Allow from all
      </Location>
      Alias /shibboleth-sp/main.css /opt/local/share/doc/shibboleth-2.4.1/main.css
      Alias /shibboleth-sp/logo.jpg /opt/local/share/doc/shibboleth-2.4.1/logo.jpg
    </IfModule>
    ### protect /auth/shibboleth/callback for omniauth
    <Location /presence_checker/auth/shibboleth/callback>
      AuthType shibboleth
      ShibRequestSetting requireSession 1
      require valid-user
    </Location>

User login name (uid) is provided as request.env["omniauth"]["uid"] by OmniAuth. The default setting of the Shibboleth attribute name used as the user login name (uid) is "eppn". If you want to change the Shibboleth attribute name, edit omniauth.rb.

    ### change :uid_field option if needed
    % vi config/initializers/omniauth.rb
      provider :shibboleth, {:uid_field => 'uid'}

OmniAuth seems not to handle Phusion Passenger 'sub uri' for failure path (/auth/failure). So thus, the configuration as the following should be added to the omniauth.rb.

    configure do |config|
      config.on_failure = Proc.new do |env|
        message_key = env['omniauth.error.type']
        new_path = "#{env['SCRIPT_NAME']}#{OmniAuth.config.path_prefix}/failure?message=#{message_key}"
        [302, {'Location' => new_path, 'Content-Type'=> 'text/html'}, []]
      end
    end


## Collaborate with Moodle

1.  Create web link to URL https://pchecker-host/pchecker-path/presences/new
at Moodle course by setting "extended parameters" named as follows:

        * login = User - User Name
        * name = User - Sir & Given Name
        * mail = User - Mail Address
        * moodle_course_id = Course - id

  Set window configuration to 'open new window' and window size (width, height) = (800, 600) may be better for the usability.

2.  Create course at Presence Checker
(access URL https://pchecker-host/pchecker-path/courses/new)
The new course should have the moodle_course_id of your course.


## Use without Moodle

You can also register presence without Moodle.
In this case, students must input their profiles manually.
This function is basiclly for the students unregistered to the Moodle.

