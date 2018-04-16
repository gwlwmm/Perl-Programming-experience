#!/usr/bin/perl
use JSON;
use IO::File;

sub create_big_hash {
    my $hash = {};
    for (my $i = 0 ; $i < 1500 ; $i++) {
        for (my $u = 0 ; $u < 100 ; $u++) {
            $hash->{$i}->{users}->{"testuser_$u"}->{role} = "inherit";
        }
    }
    return $hash;
}

sub main {
    my $hash = create_big_hash();
    my $fh = IO::File->new("big-json.json", O_WRONLY | O_CREAT, 0644);
    if ($fh) {
        print $fh to_json($hash, pretty => 1);
        close($fh);
    }
}

main();
