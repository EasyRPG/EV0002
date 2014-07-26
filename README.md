EV0002
======

The channel bot in #easyrpg on freenode, provides logs and pizza (and maybe more).

It is using the [cinch](https://github.com/cinchrb/cinch) bot framework and is written
in ruby, like the legacy EV0001.

Installation
------------

Needed gems beside `cinch` are: `json`, `cinch-seen`, `thin` and `sinatra` (see Gemfile
for details).
You can use bundler to install the dependencies.

    $ bundle

LICENSE
-------

This bot and its plugins were written by carstene1ns and are licensed under the MIT
license, see LICENSE file for details.
There are a few exceptions to the license, see `Acknowledgements` sections for details.

Acknowledgements
----------------

plugins/http_server.rb by @Quintus, under LGPL license
