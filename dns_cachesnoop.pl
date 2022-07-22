#!/usr/bin/env perl
# Description: Performs DNS cache snooping against a DNS server
# Depends on:  nmap p5-net-dns
#
# (c) 2020 Alexandr Savca, alexandr dot savca89 at gmail dot com

use strict;
use warnings;
use Getopt::Long;
use Net::DNS;

BEGIN { $" = ',' }

sub usage {
    print <<EOF;
Performs DNS cache snooping against a DNS server.

Usage: $0 [OPTIONS] <TARGET>

where OPTIONS are:

-h|--help

This message.

-m|--mode <0|nonrecursive>

Queries are sent to the server with the RD (recursion desired) flag set
to 0.  The server should respond positively to these only if it has the
domain cached.  The default mode.

-m|--mode <1|timed>

The mean and standard deviation response times for a cached domain are
calculated by sampling the resolution of a name (www.google.com)
several times.

-t|--tcp / -u|--udp

Connect via TCP/UDP or both.
Default is UDP.

-p|--port

Connection port.

-d|--domains <DOMAINS|WORDLIST>

An array of domain (separated by comma) to check in place of the
default list.  The default list of domains to check consists of the
top 50 most popular sites, each site being listed twice, once with
"www." and once without.

Ex.: -d www.google.com,www.yahoo.com,google.com,yahoo.com
     -d ~/wordlist.txt

<TARGET>

DNS server to perform DNS cache snooping for.

EOF
    exit +shift;
}

my %OPTS;
GetOptions(
    'h|help!'       =>  \$OPTS{help},
    'v|verbose!'    =>  \$OPTS{verbose},
    't|tcp!'        =>  \$OPTS{tcp},
    'u|udp!'        =>  \$OPTS{udp},
    'p|port=i'      =>  \$OPTS{port},
    'm|mode=s'      =>  \$OPTS{mode},
    'd|domains=s'   =>  \$OPTS{domains},
) or die;
usage(1)     if $OPTS{help};
usage(2) unless @ARGV;

die "The script must run as root!\n" if $> != 0;

if ($OPTS{domains} && -f $OPTS{domains}) {
    print "Found wordlist: $OPTS{domains}.\n";

    my @domain_list;
    open my $fh, $OPTS{domains};
    while (<$fh>) {
        chomp;
        push @domain_list, $_;
    }
    close $fh;

    $OPTS{domains} = "@domain_list";
}

# default values
$OPTS{mode} //= 'nonrecursive';
$OPTS{mode}   = 'nonrecursive' if $OPTS{mode} eq 0;
$OPTS{mode}   = 'timed'        if $OPTS{mode} eq 1 || \
                                  $OPTS{mode} eq 'timed';
$OPTS{target} = shift;
$OPTS{port} //= 53;
$OPTS{udp}  //= 1 unless $OPTS{tcp};

$OPTS{args}  .= ' -d  ' if $OPTS{verbose};
$OPTS{args}  .= ' -sU ' if $OPTS{udp};
$OPTS{args}  .= ' -sT ' if $OPTS{tcp};

$OPTS{args}  .= ' -p'.$OPTS{port};

$OPTS{script} = '--script dns-cache-snoop.nse ';

$OPTS{script_args}  = "--script-args 'dns-cache-snoop.mode=$OPTS{mode}";

$OPTS{script_args} .= ",dns-cache-snoop.domains={$OPTS{domains}}"
                    if $OPTS{domains};

$OPTS{script_args} .= "'";

print \
">>> nmap $OPTS{args} $OPTS{script} $OPTS{script_args} $OPTS{target}\n";
print qx(
    nmap $OPTS{args} $OPTS{script} $OPTS{script_args} $OPTS{target}
);

# vim:sw=4:ts=4:sts=4:et:tw=71:cc=72
# End of file.
