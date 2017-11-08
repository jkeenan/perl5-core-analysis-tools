# perl
use strict;
use warnings;
use 5.10.1;
use Data::Dumper;$Data::Dumper::Indent=1;
use Data::Dump qw( dd pp );
use Carp;
use Cwd;
use IO::File;
use Text::CSV;

my $cwd = cwd();

croak "Must supply positive integer as command-line argument"
    unless (@ARGV == 1 and $ARGV[0] =~ m/^\d+$/ and $ARGV[0]);

my $target_count = shift(@ARGV);

=pod

my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
                     or die "Cannot use CSV: ".Text::CSV->error_diag ();
 
     open my $fh, "<:encoding(utf8)", "test.csv" or die "test.csv: $!";
     while ( my $row = $csv->getline( $fh ) ) {
         $row->[2] =~ m/pattern/ or next; # 3rd field should match
         push @rows, $row;
     }
     $csv->eof or $csv->error_diag();
     close $fh;

count,distribution,core_upstream_status,maintainers,top_3_downstream
27572,perl,,,"PathTools:27554 Test-Simple:27554 Carp:27554 Pod-Simple:27554 Pod-Escapes:27554"
27554,Carp,blead-upstream,"DAPM DOM FLORA JESSE LBROCARD NWCLARK P5P RJBS ZEFRAM","File-Path:27554 PathTools:27554 File-Temp:27554 Exporter:27554 Pod-Simple:27554"
27554,Data-Dumper,blead-upstream,"EDAVIS GSAR ILYAM P5P SMUELLER","ExtUtils-MakeMaker:27554 CPAN-Meta:15702 ExtUtils-Manifest:14885 Module-Build:14784 ExtUtils-Config:8432"
27554,Encode,cpan-upstream,DANKOGAI,"podlators:27554 ExtUtils-MakeMaker:27554 CPAN-Meta:15702 Encode-Locale:7319 IO-HTML:7302"

=cut

my @distros = ();
my $file = "$cwd/cpan.river.20170409.csv";

my $csv = Text::CSV->new ( { binary => 1 } )
    or croak("Cannot use CSV: ".Text::CSV->error_diag ());
 
open my $IN, "<:encoding(utf8)", $file or croak "Unable to open '$file' for reading";
my $headerref = $csv->getline($IN);
$csv->column_names(@{$headerref});
pp($headerref);
#my $row = $csv->getline_hr($IN);
#pp($row);
while ( my $row = $csv->getline_hr($IN) ) {
    next if $row->{core_upstream_status};
    next if $row->{distribution} eq 'perl';
    next if $row->{distribution} =~ m/(mod_perl|Apache|Term-ReadLine-Perl)/i;
    next unless $row->{count};
    my $module = $row->{distribution};
    $module =~ s/-/::/g;
    push @distros, [ $row->{distribution}, $row->{count}, $module ];
}
close $IN or croak "Unable to close '$file' after reading";
say STDOUT "$_->[2]" for @distros[0 .. ($target_count - 1)];

say STDERR "Finished";


__END__
my $IN = IO::File->new($file, 'r');
croak "Unable to open $file" unless defined $IN;

while (my $l = <$IN>) {
    chomp $l;
    next if $l =~ m/<(?:blead|cpan)-upstream>/;
    next unless $l =~ m/^\s*(\d+)\s(\S+)/;
    my ($depcount, $distro) = ($1,$2);
    next if $distro eq 'perl';
    next if $distro =~ m/(mod_perl|Apache|Term-ReadLine-Perl)/i;
    my $module = $distro;
    $module =~ s/-/::/g;
    push @distros, [ $distro, $depcount, $module ];
}
$IN->close or croak "Unable to close $file after reading";
say STDOUT "$_->[2]" for @distros[0 .. ($target_count - 1)];

say STDERR "Finished";
