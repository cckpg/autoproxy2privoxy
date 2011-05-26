AutoProxy2Privoxy
=================

Overview
--------

AutoProxy2Privoxy generates a list of privoxy forward rules from a set of
AutoProxy rules.

AutoProxy is an firefox addon that automatically determines which URLs are to
be requested through a proxy, according to a predefined list of rules.

The AutoProxy2Pac program can produce a Proxy Auto-Config file out of the
AutoProxy ruleset, to be used by all browsers that support PAC.

Privoxy, with forward rules set up correctly, can be used as a Proxy Auto-Config
replacement, with the benefit of being universal for any program that uses the
proxy.

Another advantage of using privoxy is that, when forwarding to a SOCKS4a/SOCKS5
proxy, privoxy will request the DNS resolution to happen on the remote side.
This is beneficial for programs that do not support remote DNS resolution.

Inspired by AutoProxy2Pac, powered by Privoxy, and motivated by GFW, here,
ladies and gentlemen, I present you AutoProxy2Privoxy!

How to Build
------------

AutoProxy2Privoxy is a BASH script and needs not be built. This section talks
about how to build the privoxy forward rules from an AutoProxy ruleset.

The following example assumes a Linux environment. Also the famous gfwlist is
used as the autoproxy ruleset input in the example below.

    gfwlist=https://autoproxy-gfwlist.googlecode.com/svn/trunk/gfwlist.txt
    wget -qO- "${gfwlist}" | base64 -d > gfwlist.txt
    export PROXY_ADDR=127.0.0.1:7127 PROXY_TYPE=SOCKS5
    chmod +x autoproxy2privoxy
    ./autoproxy2privoxy gfwlist.txt > gfw.action

Behold, this last command runs for a while.

How to Use
----------

Privoxy supports all major operating systems.  Installation paths may vary from
platform to platform. The following assumes a Linux environment.

First, make sure the address and type of the target proxy is set correctly in
gfw.action:

    {+forward-override{forward-socks5 127.0.0.1:7127 .}}

Then issue the following commands as root::

    cp gfw.action /etc/privoxy/
    chown privoxy:privoxy /etc/privoxy/gfw.action
    chmod 660 /etc/privoxy/gfw.action

Now edit `/etc/privoxy/config`, adding this line::

    actionsfile gfw.action

Finally, make sure that forward rules are not set in `/etc/privoxy/config`,
which is the default, unless you know what you're doing.

Privoxy should automatically pick up the new config. Now just point your program
to privoxy, who will automatically determine whether to forward to SOCKS or not.

License
-------

This program is in the public domain, looking for a trade for a more robust
implementation.

Fork the idea, guys.

Links
-----

[AutoProxy Rules](https://autoproxy.org/zh-CN/Rules)
[Privoxy Patterns](http://www.privoxy.org/user-manual/actions-file.html#AF-PATTERNS)
