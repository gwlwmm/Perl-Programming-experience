#!/usr/bin/perl
use VTP::Common::Exception;
use VTP::Common::Log;
use Frontier::Client;
use Cwd;
use File::Basename;
use plog;
use Time::HiRes;
my $debug = shift;
my $client = Frontier::Client->new('url' => "http://127.0.0.1:10002/RPC2");
my $ret = $client->call('debug', $debug);
