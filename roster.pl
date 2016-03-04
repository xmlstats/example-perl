#!/usr/bin/perl -w

use strict;

use Config::Tiny;
use HTTP::Status;
use JSON;
use LWP::UserAgent;
use URI::Escape;
require Crypt::SSLeay;

my $config = Config::Tiny->read('xmlstats.conf');

my $json = JSON->new->allow_nonref;

main();

sub main {
    # See https://erikberg.com/api/endpoints#requrl
    my $host   = "erikberg.com";
    my $sport  = "nba";
    my $method = "teams";
    my $id     = undef;
    my $format = "json";
    my %parameters = ();

    my $url = build_url($host, $sport, $method, $id, $format, %parameters);

    my ($data, $xmlstats_remaining, $xmlstats_reset) = http_get($url);

    my $teams = $json->decode($data);
    for my $team (@{$teams}) {
        # If no more requests are available in current window, wait.
        # Important: make sure your system is using NTP or equivalent, otherwise
        # this will produce incorrect results.
        if ($xmlstats_remaining == 0) {
            my $now = time;
            my $delta = $xmlstats_reset - $now;
            print "Reached rate limit. Waiting $delta seconds to make new request\n";
            sleep($delta);
        }
        $url = build_url($host, $sport, 'roster', $team->{team_id}, 'json', ());
        ($data, $xmlstats_remaining, $xmlstats_reset) = http_get($url);
        my $roster = $json->decode($data);
        # Process roster data... In this example, we are just printing each roster
        print "$roster->{team}->{first_name} $roster->{team}->{last_name} Roster\n";
        for my $player (@{$roster->{players}}) {
            printf("%25s, %-2s %5s %3s lb\n",
                    $player->{display_name},
                    $player->{position},
                    $player->{height_formatted},
                    $player->{weight_lb});
        }
    }
}

sub http_get {
    my ($url) = @_;
    my $access_token = $config->{_}->{access_token};
    my $user_agent = sprintf("xmlstats-expl/%s (%s)",
        $config->{_}->{version}, $config->{_}->{user_agent_contact});

    my $ua = LWP::UserAgent->new;
    $ua->default_header("Authorization" => "Bearer $access_token");
    $ua->agent($user_agent);

    my $req = HTTP::Request->new(GET => $url);
    $req->accept_decodable;

    my $res = $ua->request($req);
    my $rc = $res->code;
    if ($res->is_success) {
        my $xmlstats_remaining = $res->header("xmlstats-api-remaining");
        my $xmlstats_reset = $res->header("xmlstats-api-reset");
        my $data = $res->decoded_content;
        return ($data, $xmlstats_remaining, $xmlstats_reset);
    } else {
        print STDERR "Error retrieving file: $rc.\n";
        print STDERR $res->decoded_content;
        exit(1);
    }
}

# See https://erikberg.com/api/methods Request URL Convention for
# an explanation
sub build_url {
    my ($host, $sport, $method, $id, $format, %parameters) = @_;
    my ($path) = join("/", grep(defined, ($sport, $method, $id)));
    my $url = "https://" . $host . "/" . $path . "." . $format;

    # check for parameters and create parameter string
    if (%parameters) {
        my @paramlist;
        for my $key (sort keys %parameters) {
            push @paramlist, uri_escape($key) . "=" . uri_escape($parameters{$key});
        }
        my $paramstring = join("&", @paramlist);
        if (@paramlist) { $url .= "?" . $paramstring }
    }
    return $url;
}
