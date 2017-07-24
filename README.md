# Bike!Bike! #

| Environment | Build Status |
| ----------- |:------------:|
| Development | [![Development Build Status](https://travis-ci.org/bikebike/BikeBike.svg?branch=development)](https://travis-ci.org/bikebike/BikeBike) |
| Production  | [![Production Build Status](https://travis-ci.org/bikebike/BikeBike.svg?branch=master)](https://travis-ci.org/bikebike/BikeBike) |

This is the repository for the Bike!Bike! website. It can be found in development at [preview.bikebike.org](https://preview-en.bikebike.org/) and in production at [bikebike.org](https://bikebike.org/)

Feel free to clone or fork the repository any time to start working on new features or fixes. To get help create an issue or contact Godwin: `goodgodwin` `@` `hotmail.com` any time.

![Screenshot of Bike!Bike!](https://workbench.bikecollectives.org/apps/bikebike/screenshots/application/home/3/desktop.png)

## Technologies ##

* [Ruby 2.3.0][1]
* [Rails 4.2.0][2] _([Project to upgrade to Rails 5](https://github.com/orgs/bikebike/projects/13))_
* [PostgreSQL][3]
* [HAML][4]
* [SCSS][5]
* [NGinx][6] _([We may switch to Caddy](https://github.com/bikebike/bikecollectives_core/issues/1))_
* [DigitalOcean][7] _([We may switch to Linode](https://github.com/bikebike/bikecollectives_core/issues/2))_

[1]: http://www.ruby-lang.org/en/
[2]: http://rubyonrails.org/
[3]: http://www.postgresql.org/
[4]: http://haml.info/
[5]: http://sass-lang.com/
[6]: https://www.nginx.com/
[7]: https://digitalocean.com


## Internal Gems ##
We will make a commitment to extract any functionality that makes sense to do so, into separate gems in order to share functionality with others, with our other projects (such as bikecollectives.org), and to enable easier collaboration amongst ourselves.

It is recommended that you at least use also clone `bikecollectives_core` into you workspace. To override the gem location execute:

```bash
bundle config local.bikecollectives_core PATH_TO/bikecollectives_core
```

Here is a list of the gems we have created so far, if you are a collaborator on this project you may need to become a collaborator on these gems as well. Don't hesitate to make a request, it won't be denied:

### Lingua Franca ###

[Lingua Franca](https://github.com/lingua-franca/lingua_franca) provides an easy way to include translatable content and provides a user interface for translators to provide translations. See [Translations](#translations) for best practices on the Bike!Bike! website.

### Bumbleberry ###
[Bumbleberry](https://github.com/bumbleberry/bumbleberry) provides cross-browser support with little effort and minimum file sizes. Basically it creates a different stylesheet for every known browser and only includes supported rules for each using information obtained from [caniuse.com](caniuse.com).


## Github Workflow ##
If you are a git wiz, feel free to adjust the steps below slightly, otherwise follow these steps until you are familiar enough to stray. What should remain constant is that we need to branch, code review, and merge with master.

1. Before you start working on a new feature, start working on a new branch (alternatively you can fork): `git checkout -b myname_new_feature`
1. Write your new feature
1. Add tests and execute them using `bundle exec i18n`
1. Make any adjustments, make sure you have included comments and abided other coding conventions
1. Check your git status to make sure you are on the correct branch and have any new files to add: `git status`
1. Add any new files using: `git add [myfile]`
1. Commit your changes: `git commit -am 'My commit message'`
1. Switch back to the development branch and pull the latest: `git checkout master && git pull`
1. Switch back to your branch: `git checkout myname_new_feature`
1. If there were any changes, rebase. This merges in the new code with your new code: `git rebase -i origin/development`
1. Push your changes: `git push origin myname_new_feature`
1. Make a pull request and wait for your code to be reviewed
1. If any changes are required, make them commit your changes, and rebase again. This time you need to make sure that you squash your commits (makes sure you only add one commit in the end). Where you see your commit message, change 'pick' to 'fixup' or 'f'.
1. Push your code again and repeat 12 and 13 until your code gets merged with development
1. Once your code is in development it will be released to our development site, once new translations are added and the site is manually tested it will be moved to master and the production site

## Deployment Process ##
Please note, we currently don't have this process set up, we're working to get here.

1. Write code and get it pulled into master
2. Your changes will be automatically be deployed to our preview site
3. Your changes will be tested there, if tests fail deployers will be notified
4. Once that deployment process completes and tests pass, translators will be notified if there are new translations
4. Once translators have completed translations, translations will be committed to master and your changes will be deployed to production


## Translations ##

Translating our site into multiple languages is a key part of opening it up to the world. When coding, never include any English text as in a string or Haml. Instead, we shall always use the underscore helper method `_`. The method takes a translation key and some optional parameters.

All translation is done in a collaborative, volunteer based system on the site itself, even the English text. If a user has sufficient permissions, the underscore method will produce highlighted text which can be edited directly by the user.

The method can be used as follows:

```haml
%h1=_'basename.my_title'
%p=_'basename.my_key', :paragraph
%button=_'basename.click_me'
```

Assuming none of the keys map to translations, this will be rendered into the following HTML:

```html
<h1>
  Lorem ipsum dolor sit amet
</h1>

<p>
  Curabitur non nulla sit amet nisl tempus convallis quis ac lectus. Vivamus magna justo, lacinia eget consectetur sed, convallis at tellus. Proin eget tortor risus. Donec sollicitudin molestie malesuada. Donec rutrum congue leo eget malesuada.
</p>

<button>
  click me
</button>
```

By default, the key will be translated using the last key part ('click me' in this example), however if a context is provided, some appropriate lorem ipsum text. Available contexts are:

* `title` (alias: `t`): title text, a few words in upper case
* `word` (alias: `words`, `w`): A word, if a second parameter is provided a numbr of words will be rendered (for example `_'key',:w,3`)
* `sentence` (alias: `sentences`, `s`): A sentence or multiple sentence
* `paragraph` (alias: `p`): A paragraph

If actual translations are not provided by the time the code hits production, fatals will occur.

### Entering translations

Translations can be provided directly by editing [`en.yml`](https://github.com/bikebike/BikeBike/blob/master/config/locales/en.yml) but will also be directly using the [workbench](https://github.com/bikebike/bikecollectives_workbench):

![Screenshot of the Bike Collectives Workbench](https://i.imgur.com/y8Ezjeg.png)

### Collecting translations

Translations, along with screenshots and HTML page captures are collected during testing so that the workbench will have up to date translations and context for each to make it easier for translators to provide relevant translations. To collect these translations yourself, execute `rake i18n`.

## Testing Practices ##

Our focus will be on integration testing using Capybara. While testing the app records all translations that it finds, whether or not they exist, and which pages that they were found on.

Before commiting you shuold always run:

```bash
bundle exec rake cucumber:run
```

and:

```bash
bundle exec rake i18n
```

The former is going to be faster but does not perform checks for untranslated content, it is recommneded that you run this regularily while developing while running the `i18n` check will ensure that you have not missed translations.

If you are creating any new content you will also want to add a new feature or scenario to ensure the new translations are picked up.
