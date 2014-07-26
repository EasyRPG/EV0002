EV0002
======

The channel bot in #easyrpg on freenode, provides logs and pizza (and maybe more).

It is using the [cinch](https://github.com/cinchrb/cinch) bot framework and is written
in ruby, like the legacy EV0001.

Needed gems beside `cinch` are: `json`, `cinch-seen`, `thin` and `sinatra` (see Gemfile for
details).
You can use bundler to install the dependencies.

Acknowledgements
----------------

plugins/http_server.rb by @Quintus, under LGPL license
