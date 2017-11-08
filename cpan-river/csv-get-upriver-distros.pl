#!/usr/bin/env perl
use 5.12.0;
use warnings;
use Data::Dump qw( dd pp );
use Carp;
use Text::CSV;
use Getopt::Long;
use Cwd;

=head1 NAME

csv-get-upriver-distros.pl

=head1 USAGE

=over 4

=item * Typical

    csv-get-upriver-distros.pl --input=20171107.cpan.river.csv --count=2000 --verbose 

Output will be written in current directory to file named 20171107-top-2000.txt.

=item * Specify output directory

    csv-get-upriver-distros.pl --input=20171107.cpan.river.csv --count=2000 --verbose \
        outputdir=/path/to/output

=item * Specify output filename

    csv-get-upriver-distros.pl --input=20171107.cpan.river.csv --count=2000 --verbose \
        output=/path/to/output/my-output.txt

=back

=head1 PREREQUISITES

=head2 From CPAN 

    Data::Dump
    Text::CSV

=head2 Input file

A CSV file, typically named something like F<20171107.cpan.river.csv>, with the following format:

    count,distribution,core_upstream_status,maintainers,top_5_downstream
    28296,perl,,,"Carp:28278 ExtUtils-MakeMaker:28278 File-Path:28278 File-Temp:28278 PathTools:28278"
    28278,Carp,blead-upstream,"DAPM DOM FLORA JESSE LBROCARD NWCLARK P5P RJBS ZEFRAM","Exporter:28278 File-Path:28278 File-Temp:28278 PathTools:28278 Pod-Simple:28278"
    28278,Data-Dumper,blead-upstream,"EDAVIS GSAR ILYAM P5P SMUELLER","ExtUtils-MakeMaker:28278 CPAN-Meta:15945 ExtUtils-Manifest:15087 Module-Build:14986 ExtUtils-Config:8672"
    28278,Encode,cpan-upstream,DANKOGAI,"ExtUtils-MakeMaker:28278 podlators:28278 CPAN-Meta:15945 URI:8582 Encode-Locale:7566"

This file would typically be the output of F<compute_downstream_dag.pl>.

=cut

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

my %modules4distros = (
    'libwww-perl'   => 'LWP',
);
my @distros = ();
while ( my $row = $csv->getline_hr($IN) ) {
    next if $row->{core_upstream_status};
    next if $row->{distribution} eq 'perl';
    next if $row->{distribution} =~ m/$bad_distros/;
    next unless $row->{count};
    my $module;
    if ($modules4distros{$row->{distribution}}) {
        $module = $modules4distros{$row->{distribution}};
    }
    else {
        $module = $row->{distribution} =~ s/-/::/gr;
    }
    push @distros, [ $row->{distribution}, $row->{count}, $module ];
}
close $IN or croak "Unable to close '$inputfile' after reading";
#pp(\@distros);

open my $OUT, '>', $outputfile or croak "Unable to open $outputfile for writing";
say $OUT "$_->[2]" for @distros[0 .. ($target_count - 1)];
close $OUT or croak "Unable to close $outputfile after writing";

say "Finished" if $verbose;
