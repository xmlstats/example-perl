Perl Example
============

A simple example that accesses the [xmlstats](https://erikberg.com/api) API
using Perl. This example grabs a list of active NBA teams, makes a request
for each team's roster, and prints.

Requirements
------------
To run this program, you will need Perl 5.x with Config::Tiny, HTTP::Status, JSON,
LWP::UserAgent, URI::Escape, Crypt::SSLeay modules installed, and an xmlstats account.

Getting Started
---------------
Clone the repository.

### Configure
Specify your API access token and e-mail address in `xmlstats.conf`.

### Run
```
perl roster.pl
```

