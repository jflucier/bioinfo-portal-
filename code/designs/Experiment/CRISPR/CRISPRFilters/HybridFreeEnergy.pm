package designs::Experiment::CRISPR::CRISPRFilters::HybridFreeEnergy;
use strict;

use designs::Experiment::CRISPR::Constants;
use File::Temp 'tempdir';

# the higher the value the binding affinity it as for its target

sub new {
  my ($class) = @_;
  my $self = ref($class) ? $class : {};
  bless($self => (ref $class || $class));
  return $self;
}

sub getFilterNbr{
    return 2;
}

sub getName{
    return 'Hybrid free energy.';
}

sub get_hybrid_path{
    my($self) = @_;
    my $cacheName = "_hybrid_path";
    if (!defined($self->{$cacheName})) {
        $self->{$cacheName} = tempdir(File::Spec->tmpdir()."/offtarget.XXXX", CLEANUP => 1);
    }
    return $self->{$cacheName};
}

sub get_file_path{
    my($self,$tag,$seq) = @_;
    
    my $full_path = $self->get_hybrid_path() . "/" . $tag;
    open(FH, '>' . $full_path);
    print FH $seq;
    close(FH);
    return $full_path;
}

sub executeFilter{
    my($self,$crispr_list) = @_;
    foreach my $crispr (@$crispr_list){
        my $seqa_path = $self->get_file_path('seqa',$crispr->{'spacer_sequence'});
        my $seqb_path = $self->get_file_path('seqb',$crispr->{'target_sequence'});
        
        my $path = $self->get_hybrid_path();
        `cd $path && hybrid-2s.pl --energyOnly -n DNA -t 30 -T 30 seqa seqb`;
        
        open(FH, '<' . $path . "/seqa-seqb.dG") or die("Unable to open file sea-seqb.dG in $path");
        my @lines = <FH>;
        chomp @lines;
        
        # #T	-RT ln Z	Z
        # 30	-6.08775	24477.4
        my($dG) = $lines[1] =~ /^30\t(.+)\t/;
        
        $crispr->{filters}->{'hybrid_dg'} = $dG;
        close(FH);
    }
    
    File::Temp::cleanup();
}

1; 
