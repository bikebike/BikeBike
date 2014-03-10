Bike!Bike!
===========

This is the development repository for Bike!Bike!

If you're about to get started contributing please contact Godwin: `goodgodwin``@``hotmail.com`. Also try to familiarize yourself with the [technologies](#technologies) we're using, our [collaboration tools](#collaboration-tools), [requirements](#requirements-overview), [coding conventions](#coding-conventions), [style guide](#style-guide).

### Technologies ###
-----

* [Ruby 2.0.0][1]
* [Rails 4.0.0][2]
* [PostgreSQL][3]
* [HAML][4]
* [Scss][7]
* [Compass][8]
* [Foundation][5]
* [CoffeeScript 1.7.1][6]
* [jQuery 1.11.0][9]

[1]: http://www.ruby-lang.org/en/
[2]: http://rubyonrails.org/
[3]: http://www.postgresql.org/
[4]: http://haml.info/
[5]: http://foundation.zurb.com/
[6]: http://coffeescript.org/
[7]: http://sass-lang.com/
[8]: http://compass-style.org/
[9]: http://jquery.com/


## Collaboration Tools ##
-----

* [Trello][10]
* [GitHub][11]
* [Google Hangouts][12]

[10]: https://trello.com/b/X4TGKQ1L/rails-tasks
[11]: https://github.com/bikebike/BikeBike
[12]: http://www.google.com/+/learnmore/hangouts/


## Requirements Overview ##
-----

Bike!Bike! is a conference which is held in and hosted by a different city each year. The conference is specifically for not for profit bicycle collectives (5013c or equivalent status is not required). There are also 'Reginal Bike!Bike!s' which can be hosted by any organization at any time of the year.

The Bike!Bike! website will help coordinate these conferences, allowing users to register, to create organizations, and organize conferences.

### Users ###
Users should be able to register and log in, either with our system or using Facebook. We will store user name, encrypted passwords, email addresses, avatars, and user settings.

### Organizations ###
An organization can be created by any user. An organization has a name, location, logo, email address, and some additional optional settings. An organization also contains a list of users which can interact and represent the organization on the site. A user is added to the organization by either:

1.	Creating the organization
2.	Requesting membership
3.	Being invited by an existing member

Organizations can be set up to allow anyone to become a member, require verification, require a secret password, or only allow invitations.

### Conferences ###

Conferences can be created by any user who is associated with an organization. A conference has a name, date, location, a list of host organizations, and optional administrators.

A conference can be modified by anyone who has been added as an administrator directly, or is a member of any of the host organizations.

### Registration ###
Any member of the site can register for a conference. A form must be constructed by the conference corrdinators and must then be completed by the registrant.

### Workshops ###
Any user who is register for a specific conference can propose workshops for that conference. A workshop is later scheduled by the conference coordinators if they decide to include it in the conference. A workshop can have one or more facilitators which are added in a similar process as users are added to an organization.


### Events ###
Events are created and scheduled by conference coordinators.


## Coding Conventions ##

### Ruby ###

### CoffeeScript ###

### Haml ###

### SCSS ###

### Translations ###

Translating our site into mutiple languages is a key part of opening it up to the world. When coding, never include any English text as in a string or Haml. Instead, we shall always use the underscore helper method `_`. The method takes a translation key and some optional parameters.

All translation is done in a collaborative, volunteer based system on the site itself, even the English text. If a user has sufficient permissions, the underscore method will produce highlighted text which can be edited directly by the user.

The method can be used as follows:

	_ 'basename.my_key'

	_ 'basename.my_key', :paragraph

	_ 'basename.my_key' do
		<input type="text" placeholder="_!" />
	end

If the key does not exist, the previos lines will produce the following respectively:

	'my_key'
	
	'Curabitur non nulla sit amet nisl tempus convallis quis ac lectus.
		Vivamus magna justo, lacinia eget consectetur sed, convallis at
		tellus. Proin eget tortor risus. Donec sollicitudin molestie
		malesuada. Donec rutrum congue leo eget malesuada.'

	<input type="text" placeholder="my_key" />

If the user has sufficient rights, these blocks will also be surrounded by the necessary markup to allow them to be selected and edited by the user.

### Style Guide ###

On hold until our design team determines a director for our identity.
