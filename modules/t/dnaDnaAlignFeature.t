
use lib 't';

BEGIN { $| = 1;  
	use Test;
	plan tests => 63;
}

use MultiTestDB;
use Bio::EnsEMBL::DnaDnaAlignFeature;
use Bio::EnsEMBL::SeqFeature;
use Bio::EnsEMBL::RawContig;


my($CHR, $START, $END) =  ('20', 30_363_615, 30_475_000);
my $CTG_BOUNDARY       =  62877;

#
# 1 Test DnaDnaAlignFeature compiles
#
ok(1);

my $multi_db = MultiTestDB->new;
my $db = $multi_db->get_DBAdaptor('core');



my $slice = $db->get_SliceAdaptor->fetch_by_chr_start_end($CHR,$START,$END);

my $contig = new Bio::EnsEMBL::RawContig;
$contig->seq('ACTGACTG');
$contig->name('bogus contig');

my @feats;
my $fp = new Bio::EnsEMBL::FeaturePair;
$fp->start(5);
$fp->end  (7);
$fp->strand(1);
$fp->score(10);
$fp->contig($contig);
$fp->hstart(105);
$fp->hend    (107);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');

push(@feats,$fp);


$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start(10);
$fp->end  (14);
$fp->strand(1);
$fp->score(10);
$fp->contig($contig);
$fp->seqname(1);

$fp->hstart  (108);
$fp->hend    (112);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

#
#
# 2 Test DnaDnaAlignFeature::new(-features)
#
$dnaf = Bio::EnsEMBL::DnaDnaAlignFeature->new( -features => \@feats );
ok($dnaf && $dnaf->validate);

#
# 3 Test DnaDnaAlignFeature::seqname
#
ok($dnaf->seqname eq 'bogus contig');

#
# 4 Test DnaDnaAlignFeature::hseqname
#
ok($dnaf->hseqname eq 'dummy-hid');


#
# 5 Test DnaDnaAlignFeature::cigar_string
#
ok($dnaf->cigar_string =~ '3M2I5M');

#
# 6-8 Test DnaDnaAlignFeature::reverse_complement
#
my $strand = $dnaf->strand;
my $hstrand = $dnaf->hstrand;
$dnaf->reverse_complement;
ok($dnaf->cigar_string =~ '5M2I3M');
ok(($strand*-1) == $dnaf->strand);
ok(($hstrand*-1) == $dnaf->hstrand); 



#
# 9 Test DnaDnaAlignFeature::start
#
ok($dnaf->start == 5);

#
# 10 Test DnaDnaAlignFeature::end
#
ok($dnaf->end == 14);

#
# 11 Test DnaDnaAlignFeature::ungapped_features
#
ok( scalar($dnaf->ungapped_features) == 2);


#
# 12 Test retrieval from database
#
my $features = $slice->get_all_DnaAlignFeatures;

ok(scalar @$features);

#
# 13 Test transformation to raw contig
#
my $f = $features->[0];
my @fs = $f->transform;
ok( scalar @fs );

#
# 14 Test transformation back to slice
#
($f) = @fs;
$f = $f->transform($slice); 
ok($f);

#
# 15 Test transformation onto negative strand slice
#
$f = $f->transform($slice->invert);
ok($f);


#
# 16-21 create a dnaalign feature on a slice across a contig boundary
#       and convert to raw contig coordinates
#       (+ve strand, +ve hitstrand)
#
@feats = ();
$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY - 2);
$fp->end  ($CTG_BOUNDARY);
$fp->strand(1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart(105);
$fp->hend    (107);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY + 3);
$fp->end  ($CTG_BOUNDARY + 7);
$fp->strand(1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart  (108);
$fp->hend    (112);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY + 8);
$fp->end  ($CTG_BOUNDARY + 12);
$fp->strand(1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart  (115);
$fp->hend    (119);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$dnaf = Bio::EnsEMBL::DnaDnaAlignFeature->new( -features => \@feats );
ok($dnaf);
ok($dnaf->cigar_string eq '3M2I5M2D5M');
ok($dnaf->validate || 1); #validate doesn't return true but throws on fail

@dnafs = $dnaf->transform;
ok(scalar(@dnafs) == 2);
ok($dnafs[0]->validate || 1); 
ok($dnafs[1]->validate || 1);


#
# 22-27 create a dnaalign feature on a slice across a contig boundary
#       and convert to raw contig coordinates
#       (+ve strand, -ve hitstrand)
#
@feats = ();
$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY - 2);
$fp->end  ($CTG_BOUNDARY);
$fp->strand(1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart  (108);
$fp->hend    (110);
$fp->hstrand (-1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY + 3);
$fp->end  ($CTG_BOUNDARY + 7);
$fp->strand(1);
$fp->score(10);
$fp->contig($slice);
$fp->seqname(1);
$fp->hstart(103);
$fp->hend    (107);
$fp->hstrand (-1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);


$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY + 8);
$fp->end  ($CTG_BOUNDARY + 12);
$fp->strand(1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart  (96);
$fp->hend    (100);
$fp->hstrand (-1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$dnaf = Bio::EnsEMBL::DnaDnaAlignFeature->new( -features => \@feats );
ok($dnaf);
ok($dnaf->cigar_string eq '3M2I5M2D5M');
ok($dnaf->validate || 1); #validate doesn't return true but throws on fail

my @dnafs = $dnaf->transform;
ok(scalar(@dnafs) == 2);
ok($dnafs[0]->validate || 1); 
ok($dnafs[1]->validate || 1);


#
# 28-33 create a dnaalign feature on a slice across a contig boundary
#       and convert to raw contig coordinates
#       (-ve strand, +ve hitstrand)
#
@feats = ();

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY + 8);
$fp->end  ($CTG_BOUNDARY + 10);
$fp->strand(-1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart  (100);
$fp->hend    (102);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY + 1);
$fp->end  ($CTG_BOUNDARY + 5);
$fp->strand(-1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart(103);
$fp->hend    (107);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY - 4);
$fp->end  ($CTG_BOUNDARY);
$fp->strand(-1);
$fp->score(10);
$fp->contig($slice);
$fp->seqname(1);
$fp->hstart  (110);
$fp->hend    (114);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);


$dnaf = Bio::EnsEMBL::DnaDnaAlignFeature->new( -features => \@feats );
ok($dnaf);
ok($dnaf->cigar_string eq '3M2I5M2D5M');
ok($dnaf->validate || 1); #validate doesn't return true but throws on fail

@dnafs = $dnaf->transform;
ok(scalar(@dnafs) == 2);
ok($dnafs[0]->validate || 1); 
ok($dnafs[1]->validate || 1);



#
# 34-39 create a dnaalign feature on a slice across a contig boundary
#       and convert to raw contig coordinates
#       (-ve strand, -ve hitstrand)
#
@feats = ();
$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY + 3);
$fp->end  ($CTG_BOUNDARY + 5);
$fp->strand(-1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart  (108);
$fp->hend    (110);
$fp->hstrand (-1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY - 4);
$fp->end  ($CTG_BOUNDARY);
$fp->strand(-1);
$fp->score(10);
$fp->contig($slice);
$fp->seqname(1);
$fp->hstart(103);
$fp->hend    (107);
$fp->hstrand (-1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);


$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY - 9);
$fp->end  ($CTG_BOUNDARY - 5);
$fp->strand(-1);
$fp->score(10);
$fp->contig($slice);
$fp->seqname(1);
$fp->hstart(96);
$fp->hend(100);
$fp->hstrand (-1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$dnaf = Bio::EnsEMBL::DnaDnaAlignFeature->new( -features => \@feats );
ok($dnaf);
ok($dnaf->cigar_string eq '3M2I5M2D5M');
ok($dnaf->validate || 1); #validate doesn't return true but throws on fail

@dnafs = $dnaf->transform;
ok(scalar(@dnafs) == 2);
ok($dnafs[0]->validate || 1); 
ok($dnafs[1]->validate || 1);


#
#
# Do the same tests again on the negative strand slice
#
#
$CTG_BOUNDARY = $slice->length - $CTG_BOUNDARY + 1;
$slice = $slice->invert;

#
# 40-45 create a dnaalign feature on a slice across a contig boundary
#       and convert to raw contig coordinates
#       (+ve strand, +ve hitstrand)
#
@feats = ();
$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY - 2);
$fp->end  ($CTG_BOUNDARY);
$fp->strand(1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart(105);
$fp->hend    (107);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY + 3);
$fp->end  ($CTG_BOUNDARY + 7);
$fp->strand(1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart  (108);
$fp->hend    (112);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY + 8);
$fp->end  ($CTG_BOUNDARY + 12);
$fp->strand(1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart  (115);
$fp->hend    (119);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$dnaf = Bio::EnsEMBL::DnaDnaAlignFeature->new( -features => \@feats );
ok($dnaf);
ok($dnaf->cigar_string eq '3M2I5M2D5M');
ok($dnaf->validate || 1); #validate doesn't return true but throws on fail

@dnafs = $dnaf->transform;
ok(scalar(@dnafs) == 2);
ok($dnafs[0]->validate || 1); 
ok($dnafs[1]->validate || 1);


#
# 46-51 create a dnaalign feature on a slice across a contig boundary
#       and convert to raw contig coordinates
#       (+ve strand, -ve hitstrand)
#
@feats = ();
$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY - 2);
$fp->end  ($CTG_BOUNDARY);
$fp->strand(1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart  (108);
$fp->hend    (110);
$fp->hstrand (-1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY + 3);
$fp->end  ($CTG_BOUNDARY + 7);
$fp->strand(1);
$fp->score(10);
$fp->contig($slice);
$fp->seqname(1);
$fp->hstart(103);
$fp->hend    (107);
$fp->hstrand (-1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);


$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY + 8);
$fp->end  ($CTG_BOUNDARY + 12);
$fp->strand(1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart  (96);
$fp->hend    (100);
$fp->hstrand (-1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$dnaf = Bio::EnsEMBL::DnaDnaAlignFeature->new( -features => \@feats );
ok($dnaf);
ok($dnaf->cigar_string eq '3M2I5M2D5M');
ok($dnaf->validate || 1); #validate doesn't return true but throws on fail

@dnafs = $dnaf->transform;
ok(scalar(@dnafs) == 2);
ok($dnafs[0]->validate || 1); 
ok($dnafs[1]->validate || 1);


#
# 52-57 create a dnaalign feature on a slice across a contig boundary
#       and convert to raw contig coordinates
#       (-ve strand, +ve hitstrand)
#
@feats = ();

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY + 8);
$fp->end  ($CTG_BOUNDARY + 10);
$fp->strand(-1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart  (100);
$fp->hend    (102);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY + 1);
$fp->end  ($CTG_BOUNDARY + 5);
$fp->strand(-1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart(103);
$fp->hend    (107);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY - 4);
$fp->end  ($CTG_BOUNDARY);
$fp->strand(-1);
$fp->score(10);
$fp->contig($slice);
$fp->seqname(1);
$fp->hstart  (110);
$fp->hend    (114);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);


$dnaf = Bio::EnsEMBL::DnaDnaAlignFeature->new( -features => \@feats );
ok($dnaf);
ok($dnaf->cigar_string eq '3M2I5M2D5M');
ok($dnaf->validate || 1); #validate doesn't return true but throws on fail

@dnafs = $dnaf->transform;
ok(scalar(@dnafs) == 2);
ok($dnafs[0]->validate || 1); 
ok($dnafs[1]->validate || 1);



#
# 58-63 create a dnaalign feature on a slice across a contig boundary
#       and convert to raw contig coordinates
#       (-ve strand, -ve hitstrand)
#
@feats = ();
$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY + 3);
$fp->end  ($CTG_BOUNDARY + 5);
$fp->strand(-1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart  (108);
$fp->hend    (110);
$fp->hstrand (-1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY - 4);
$fp->end  ($CTG_BOUNDARY);
$fp->strand(-1);
$fp->score(10);
$fp->contig($slice);
$fp->seqname(1);
$fp->hstart(103);
$fp->hend    (107);
$fp->hstrand (-1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);


$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY - 9);
$fp->end  ($CTG_BOUNDARY - 5);
$fp->strand(-1);
$fp->score(10);
$fp->contig($slice);
$fp->seqname(1);
$fp->hstart(96);
$fp->hend(100);
$fp->hstrand (-1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$dnaf = Bio::EnsEMBL::DnaDnaAlignFeature->new( -features => \@feats );
ok($dnaf);
ok($dnaf->cigar_string eq '3M2I5M2D5M');
ok($dnaf->validate || 1); #validate doesn't return true but throws on fail

@dnafs = $dnaf->transform;
ok(scalar(@dnafs) == 2);
ok($dnafs[0]->validate || 1); 
ok($dnafs[1]->validate || 1);

