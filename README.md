# EV0002

The channel bot in [#easyrpg][webchat] on freenode, provides logs, pizza and a lot of
other stuff.

It is is written in ruby, using the [cinch][cinch] bot framework (our legacy
[EV0001][ev0001] bot was written from scratch).

## Installation

Needed gems besides `cinch` are (see Gemfile for details):

 * [cinch-seen][cinch-seen]
 * [cinch-identify][cinch-identify]
 * [json][json]
 * [thin][thin]
 * [sinatra][sinatra]
 * [chronic][chronic]
 * [xmlrpc][xmlrpc] (for ruby 2.4+)

You can use bundler to install them and their dependencies.

    $ bundle install --path vendor/bundle [--shebang="ruby2.1"]

If you provide the path argument, gems will be installed locally.

Secret values (passwords and such) are read from a file `secrets.yml` on startup.
A template is provided, you need to copy it and fill in the values or remove all
references to `$secrets` and fill in the values directly.

## Running

    $ ./EV0002

This helper script tries to detect if you installed the gems locally with bundler and
will run EV0002 in bundler environment if needed.

## LICENSE

This bot and plugins were written by carstene1ns and the EV0002 authors.
They are licensed under the MIT license, see LICENSE file for details.
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

   Heavily modified version of Quintus' plugin, see above. Generates HTML logs and links a
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

[webchat]: https://webchat.freenode.net/?channels=easyrpg
[cinch]: https://github.com/cinchrb/cinch
[ev0001]: https://github.com/EasyRPG/EV0001
[cinch-seen]: https://github.com/bhaberer/cinch-seen
[cinch-identify]: https://github.com/cinchrb/cinch-identify
[json]: http://flori.github.io/json/
[thin]: http://code.macournoyer.com/thin/
[sinatra]: http://sinatrarb.com/
[chronic]: https://github.com/mojombo/chronic
[xmlrpc]: https://github.com/ruby/xmlrpc
[quintus]: https://github.com/Quintus
