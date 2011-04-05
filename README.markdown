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

About installation of RubyGems, refer the URL below:
(http://docs.rubygems.org/read/chapter/3)

After installing RubyGems and bundle gem, you can install required gems by the command below:

    % bundle install

Update 'oa-enterprise' gem to the Shibboleth supported version.

    % cd ../
    % git clone https://github.com/toyokazu/omniauth.git
    % cd omniauth/oa-enterprise
    % bundle install
    % rake gem
    % gem install dist/oa-enterprise-0.2.0.gem


## Application configuration

    % cp config/app_config.yml.sample config/app_config.yml

and edit source network addresses where you want to permit presence registrations.

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


## Starting server

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
    PassengerRoot /Users/username/.rvm/gems/ruby-1.9.2-head/gems/passenger-3.0.4
    PassengerRuby /Users/groupname/.rvm/wrappers/ruby-1.9.2-head/ruby
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


## Collaborate with Moodle

1.  Create web link to URL https://pchecker-host/pchecker-path/presences/new
at Moodle course by setting "extended parameters" named as follows:

        * login = User - User Name
        * name = User - Sir & Given Name
        * mail = User - Mail Address
        * moodle_course_id = Course - id

  Assumed new window size (width, height) = (800, 600) for default css (precense_checker.css).

2.  Create course at Presence Checker
(access URL https://pchecker-host/pchecker-path/courses/new)
The new course should have the moodle_course_id of your course.


## Use without Moodle

You can also register presence without Moodle.
In this case, students must input their profiles manually.
This function is basiclly for the students unregistered to the Moodle.

