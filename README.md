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

The program is tested with Ruby 1.8.7 and 1.9.2.

The program requires [oauth](http://oauth.rubyforge.org/) gem to be installed.
In addition, the program needs [json](http://json.rubyforge.org/) gem on Ruby
1.8.

This documentation page is also provided as a manual page. Use
[gem-man](http://github.com/defunkt/gem-man) to see it:

    $ gem man tweetwine

## BASIC USAGE AND CONFIGURATION

In the command line, run the program by entering

    $ tweetwine [global_options..] [command] [command_options...]

For all the global options and commands, see:

    $ tweetwine help

For information about a specific command and its options, enter:

    $ tweetwine help <command>

In order to use to use the program, you must authorize it to access your
account on Twitter. This is done with
[OAuth](http://dev.twitter.com/pages/oauth_faq) protocol, and it is required
when the program is launched for the first time. After that, Tweetwine
remembers the access you granted by storing the access token into
`~/.tweetwine`. The file serves as your configuration file.

Because the access token is sensitive information, Tweetwine obfuscates it
when storing it into the file. While this prevents simple plain text reading
attempts of the access token, it is not secure. You restrict access to the
file only to yourself.

The configuration file is in YAML syntax. In addition to the OAuth access
token, the program recognizes the following settings:

    :colors: true|false
    :username: <your_username>

### URL shortening for a status update

Before actually sending a new status update, it is possible for the software
to shorten the URLs in the tweet by using an external web service. This can be
enabled via the `:shorten_urls` key in configuration file; for example:

    :username: spoonman
    :colors: true
    :shorten_urls:
      :service_url: http://is.gd/create.php
      :method: post
      :url_param_name: URL
      :xpath_selector: //input[@id='short_url']/@value
      :disable: false

The supported HTTP request methods (in `method` field) are `get` and `post`.
The method chosen affects whether parameters are passed as URL query
parameters or as payload in the HTTP request, respectively. Extra parameters
can be given via `:extra_params` field, as a hash.

The `xpath_selector` field is needed to locate the HTML element which contains
the shortened URL from the HTTP response.

URL shortening can be disabled by not defining `shorten_urls` key in the
configuration file, setting field `disable` to true, or by using the command
line option `--no-url-shorten`. The last option is useful for disabling URL
shortening only temporarily.

*NOTE:* The use of the feature requires [nokogiri](http://nokogiri.org/) gem
to be installed.

### HTTP proxy setting

If `$http_proxy` environment variable is set, Tweetwine attempts to use the
URL in the environment variable as HTTP proxy for its HTTP connections. This
setting can be overridden with `--http-proxy` and `--no-http-proxy` command
line options.

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
