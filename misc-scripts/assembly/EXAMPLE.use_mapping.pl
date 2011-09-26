#!/usr/local/ensembl/bin/perl

=head1 NAME

EXAMPLE.use_mapping.pl - example script for projecting features from one
assembly to another

=head1 SYNOPSIS

EXAMPLE.use_mapping.pl [arguments]

Required arguments:

  --host=hOST                 database host HOST
  --port=PORT                 database port PORT
  --user=USER                 database username USER
  --pass=PASS                 database passwort PASS
  --dbname=NAME               database name NAME
  --infile=FILE               read input data from FILE
  --old_assembly=NAME         old assembly NAME
  --new_assembly=NAME         new assembly NAME

=head1 DESCRIPTION

This is an example script illustrating how to use a mapping between two
assemblies for a species, as generated by the scripts in this directory. At the
time of writing, this mapping was available for human and mouse.

The script assumes that your input data are features in old assembly
coordinates which you want to transform into new assembly coordinates (i.e.
project the features onto the new assembly) and store in an Ensembl database.
The input data in this example is read from a file with the format

# NAME:CHROMOSOME:START:END:STRAND
feat_1:X:200:5000:1
feat_2:X:6000:7040:-1
...


The example also includes some sanity check you might want to do on your
projections. It will depend on your use case whether you want to use them or
not (you might need either more or less restrictive conditions).

=head1 LICENCE

This code is distributed under an Apache style licence. Please see
http://www.ensembl.org/info/about/code_licence.html for details.

=head1 AUTHOR

Patrick Meidl <meidl@ebi.ac.uk>, Ensembl core API team

=head1 CONTACT

Please post comments/questions to the Ensembl development list
<dev@ensembl.org>

=cut

use strict;
use warnings;
no warnings 'uninitialized';

use Getopt::Long;
use Bio::EnsEMBL::SimpleFeature;
use Bio::EnsEMBL::Analysis;
use Bio::EnsEMBL::DBSQL::DBAdaptor;

$| = 1;

my ($host, $port, $user, $pass, $dbname, $infile, $old_assembly, $new_assembly);

GetOptions(
    "host=s",          \$host,
    "port=i",          \$port,
    "user=s",          \$user,
    "pass=s",          \$pass,
    "dbname=s",        \$dbname,
    "infile=s",        \$infile,
    "old_assembly=s",  \$old_assembly,
    "new_assembly=s",  \$new_assembly
);

# connect to database and get adaptors
my $db = new Bio::EnsEMBL::DBSQL::DBAdaptor(
    -HOST     => $host,
    -PORT     => $port,
    -USER     => $user,
    -PASS     => $pass,
    -DBNAME   => $dbname,
);

my $sa = $db->get_SliceAdaptor();

# create an analysis for the type of feature you wish to store
my $analysis = new Bio::EnsEMBL::Analysis(
    -LOGIC_NAME => 'your_analysis'
);

# read your input data
open(FILE, "<$infile") or die("Can't open $infile for reading: $!");

while (<FILE>) {

  # skip comments
  next if (/^#/);

  my ($name, $chr, $start, $end, $strand) = split(/:/);

  # get a slice on the old assembly
  my $slice_oldasm = $sa->fetch_by_region('chromosome', $chr, undef, undef,
    undef, $old_assembly);

  if (!$slice_oldasm) {
    warn "Can't get $old_assembly slice for $chr:$start:$end\n";
    next;
  }

  # create a new feature on the old assembly
  my $feat = Bio::EnsEMBL::SimpleFeature->new(
      -DISPLAY_LABEL  => $name,
      -START          => $start,
      -END            => $end,
      -STRAND         => $strand,
      -SLICE          => $slice_oldasm,
      -ANALYSIS       => $analysis,
  );

  # project feature to new assembly
  my @segments = @{ $feat->feature_Slice->project('chromosome', $new_assembly) };

  # do some sanity checks on the projection results:
  # discard the projected feature if
  #   1. it doesn't project at all (no segments returned)
  #   2. the projection is fragmented (more than one segment)
  #   3. the projection doesn't have the same length as the original
  #      feature

  # this tests for (1) and (2)
  next unless (scalar(@segments) == 1);

  # test (3)
  my $proj_slice = $segments[0]->to_Slice;
  next unless ($feat->length == $proj_slice->length);

  next unless ($proj_slice->seq_region_name eq $feat->slice->seq_region_name);

  # everything looks fine, so adjust the coords of your feature
  $feat->start($proj_slice->start);
  $feat->end($proj_slice->end);
  my $slice_newasm = $sa->fetch_by_region('chromosome', $chr, undef, undef,
    undef, $new_assembly);
  $feat->slice($slice_newasm);

  # store the feature
  $feat->store;

}

close(FILE);

