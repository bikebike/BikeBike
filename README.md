Bike!Bike!
===========

This is the development repository for Bike!Bike! Progress can currently be seen at [preview.bikebike.org](https://preview-en.bikebike.org/) and in production at [bikebike.org](https://bikebike.org/)

If you're about to get started contributing please contact Godwin: `goodgodwin``@``hotmail.com`. Also try to familiarize yourself with the [technologies](#technologies) we're using, our [collaboration tools](#collaboration-tools), [requirements](#requirements-overview), [coding conventions](#coding-conventions), [style guide](#style-guide), and [testing practices](#testing-practices).

### Technologies ###

* [Ruby 2.0.0][1]
* [Rails 4.0.0][2]
* [PostgreSQL][3]
* [HAML][4]
* [SCSS][5]

[1]: http://www.ruby-lang.org/en/
[2]: http://rubyonrails.org/
[3]: http://www.postgresql.org/
[4]: http://haml.info/
[5]: http://sass-lang.com/


## Internal Gems ##
We will make a commitment to extract any functionality that makes sense to do so, into separate gems in order to share functionality with others, with our other projects (such as bikecollectives.org), and to enable easier collaboration amongst ourselves.

Here is a list of the gems we have created so far, if you are a collaborator on this project you may need to become a collaborator on these gems as well. Don't hesitate to make a request, it won't be denied:

### Lingua Franca ###

[Lingua Franca](https://github.com/lingua-franca/lingua_franca) provides an easy way to include translatable content and provides a user interface for translators to provide translations. See [Translations](#translations) for best practices on the Bike!Bike! website.

### Bumbleberry ###
[Bumbleberry](https://github.com/bumbleberry/bumbleberry) provides cross-browser support with little effort and minimum file sizes. Basically it creates a different stylesheet for every known browser and only includes supported rules for each using information obtained from [caniuse.com](caniuse.com).


## Collaboration Tools ##

* [Trello][6]
* [GitHub][7]
* [Google Hangouts][8]

[6]: https://trello.com/b/X4TGKQ1L/rails-tasks
[7]: https://github.com/bikebike/BikeBike
[8]: http://www.google.com/+/learnmore/hangouts/

## Github Workflow ##
If you are a git wiz, feel free to adjust the steps below slightly, otherwise follow these steps until you are familiar enough to stray. What should remain constant is that we need to branch, code review, and merge with master.

1. Before you start working on a new feature, start working on a new branch (alternatively you can fork): `git checkout -b myname_new_feature`
2. Write your new feature
3. Add tests and execute them using `bundle exec rake cucumber`
4. Make any adjustments, make sure you have included comments and abided other coding conventions
5. Check your git status to make sure you are on the correct branch and have any new files to add: `git status`
6. Add any new files using: `git add [myfile]`
7. Commit your changes: `git commit -am 'My commit message'`
8. Switch back to the master branch and pull the latest: `git checkout master && git pull`
9. Switch back to your branch: `git checkout myname_new_feature`
10. If there were any changes, rebase (if in doubt, rebase). This merges in the new code with your new code: `git rebase -i origin/master`
11. Push your changes: `git push origin myname_new_feature`
12. Make a pull request and wait for your code to be reviewed
13. If any changes are required, make them commit your changes, and rebase again. This time you need to make sure that you squash your commits (makes sure you only add one commit in the end). Where you see your commit message, change 'pick' to 'fixup' or 'f'.
14. Push your code again and repeat 12 and 13 until your code gets merged with master

## Deployment Process ##
Please note, we currently don't have this process set up, we're working to get here.

1. Write code and get it pulled into master
2. Your changes will be automatically be deployed to our preview site
3. Your changes will be tested there, if tests fail deployers will be notified
4. Once that deployment process completes and tests pass, translators will be notified if there are new translations
4. Once translators have completed translations, translations will be committed to master and your changes will be deployed to production

## Requirements Overview ##

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

Translating our site into multiple languages is a key part of opening it up to the world. When coding, never include any English text as in a string or Haml. Instead, we shall always use the underscore helper method `_`. The method takes a translation key and some optional parameters.

All translation is done in a collaborative, volunteer based system on the site itself, even the English text. If a user has sufficient permissions, the underscore method will produce highlighted text which can be edited directly by the user.

The method can be used as follows:

	_ 'basename.my_key'

	_ 'basename.my_key', :paragraph

	end

If the key does not exist, the previous lines will produce the following respectively:

	'my_key'
	
	'Curabitur non nulla sit amet nisl tempus convallis quis ac lectus.
		Vivamus magna justo, lacinia eget consectetur sed, convallis at
		tellus. Proin eget tortor risus. Donec sollicitudin molestie
		malesuada. Donec rutrum congue leo eget malesuada.'

If the user has sufficient rights, these blocks will also be surrounded by the necessary markup to allow them to be selected and edited by the user.

Translations are recorded during testing and committed to the repository when pushing to github. After pulling down the latest version from github you should always run `rake translations:migrate` to put the latest migrations into your database.

### Style Guide ###

On hold until our design team determines a director for our identity.


## Testing Practices ##

Our focus will be on integration testing using Capybara. While testing the app records all translations that it finds, whether or not they exist, and which pages that they were found on.
