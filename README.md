## Welcome to BEFdata

It is a data management software for biodiversity related research units. As a
web based portal, it enables research groups to upload, store, manage and share
data with each other. BEFdata uses an Excel workbook for the exchange of data
and metadata and thus integrates easily into your data collection and analysis
workflow. It provides a secure environment for your data during an on-going
data collection or analysis.

[![Build Status](https://travis-ci.org/cpfaff/befdata.svg?branch=master)](https://travis-ci.org/cpfaff/befdata)[![Coverage Status](https://coveralls.io/repos/github/cpfaff/befdata/badge.svg?branch=master)](https://coveralls.io/github/cpfaff/befdata?branch=master)

## Main features

A brief list of the most important features:

* Users can add and data using a spreadsheet software (e.g. Excel)
* The spreadsheet also helps to collect metadata about the dataset.
* Online access to data for better collaboration in projects
* Tools to curate the naming conventions used in the primary data (harmonization).
* The software can export metadata as Ecological Metadata Standard (exchange)
* Keep record of ideas for analysis and data exchange (Proposals)
* Access the data with the rBEFdata R package for (analysis, documentation)

## Getting Started

BEF-Data is developed under an [MIT](LICENSE.md) license. You can set up the
software for your own projects. To set up a local instance on your computer
follow the steps below. In the wiki you will find instructions about how to
setup a dedicated linux server instsance.

1. Prerequisites

Install the following tools on your system.

* Ruby 2.3.3 (You can use a ruby version manager e.g. rvm)
* PostgreSql (version <= 9.6.15)
* ImageMagick
* Passenger (deployment)
* Node.js

2. Download the source code

* You can e.g. use the `git clone` command or the
  [download](https://github.com/cpfaff/befdata/archive/master.zip) button.

You find the last stable version on the branch with the greatest version number
(e.g. v1.6.1) After you cloned the project you should issue a checkout for that
branch (e.g. `git checkout v1.6.1`).

3. Install the bundle

When you have setup ruby you can install the bundler gem.

```
gem install bundler
```

If you are in the root folder of the BEF-Data application you can issue the
command below which will install all required libraries.

```
bundle install
```

4. Configure the software

You can use the template configuration files in the project `config/` folder.
The template files are all named with the appendix `.dist`. When you remove the
`.dist` from the name of the file, the application will start to use it for it
for configuration. You need to rename these:

```
configuration.yml.dist -> configuration.yml
database.yml.dist -> database.yml
application.yml.dist -> appication.yml
mailer.yml.dist -> mailer.yml
```

Afterwards you need to open them and make your changes to the configuration
according to your needs. The files are commented so you can understand what the
separate options do.

* Create a secret key.

```
bundle exec rake secret
```

You copy and paste it into the configuration file
`config/initializers/secret_token.rb`

* Set up the database

We are using postgres as our database backend. When you have set it up you
should change the password of the root user which is named postgres. When you
have done this create a new user for BEFadta and a database you want to use in
our application. Make the new user the owner of the database.

* Connect to the database

In the configuration file `config/database.yml` you can set the `host` the
`database` the `username` and `password` for different environments
(`production`, `test`, `development`). If you want to run this on a dedicated
Linux server, you need only the `production` environment related information.
Add all information from the database you just have set up.

If you run this locally on your computer, and if want spin up an instance of
BEFdata with the rails builtin server you might also want to setup the other
environments (particularly development).

4. Configure ImageMagick

The ImageMagick `convert` command is used to create thumbnails of the user
uploaded avatar images in conjunction with the paperclip gem. Thus convert
needs to be accessible by paperclip. You have to set the path to the executable
in the configuration file of the environment you are running BEFdata in. For
example in production `config/environments/production.rb`.

```
# setup paperclip
Paperclip.options[:command_path] = '/usr/bin'
Paperclip.options[:log] = false
```

5. Initialize the database

```
# setup the database
bundle exec rake db:setup

# fill the database with default values
bundle exec rake db:seed
```

Afterwards you can use your browser and add `localhost:3000` in the address
bar. There you should find your very own befdata instance. You can login with
the username "Admin" and the password "test". You should change that password
in the profile of the user.
