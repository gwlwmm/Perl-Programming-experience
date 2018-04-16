#!/usr/bin/perl
use JSON;
use IO::File;

sub func {
    my ($data) = @_;
    my $hash = from_json($data);
    undef $hash;
}

sub test_hash {
    my ($data) = @_;
    while (1) {
        func($data);
        sleep 5;
    }
}

=JSON::Parse
use JSON::Parse 'parse_json';
sub test_hash_json_parse {
    my ($data) = @_;
    while (1) {
        parse_json ($data);
        #my $hash = parse_json ($data);
        #undef $hash;
        sleep 5;
    }
}
=cut

sub main {
    my $fh = IO::File->new("big-json.json", "r");
    die "open failed $!" unless $fh;
    #sleep 5;
    my $data;
    sysread($fh, $data, 1024*1024*20, 0);
    close($fh);
    
    sleep 5;
    test_hash($data);
}

main();
