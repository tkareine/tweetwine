tweetwine -- a simple Twitter command line agent
================================================

## DESCRIPTION

Tweetwine supports showing the home timeline of the authenticated user, the
latest statuses of friends and followers, and the latest statuses that mention
the user. If that's not enough, statuses can be searched with arbitrary terms.
In addition, new statuses can be sent.

Features:

* Simple to use command line interface, with Bash completion support
* ANSI coloring of statuses, but in discreet manner
* Supports shortening URLs in a status update with a configurable shortening
  service
* Configuration file for preferred settings

## INSTALL

Install Tweetwine with RubyGems:

    $ gem install tweetwine

The program is compatible with both Ruby 1.8 and 1.9.

The program requires [rest-client](http://github.com/archiloque/rest-client)
gem to be installed. In addition, the program needs
[json](http://json.rubyforge.org/) gem on Ruby 1.8.

## BASIC USAGE AND CONFIGURATION

In the command line, run the program by entering

    $ tweetwine [ <GLOBAL_OPTIONS> ] [ <COMMAND> ] [ <COMMAND_OPTIONS> ]

The program needs the user's username and password for authentication. This
information can be supplied either via a configuration file or as an option
(`-a USERNAME:PASSWORD`) to the program. It is recommended to use the former
method over the latter.

The configuration file, in `~/.tweetwine`, is in YAML syntax. The program
recognizes the following basic settings:

    username: <your_username>
    password: <your_password>
    colors: true|false

For all the global options and commands, see:

    $ tweetwine help

For information about a specific command and its options, enter:

    $ tweetwine help <COMMAND>

### URL shortening for status update

Before actually sending a status update, it is possible for the software to
shorten the URLs in the update by using an external web service. This can be
enabled via the `shorten_urls` key in configuration file; for example:

    username: spoonman
    password: withyourhands
    colors: true
    shorten_urls:
      enable: true
      service_url: http://is.gd/create.php
      method: post
      url_param_name: URL
      xpath_selector: //input[@id='short_url']/@value

The supported methods (in `method`) are `get` and `post`. The method chosen
affects whether parameters are passed as URL query parameters or as payload
in the HTTP request, respectively. Extra parameters can be given via
`extra_params` key, as a hash.

The `xpath_selector` is needed to extract the shortened URL from the result.

URL shortening can be disabled by

* not defining `shorten_urls` key in the configuration file,
* setting key `enable` to `false`, or
* using the command line option `--no-url-shorten`.

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

Tweetwine is Copyright (c) 2009-2010 Tuomas Kareinen

## SEE ALSO

tweetwine(1), <http://github.com/tuomas/tweetwine>
