#!/usr/bin/gawk -E
# Convert AutoProxy/GFWList rules to Privoxy actions file.
# Reference: https://github.com/gfwlist/gfwlist/wiki/Syntax
# Reference: http://www.privoxy.org/user-manual/actions-file.html#AF-PATTERNS
# Requires Gawk

BEGIN {
  FS = "/"
  if (!proxy) { proxy = "socks5://127.0.0.1:9050" }
  split(proxy, a, /:\/\/|:|\s+/)
  i = sprintf("-%s", a[1]); j = " ."
  if (a[1] == "http") { i = ""; j = "" }
  action[0] = sprintf("{+forward-override{forward%s %s:%s%s}}", i, a[2], a[3], j)
  action[1] = "{-forward-override}"
  patset[0][""]; delete patset[0][""]
  patset[1][""]; delete patset[1][""]
  # Add custom privoxy patterns here
  patset[0][".onion"]
}

/^! Title: / {
  sub(/^! Title: /, "")
  info["GFWList:"] = $0
  next
}

/^! Last Modified: / {
  sub(/^! Last Modified: /, "")
  info["Updated:"] = $0
  next
}

/^[![]|^\s*$/ { next } # ignored

{ i = 0; orig = $0 }

/^@@/ { # excluded
  i = 1
  sub(/^@@/, "")
}

/^([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])){3}(:[0-9]+)?$/ { # IP address
  patset[i][$0]
  next
}

# Special case for that long-ass google line:
# /^https?:\/\/([^\/]+\.)*google\.(ac|ad|...|vu|ws)\/.*/
index($0, "/^https?:\\/\\/([^\\/]+\\.)*google\\.(") == 1 {
  $0 = substr($0, 34)
  sub(/......$/, "")
  split($0, a, /\|/)
  for (j in a) {
    patset[i][sprintf(".google.%s", a[j])]
    # Remove redundant patterns
    delete patset[i][sprintf("google.%s:80", a[j])]
    delete patset[i][sprintf(".google.%s:80", a[j])]
    delete patset[i][sprintf("*.google.%s:80", a[j])]
    delete patset[i][sprintf("google.%s:443", a[j])]
    delete patset[i][sprintf(".google.%s:443", a[j])]
    delete patset[i][sprintf("*.google.%s:443", a[j])]
  }
  next
}

# Convert (rare) regexp patterns to domain patterns
# /^https?:\/\/[^\/]+blogspot\.(.*)/ => ||blogspot.*
/^\/\^https\?:\\\/\\\/\[\^\\\/\]\+[^/]+\/$/ {
  $0 = substr($0, 20)
  sub(/\/$/, "")
  gsub(/[()]/, "")
  gsub(/\.\*/, "*")
  gsub(/\.\+/, "?*")
  gsub(/\\/, "")
  sub(/^/, "||")
}

/^\/.*\/$/ {
  unhandled["regexp"][orig]
  next
}

# ||foo*.bar => .foo*.bar
/^\|\|/ { # domain
  host = substr($1, 3)
  sub(/^\.*/, "", host)
  patset[i][sprintf(".%s", host)]
  # Remove redundant patterns
  delete patset[i][sprintf("%s:80", host)]
  delete patset[i][sprintf(".%s:80", host)]
  delete patset[i][sprintf("*.%s:80", host)]
  delete patset[i][sprintf("%s:443", host)]
  delete patset[i][sprintf(".%s:443", host)]
  delete patset[i][sprintf("*.%s:443", host)]
  next
}

# Fix up broken patterns
/^https?:\/\// {
  sub(/^/, "|")
}

# NOTE We simply ignore the :80/keyword reset case. (Go! HTTPS! Yay!)
# Support patterns which are basically missing |http://.
# Don't try to fix broken patterns such as:
# .bbc.co.uk*chinese
# .bbc.co*zhongwen
# bbs.sina.com%2F
# q%3Dfreedom
/\./ &&
/^([[:alnum:]._~-]|[!'*+,;&=])+(\/([[:alnum:]._~-]|%[[:xdigit:]]{2}|[!'*+,;&=]|[@:])*(\?([[:alnum:]._~-]|%[[:xdigit:]]{2}|[!'*+,;&=]|[@/?:])*)?(#([[:alnum:]._~-]|%[[:xdigit:]]{2}|[!'*+,;&=]|[@/?:])*)?)*$/ { # pattern
  sub(/^/, "|http://")
}

# |http://foo.bar/*?q=x+y => foo.bar:80/.*\?q=x\+y
# |https://cdn*.foo.bar => cdn*.foo.bar:443
/^\|https?:\/\// { # start of URL
  port = $1 == "|http:" ? 80 : 443
  sub(/^\|https?:\/\//, "")
  host = $1
  $0 = substr($0, length(host) + 1) # path
  sub(/\/$/, "")
  # Ignore broken rules
  j = split(host, a, /\./)
  if (!j || (!$0 && a[j] ~ /\*$/) || a[j] ~ /%|\*./) {
    unhandled["broken"][orig]
    next
  }
  gsub(/[].?+(|)[]/, "\\\\&")
  gsub(/\*/, ".*")
  sub(/^\*\./, ".", host)
  # Don't add redundant patterns
  if ((keyword ? 1 : !$0) &&
      !(sprintf("%s", host) in patset[i]) &&
      !(sprintf(".%s", host) in patset[i]) &&
      !(sprintf("%s:%s", host, port) in patset[i]) &&
      !(sprintf(".%s:%s", host, port) in patset[i]) &&
      !(sprintf(".%s:%s%s", host, port, $0) in patset[i])) {
    patset[i][sprintf("%s:%s%s", host, port, $0)]
  }
  next
}

{
  unhandled["pattern"][orig]
}

END {
  # Remove custom privoxy patterns here (false positives)
  #delete patset[0][""]
  for (i in info) {
    print "#", i, info[i]
  }
  for (i=0;i<2;++i) {
    asorti(patset[i])
    print action[i]
    for (j in patset[i]) {
      print patset[i][j]
    }
  }
  if (!verbose) {
    exit
  }
  for (i in unhandled) {
    if (!isarray(unhandled[i]))
      continue
    asorti(unhandled[i])
    print "WARNING: unhandled " i > "/dev/stderr"
    for (j in unhandled[i]) {
      print unhandled[i][j] > "/dev/stderr"
    }
  }
}
