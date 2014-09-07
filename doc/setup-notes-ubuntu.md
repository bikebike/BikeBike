I got my application running on ubuntu. Here are my notes:

Prerequisites:

* rvm installed with ruby 2.0.0
* bundler installed
* postgres installed

Switch to ruby 2.0.0 and install gems: 

    rvm use 2.0.0
    bundle install

Create a postgres user (with db create permissions but no user create permissions):

      sudo -u postgres createuser -d -A -P username

Resources for postgres on ubuntu: 

* https://help.ubuntu.com/community/PostgreSQL
* http://www.davidpashley.com/articles/postgresql-user-administration/


Setup the database credentials for the application:

* Create a folder named "secure" outside of rails root
* Copy config/database.yml to /secure/database.yml
* Configure the database.yml with your database name, user name and password

Database setup (develpment and test):

    bundle exec rake db:create
    bundle exec rake db:schema:load
    RAILS_ENV=test  bundle exec rake db:schema:load

Run the tests:

      bundle exec cucumber features
      bundle exec rspec spec


  
