#!/usr/bin/env perl
use 5.12.0;
use warnings;
use Data::Dump qw( dd pp );
use Carp;
use Text::CSV;
use Getopt::Long;
use Cwd;

=head1 NAME

collate-fails.pl - Classify FAIL lines in build log

=head1 USAGE

    collate-fails.pl \
        --inputdir=/home/jkeenan/learn/perl/cpan-river/20171107 \
        --inputfile=20171108-2000-build.log.gz \
        --verbose

=head1 PREREQUISITES

=head2 From CPAN 

    Data::Dump
    Text::CSV

=head2 Input file

A cpanm build.log, gzipped, typically named something like 20171108-2000-build.log.gz.  We will F<zgrep> this file for C<FAIL>, then sort and classify the output into a Perl data structure or output file.

=cut

my ($inputfile, $inputdir, $outputfile, $outputdir, $verbose) = ('') x 5;
GetOptions(
    "inputdir=s"    => \$inputdir,
    "inputfile=s"   => \$inputfile,
    "outputdir=s"   => \$outputdir,
    "outputfile=s"  => \$outputfile,
    "verbose"       => \$verbose,
) or die("Error in command line arguments: $!");

croak "Could not locate input directory $inputdir" unless (-d $inputdir);
croak "Input file $inputfile lacks '.gz' extension"
    unless ($inputfile =~ m/\.gz$/);
my $finputfile = "$inputdir/$inputfile";
croak "Could not locate input file $finputfile" unless (-f $finputfile);
$outputdir ||= $inputdir;
croak "Could not locate output directory $outputdir" unless (-d $outputdir);

if ($verbose) {
    say "Input directory:   $inputdir";
    say "Input file:        $inputfile";
    say "Output directory:  $outputdir";
    say "Output file:       $outputfile" if (length($outputfile));
}

my $intermed = "$outputdir/intermed1.txt";
system(qq(zgrep FAIL $finputfile | sed -e 's/^-> FAIL //' | sort -u > $intermed))
    and croak "Unable to zgrep $inputfile";

my %rationales = ();
open my $IN, '<', $intermed or croak "Unable to open $intermed for reading";
while (my $l = <$IN>) {
    chomp $l;
    if ($l =~ m/^Bailing out the installation for (.*?)\.$/) {
        push @{$rationales{bailing}}, $1;
    }
    elsif ($l =~ m/^Configure failed for (.*?)\.\s+See/) {
        push @{$rationales{configure}}, $1;
    }
    elsif ($l =~ m/^Couldn't find module or a distribution (.*)/) {
        push @{$rationales{nofind}}, $1;
    }
    elsif ($l =~ m/^Failed to fetch distribution (.*)/) {
        push @{$rationales{nofetch}}, $1;
    }
    elsif ($l =~ m/^Finding (.*?)\s+on cpanmetadb failed/) {
        push @{$rationales{nofind}}, $1;
    }
    elsif ($l =~ m/^Finding (.*?)\s+\(\)\s+on mirror file\s.*?\sfailed/) {
        push @{$rationales{nofind}}, $1;
    }
    elsif ($l =~ m/^Installing (.*?)\s+failed\./) {
        push @{$rationales{install}}, $1;
    }
    elsif (my (@multiple) = $l =~ m/^Installing the dependencies failed:\sModule\s'([^']+?)'\sis\snot\sinstalled(?:,\sModule\s'([^']+?)'\sis\snot\sinstalled)*/) {
        pp(\@multiple);
        push @{$rationales{dependencies}}, grep { defined $_ } @multiple;
    }
    #    Installing the dependencies failed: Module 'AnyEvent::CacheDNS' is not installed, Module 'AnyEvent' is not installed, Module 'AnyEvent::HTTP' is not installed
}
close $IN or croak "Unable to close $intermed after reading";
#pp(\%rationales);
pp($rationales{dependencies});

say "Finished!" if $verbose;
