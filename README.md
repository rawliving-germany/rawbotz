# Rawbotz

Rawbotz provides a Web-Interface to do certain management tasks for a particular Magento Web-Shop (RawLiving Germany).

In this shop, products are supplied by different suppliers, of which one offers a magento-shop itself.

Rawbotz couples the `rawgento_db`, `rawgento_models` and `magento_remote` gems to make it easy to order items from this particular other shop and provides further functionality, e.g. accessing stock and sales history information.

Note that this git repository includes software components whose Copyright and License differ from the other parts.

These are
- Font Awesome (http://) in `lib/rawbotz/public/font-awesome-4.5.0`
- Pure CSS (http://) in `lib/rawbotz/public/pure-min.css`
- Chart.JS (http://) in `lib/rawbotz/public/Chart.min.js`
- jquery and jquery-ui (http://) in `lib/rawbotz/public/jquery-2.2.0.min.js` and `lib/rawbotz/public/jui`

The copyright and license information is contained in the respective file headers. All other files are Copyright 2016 Felix Wolfsteller and licensed under the AGPLv3 (or any later).

## Installation

While bundling rawbotz up and installing it as a gem should be possible, it is strongly advised to install it via git.

Anyway, the application is so specific to RawLiving Germanys needs that you probably want to get in contact first.

## Assumptions

- supplier attribute
- shelve attribute
- packsize attribute
- Ubuntu 14.04 installation, using rvm in an unprivileged users home.

## Usage

Until rawgento_models, `rawgento_db` and `magento_remote` have settled, please adjust the `Gemfile` or checkout these gems in the parent folder.

### Configuration

You have two options, 1) configure each component individually, or use the unified approach.
Note that how the configuration works is still not settled.

#### Component-wise Configuration

Look in the corresponding gems to check how their configuration has to be done:

  * [rawgento_db s rawgento_db-config.yml](https://github.com/rawliving-germany/rawgento_db)
  * [rawgento_models s db/config.yml](https://github.com/rawliving-germany/rawgento_models)
  * [magento_remotes config](https://github.com/fwolfst/magento_remote)

##### In Quick

Configure your database in db/config.yml (Rails style, `rawgento_models`).

Configure your magento mysql-connection in rawgento_db-config.yml (`rawgento_db`):
    host: myshop.shop
    port: 3306
    database: magento_myshop
    username: magento_myshop_dbuser
    password: magento_myshop_dbpassword

Finally, configure the remote shops credentials (`magento_remote`)

#### Unified appraoch

Create a `rawbotz.conf` YAML-file with the unified keys needed.  Note that you can pass the path to this configuration file to the various executables in `exe/`.

    # Rawbotz own database
    default: &default
      adapter: sqlite3
      database: /home/rawbotz/database.sqlite
      encoding: utf8
      pool: 5
      timeout: 5000
    
    development:
      <<: *default
    test:
      <<: *default
      database: db/rawgento_test.db
    
    # Local Magento MySQL database
    host: 127.0.0.1
    port: 3306
    database: magento_shop_dbname
    username: magento_db_username
    password: magento_db_password
    # Attributes needed
    attribute_ids:
      name: 11
      supplier_name: 666
      shelve_nr: 42
      packsize: 1337
    
    # Remote Magento Web Interface (for our mech)
    remote_shop:
      base_uri: https://magentoshop.remote
      user: mylogin@email.address
      pass: whatnottobenamed
    
    supplier_name: MagentoShop Remote

#### Setup the database

Run `rake db:setup` or `rake db:migrate` to setup the database.

#### Populate the database with local and remote products

#### Setup mailing

I guess we will have to configure pony soon.

### Deployment or web-app startup

You can run `(bundle exec) exe/rawbotz`, `rackup` or put rawbotz behind a phusion passenger.
There is a `-c` option to pass in a config file.

### Stock History Update via cron

Assuming an Ubuntu Server Setup, run `crontab -e` and add following line to fetch stock values every day at 03:00 am.

### Other tools included

#### rawbotz_update_local_products

Updates Products from magento MySQL database.  See `--help` for more information.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec rawbotz` to use the gem in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rawbotz. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

Feel free to get in contact with me.
