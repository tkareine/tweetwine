tweetwine -- a simple Twitter command line agent
================================================

## DESCRIPTION

Tweetwine shows the home timeline of the authenticated user, the latest tweets
of friends and followers, and the latest tweets that mention the user. If
that's not enough, you can search statuses with arbitrary terms. In addition,
you can send new tweets with it.

Features:

* Simple to use command line interface, with Bash completion support
* ANSI coloring of statuses, but in discreet manner
* Supports shortening URLs in a status update with a configurable shortening
  service
* Configuration file for preferred settings

## INSTALL

Install Tweetwine with RubyGems:

    $ gem install tweetwine

The program is tested with Ruby 1.8.7 and 1.9.

The program requires [oauth](http://oauth.rubyforge.org/) gem to be installed.
In addition, the program needs [json](http://json.rubyforge.org/) gem on Ruby
1.8.

Documentation is provided as gem man pages. Use
[gem-man](http://github.com/defunkt/gem-man) to see them:

    $ gem man tweetwine

## BASIC USAGE AND CONFIGURATION

The program uses OAuth to authenticate the user to Twitter. For that, you need
to register yourself a personal application at
[Twitter's developer site](http://dev.twitter.com/apps). After registration
you have access to the consumer key and secret for the application. But those
are not enough: at the site, click "My access token" link. There you will find
your personal access key and secret that correspond to the consumer key and
secret. You will need all the four tokens.

Create a configuration file, `~/tweetwine`, and insert the four OAuth
authentication tokens into it:

    :oauth:
      :consumer_key: aaaaaaaaaaaaaaaaaaaa
      :consumer_secret: bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
      :access_key: cccccccccccccccccccccccccccccccccccccccccccccccc
      :access_secret: dddddddddddddddddddddddddddddddddddddddd

The configuration file must be in in YAML syntax. In addition to the OAuth
tokens, the program recognizes the following settings:

    :username: <your_username>
    :colors: true|false

In the command line, run the program by entering

    $ tweetwine [global_options..] [command] [command_options...]

For all the global options and commands, see:

    $ tweetwine help

For information about a specific command and its options, enter:

    $ tweetwine help <command>

### URL shortening for a status update

Before actually sending a new status update, it is possible for the software
to shorten the URLs in the tweet by using an external web service. This can be
enabled via the `:shorten_urls` key in configuration file; for example:

    :oauth:
      :consumer_key: aaaaaaaaaaaaaaaaaaaa
      :consumer_secret: bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
      :access_key: cccccccccccccccccccccccccccccccccccccccccccccccc
      :access_secret: dddddddddddddddddddddddddddddddddddddddd
    :username: spoonman
    :colors: true
    :shorten_urls:
      :service_url: http://is.gd/create.php
      :method: post
      :url_param_name: URL
      :xpath_selector: //input[@id='short_url']/@value

The supported methods (in `method`) are `get` and `post`. The method chosen
affects whether parameters are passed as URL query parameters or as payload in
the HTTP request, respectively. Extra parameters can be given via
`:extra_params` key, as a hash.

The `xpath_selector` is needed to extract the shortened URL from the result.

URL shortening can be disabled by not defining `shorten_urls` key in the
configuration file, or using the command line option `--no-url-shorten`.

*NOTE:* The use of the feature requires [nokogiri](http://nokogiri.org/) gem
to be installed.

### HTTP proxy setting

If `$http_proxy` environment variable is set, Tweetwine attempts to use the
URL in the environment variable as HTTP proxy for all its HTTP connections.
This setting can be overridden with `--http-proxy` and `--no-http-proxy`
command line options.

### Bash command line completion support

Bash shell supports command line completion via tab character. If you want to
enable Tweetwine specific completion with Bash, source the file
`tweetwine-completion.bash`, located in `contrib` directory:

    . contrib/tweetwine-completion.bash

In order to do this automatically when your shell starts, insert the following
snippet to your Bash initialization script (such as `~/.bashrc`):

    if [ -f <path_to_tweetwine>/contrib/tweetwine-completion.bash ]; then
        . <path_to_tweetwine>/contrib/tweetwine-completion.bash
    fi

## COPYRIGHT

Tweetwine is Copyright (c) 2009-2010 Tuomas Kareinen.

## SEE ALSO

<http://github.com/tuomas/tweetwine>
