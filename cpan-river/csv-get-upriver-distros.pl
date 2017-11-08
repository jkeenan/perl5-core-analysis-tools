#!/usr/bin/env perl
use 5.12.0;
use warnings;
use Data::Dump qw( dd pp );
use Carp;
use Text::CSV;
use Getopt::Long;
use Cwd;

my ($target_count, $inputfile, $outputdir, $outputfile, $verbose) = ('') x 4;
GetOptions(
    "count=i"       => \$target_count,
    "input=s"       => \$inputfile,
    "outputdir=s"   => \$outputdir,
    "output=s"      => \$outputfile,
    "verbose"       => \$verbose,
) or die("Error in command line arguments: $!");

$target_count ||= 1000;
$inputfile ||= 'cpan.river.csv';
$outputdir ||= cwd();

# Retain an 8-digit datestamp from input, if provided
my ($YYYYMMDD) = $inputfile =~ m/(\d{8})/;
unless ($YYYYMMDD) {
    my @lt = localtime(time);
    $YYYYMMDD = sprintf("%04d%02d%02d" => (
        $lt[5] + 1900,
        $lt[4] + 1,
        $lt[3]
    ) );
}

$outputfile ||= "$outputdir/${YYYYMMDD}-top-${target_count}.txt";

if ($verbose) {
    say "Input:   $inputfile";
    say "Output:  $outputfile";
    say "Count:   $target_count";
}

my $csv = Text::CSV->new ( { binary => 1 } )
    or croak("Cannot use CSV: ".Text::CSV->error_diag ());
 
open my $IN, "<:encoding(utf8)", $inputfile or croak "Unable to open '$inputfile' for reading";
my $headerref = $csv->getline($IN);
$csv->column_names(@{$headerref});
#pp($headerref) if $verbose;

my $bad_distros = qr/(
        mod_perl
        | Apache
        | Term-ReadLine-Perl
        | X11-Protocol        # Requires human to click in pop-up window
        | Test-WWW-Simple     # mojolicious server fails to close
        | App-SimpleScan      # depends on Test-WWW-Simple
        | POE-Component-Child # test hangs indefinitely
    )/ix;

my @distros = ();
while ( my $row = $csv->getline_hr($IN) ) {
    next if $row->{core_upstream_status};
    next if $row->{distribution} eq 'perl';
    next if $row->{distribution} =~ m/$bad_distros/;
    next unless $row->{count};
    my $module = $row->{distribution};
    $module =~ s/-/::/g;
    push @distros, [ $row->{distribution}, $row->{count}, $module ];
}
close $IN or croak "Unable to close '$inputfile' after reading";
#pp(\@distros);

open my $OUT, '>', $outputfile or croak "Unable to open $outputfile for writing";
say $OUT "$_->[2]" for @distros[0 .. ($target_count - 1)];
close $OUT or croak "Unable to close $outputfile after writing";

say "Finished" if $verbose;
