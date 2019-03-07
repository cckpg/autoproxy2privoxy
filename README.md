AutoProxy2Privoxy
=================

Overview
--------

AutoProxy2Privoxy generates a list of Privoxy forward rules from a set of
AutoProxy rules.

AutoProxy is a firefox addon that automatically determines which URLs are to
be requested through a proxy, according to a predefined list of rules.

The AutoProxy2Pac program can produce a Proxy Auto-Config file out of the
AutoProxy ruleset, to be used by all browsers that support PAC.

Privoxy, with forward rules set up correctly, can be used as a Proxy Auto-Config
replacement, with the benefit of being universal for any program that uses the
proxy.

Another advantage of using Privoxy is that, when forwarding to a SOCKS4a/SOCKS5
proxy, Privoxy will request the DNS resolution to happen on the remote side.
This is beneficial for programs that do not support remote DNS resolution.

Inspired by AutoProxy2Pac, powered by Privoxy, and motivated by GFW, here,
ladies and gentlemen, I present you AutoProxy2Privoxy!

How to Build
------------

GNU Gawk is required for the conversion script.

The following will download the newest GFWList and generate `gfwlist.action`:

    make -B proxy=socks5://127.0.0.1:9050

How to Use
----------

Privoxy supports all major operating systems.  Installation paths may vary from
platform to platform. The following assumes a Linux environment.

First, make sure the address and type of the target proxy is set correctly in
[gfwlist.action](https://github.com/cckpg/autoproxy2privoxy/raw/master/gfwlist.action):

    {+forward-override{forward-socks5 127.0.0.1:9050 .}}

Then issue the following commands as root:

    cp gfwlist.action /etc/privoxy/

Now edit `/etc/privoxy/config`, adding this line:

    actionsfile gfwlist.action

Finally, make sure that forward rules are not set in `/etc/privoxy/config`,
which is the default, unless you know what you're doing.

Privoxy should automatically pick up the new config. Now just point your program
to Privoxy (`localhost:8118` by default), who will automatically determine
whether to forward to SOCKS or not.

License
-------

This program is in the public domain.

Links
-----

* [AutoProxy Rules](https://autoproxy.org/zh-CN/Rules)
* [Privoxy Patterns](http://www.privoxy.org/user-manual/actions-file.html#AF-PATTERNS)
* [Set Up SSH to Bypass GFW - The Definitive Guide](http://cckpg.blogspot.com/2011/05/set-up-ssh-to-bypass-gfw-definitive.html#privoxy-as-http-proxy)
