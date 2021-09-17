# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

```
bundle lock --add-platform x86_64-linux Gemfile
bundle config --local build.mysql2 "--with-ldflags=-L/usr/local/opt/openssl@1.1/lib --with-cppflags=-I/usr/local/opt/openssl@1.1/include"
bundle install
bundle cache --all
bundle package --all-platforms
```

* Configuration

```
bin/docker --help
bin/docker setup
```

* Setup env

```
bin/redis start --publish
bin/db start --publish
 ```

* Database creation

```
bin/rails db:setup
```

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
