## Welcome to BEFdata

It is a data management software for biodiversity - ecological functioning
research units. As a web based portal it enables research groups to upload,
store, manage and share data with each other. BEFdata uses an Excel workbook
for the exchange of data and metadata and thus integrates easily into your
data collection and analysis workflow. It provides a secure environment
for your data during an on-going data collection or analysis. Other project
members can only access your data after a data access request.

## Main features

A brief list of the most important features:

* Users can add data using a spreadsheet software (e.g. Excel)
* Online access to data of working groups for better collaboration
* Provides tools to curate naming conventions in primary data.
* The software can export metadata as Ecological Metadata Standard
* Keep record of ideas for analysis and data exchange (Proposals)
* Access to data with the rBEFdata R package for (analysis, documentation)

## Getting Started

You can set up the software for your own projects. Simply follow the steps
below.

1. Prerequisites

Install the following tools on your server system.

* Ruby 1.9.3 (You can use a ruby version manager e.g. rvm)
* PostgreSql Database with plpgsql language (version <= 9.6)
* ImageMagick

2. Download the source code

* You can e.g. the `git clone` command

At the moment you find the last stable version on branch 1.6. After you cloned
the project you should thus checkout that branch. `git checkout v1.6`.

* Configure the software

You can use the template configuration files in the project configuration
folder. The template files are all named ending with "dist". When you remove
the "dist" from the name the application uses them. For example

```
configuration.yml.dist -> configuration.yml
database.yml.dist -> database.yml
application.yml.dist -> appication.yml
```

The application.yml contains environment variables which are used to configure
the application secret token. This token is used to verify the integrity of
signed cookies. Make sure the secret is at least 30 characters and all random,
no regular words or you'll be exposed to dictionary attacks! The
application.yml also configures the party foul gem to track issues in
production mode.

3. Set up the database-connection

In config/database.yml set the username and password for the "development" and
"test" and "production" databases.

4. Configure ImageMagick

```
# Check ImageMagick path by running (working on linux only)
which convert

# Check if the path in config/environments/development.rb
# (or production.rb etc.) is corresponding to the one of convert
Paperclip.options[:command_path] = "/usr/bin/convert"
```

5. Setup the database

```
# setup the database
bundle exec rake db:setup

# fill the database with default values
bundle exec rake db:seed
```

6. Fire up development server

    rails server

And pointing your browser to localhost:3000 you should see your very own
befdata instance. You can login with the username "Admin" and the password
"test". You should change it in your profile.

## License

Befdata is released under the MIT License (MIT):

Copyright (c) 2019 Department of Special Botany, University of Leipzig,
represented by Christian Wirth, The BEF-China Research Unit of the German
Research Foundation (DFG), represented by Helge Bruelheide, as well as Karin
Nadrowski, Sophia Ratcliffe, Claas-Thido Pfaff

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Icons derived from Dortmund[http://pc.de/icons/] are released under a the CC BY
3.0 license[http://creativecommons.org/licenses/by/3.0/]: Copyrigth (c) pc.de.

Icons derived from Sanscons[http://www.somerandomdude.com/work/sanscons/] are
released under the CC BY-SA 3.0
license[http://creativecommons.org/licenses/by-sa/3.0/us/]: Copyrigth (c) P.J.
Onori.
