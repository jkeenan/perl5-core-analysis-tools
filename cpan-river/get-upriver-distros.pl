# perl
use strict;
use warnings;
use 5.10.1;
use Data::Dumper;$Data::Dumper::Indent=1;
use Data::Dump qw( dd pp );
use Carp;
use Cwd;
use IO::File;

my $cwd = cwd();

croak "Must supply positive integer as command-line argument"
    unless (@ARGV == 1 and $ARGV[0] =~ m/^\d+$/ and $ARGV[0]);

my $target_count = shift(@ARGV);
my @distros = ();
# Ideally, I'd like this file to be pre-purged of mod_perl's revdeps
my $file = "$cwd/river-2016-02-27.txt";

my $IN = IO::File->new($file, 'r');
croak "Unable to open $file" unless defined $IN;

while (my $l = <$IN>) {
    chomp $l;
    next if $l =~ m/<(?:blead|cpan)-upstream>/;
    next unless $l =~ m/^\s*(\d+)\s(\S+)/;
    my ($depcount, $distro) = ($1,$2);
    next if $distro eq 'perl';
    # need to add Term-ReadLine-Perl's revdeps
    next if $distro =~ m/(
        mod_perl
        | Apache
        | Term-ReadLine-Perl
        | X11-Protocol        # Requires human to click in pop-up window
        | Test-WWW-Simple     # mojolicious server fails to close
        | App-SimpleScan      # depends on Test-WWW-Simple
        | POE-Component-Child # test hangs indefinitely
    )/ix;
    my $module = $distro;
    $module =~ s/-/::/g;
    push @distros, [ $distro, $depcount, $module ];
}
$IN->close or croak "Unable to close $file after reading";
say STDOUT "$_->[2]" for @distros[0 .. ($target_count - 1)];

say STDERR "Finished";
