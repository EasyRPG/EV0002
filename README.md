# EV0002

The channel bot in [#easyrpg][webchat] on Libera Chat, provides logs, pizza and
a lot of other stuff.

It is is written in ruby, using the [cinch][cinch] bot framework (our legacy
[EV0001][ev0001] bot was written from scratch). It runs with older rubies, is
not compatible with the current version `ruby 3`.

## Installation

Needed gems besides `cinch` are (see Gemfile for details):

 * [cinch-seen][cinch-seen]
 * [json][json]
 * [thin][thin]
 * [sinatra][sinatra]
 * [chronic][chronic]
 * [googleauth][googleauth]
 * [http][http]
 * [jenkins2-api][jenkins2-api]
 * [xmlrpc][xmlrpc] (for ruby 2.4+)

You can use bundler to install them and their dependencies.

    $ bundle config set --local path 'vendor/bundle'
    $ bundle config set --local clean true
    $ bundle install

For Arch Linux replace `bundle` with `bundle2.7`.

Secret values (passwords and such) are read from a file `secrets.yml` on startup.
A template is provided, you need to copy it and fill in the values or remove all
references to `$secrets` and fill in the values directly.

## Running

    $ ./EV0002

This helper script tries to detect if you installed the gems locally with bundler and
will run EV0002 in bundler environment if needed.

If your system is recent, it will ship with a newer version of ruby, we recommend
using [rvm][rvm] or [rbenv][rbenv] to install and use ruby 2.7.6 for the time being,
a `.ruby-version` file is provided.

## LICENSE

This bot and plugins were written by carstene1ns and the EV0002 authors.
They are licensed under the ISC license, see LICENSE file for details.
There are a few exceptions to the license, see `Acknowledgements` sections for details.

## Acknowledgements

plugins/http_server.rb by [Quintus][quintus], under LGPL license - from
https://github.com/Quintus/cinch-plugins

plugins/logplus.rb by [Quintus][quintus], under LGPL license - from
https://github.com/Quintus/cinch-plugins

## Plugins

 * plugins/link_github_issues.rb:

   Takes a list of available projects and links corresponding issues when an user sends a
   message containing `<project>#<number>`. Uses GitHub json api to find issue title,
   state and URL.

 * plugins/logplus.rb:

   Modified version of Quintus' plugin, see above. Generates HTML logs and links a
   corresponding log file, when a user uses the `log` command with a human readable time
   specification, e.g. `log monday last week`.

 * plugins/http_server.rb:

   Helper plugin by Quintus, see above. Provides the webserver used by the Webhook plugins.

 * plugins/dokuwiki_xmlrpc.rb:

   Simple plugin to use Dokuwiki's XMLRPC api. Currently only provides search
   functionality and the wiki URL.

 * plugins/easyrpg_links.rb:

   Simple plugin that links webservices related to the EasyRPG project.

 * plugins/asciifood.rb:

   Fun plugin, that outputs something to drink or eat.

 * plugins/github_webhooks.rb:

   Uses GitHub webhooks to provide channel notifications, when something happens on a
   monitored GitHub project. This uses the webserver provided by http_server.rb and
   relies on the GitHub api of course. Similiar plugins are named `octospy` for other
   bot frameworks.

 * plugins/blog_webhooks.rb:

   Uses webhooks to provide channel notifications, when someone adds a new blogpost/page
   or someone adds a comment/replies to a comment  This uses the webserver provided by
   http_server.rb and relies on the hookpress wordpress plugin or a hosted setup at
   wordpress.com. Currently, it does not display full information, as the hooks are
   limited to specific fields.

 * plugins/playstore_reviews.rb:

   Uses the Google PlayStore API (pulled with a timer) to provide channel notifications,
   when someone adds a new review or updates an old review for our Android app.

 * plugins/twitter_webhooks.rb:

   Uses Zapier webhooks to provide channel notifications, when something project related
   happens on Twitter. This uses the webserver provided by http_server.rb and
   relies on the Zapier service and Twitter api.

 * plugins/discourse_webhooks.rb:

   Uses webhooks to provide channel notifications, when a new topic is added on the forums.

 * plugins/jenkins_failures.rb:

   Uses the Jenkins API (pulled with a timer) to provide channel notifications about
   failed builds.

[webchat]: https://kiwiirc.com/nextclient/#ircs://irc.libera.chat/#easyrpg?nick=rpgguest??
[cinch]: https://github.com/cinchrb/cinch
[ev0001]: https://github.com/EasyRPG/EV0001
[cinch-seen]: https://github.com/bhaberer/cinch-seen
[cinch-identify]: https://github.com/cinchrb/cinch-identify
[json]: http://flori.github.io/json/
[thin]: http://code.macournoyer.com/thin/
[sinatra]: http://sinatrarb.com/
[chronic]: https://github.com/mojombo/chronic
[http]: https://github.com/httprb/http
[googleauth]: https://github.com/google/google-auth-library-ruby
[jenkins2-api]: https://github.com/yitsushi/jenkins2-api
[xmlrpc]: https://github.com/ruby/xmlrpc
[rvm]: https://rvm.io
[rbenv]: https://github.com/rbenv/rbenv
[quintus]: https://github.com/Quintus
