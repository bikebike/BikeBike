Bike!Bike!
===========

This is a starter web application based on the following technology stack:

* [Ruby 2][1]
* [Rails 4.0.0][2]
* [PostgreSQL][3]
* [RSpec][4]
* [Twitter Bootstrap 2.3.2][5]
* [Font Awesome 3.2.1][6]
* [HAML][7]

[1]: http://www.ruby-lang.org/en/
[2]: http://rubyonrails.org/
[3]: http://www.postgresql.org/
[4]: http://rspec.info/
[5]: http://twitter.github.com/bootstrap/
[6]: http://fontawesome.io/
[7]: http://haml.info/

Starter App is deployable on [Heroku](http://www.heroku.com/). Demo: http://ruby2-rails4-bootstrap-heroku.herokuapp.com/

```Gemfile``` also contains a set of useful gems for performance, security, api building...

### Nitrous.IO

Starter App supports online development on [Nitrous.IO](http://www.nitrous.io).

You need:
* A Nitrous.IO box with **at least** 512MB of memory.
* Two "Dev Plan" heroku databases (one for development and one for test)
* The following environment variables on your Nitrous.IO box's `.bashrc`:
  ```bash
  export STARTER_APP_DEV_DB_DATABASE=YOUR_DEV_DB_DATABASE
  export STARTER_APP_DEV_DB_USER=YOUR_DEV_DB_USER
  export STARTER_APP_DEV_DB_PASSWORD=YOUR_DEV_DB_PASSWORD
  export STARTER_APP_DEV_DB_HOST=YOUR_DEV_DB_HOST
  export STARTER_APP_DEV_DB_PORT=YOUR_DEV_DB_PORT

  export STARTER_APP_TEST_DB_DATABASE=YOUR_TEST_DB_DATABASE
  export STARTER_APP_TEST_DB_USER=YOUR_TEST_DB_USER
  export STARTER_APP_TEST_DB_PASSWORD=YOUR_TEST_DB_PASSWORD
  export STARTER_APP_TEST_DB_HOST=YOUR_TEST_DB_HOST
  export STARTER_APP_TEST_DB_PORT=YOUR_TEST_DB_PORT
  ```

A guide for creating heroku databases and edit `.bashrc` on Nitrous.IO is available here: http://help.nitrous.io/postgres/
