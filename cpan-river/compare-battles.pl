# perl
use strict;
use warnings;
use 5.10.1;
use Data::Dumper;$Data::Dumper::Indent=1;
use Data::Dump qw( dd pp );
use Carp;
use List::Compare;


my $f1 = 'order-of-battle-20170330.txt';
my $f2 = 'order-of-battle-20170401.txt';
my ($seen1, $seen2);
$seen1 = parse_one_battle($f1);
$seen2 = parse_one_battle($f2);
my $lcsh = List::Compare->new($seen1, $seen2);
my @Lonly = $lcsh->get_unique();
my @Ronly = $lcsh->get_complement();
my @int   = $lcsh->get_intersection();
dd(\@Lonly, \@Ronly, \@int);

sub parse_one_battle {
    my $file = shift;
    my %seen;
    open my $IN, '<', $file or croak "Unable to open $file";
    while (my $l = <$IN>) {
        chomp $l;
        #say $l;
        my ($rank, $module, $freq) = $l =~ m/^\s{0,2}(\d+)\s+?(\S+)\s+(\d+)$/;
        $seen{$module} = $freq;
    }
    close $IN or croak "Unable to close $file";
    return \%seen;
}

