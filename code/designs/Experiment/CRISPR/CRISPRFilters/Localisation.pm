package designs::Experiment::CRISPR::CRISPRFilters::Localisation;
use strict;


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
    return 'Localisation';
}

sub executeFilter{
    my($self,$crispr_list,$template_seq) = @_;
    foreach my $crispr (@$crispr_list){
        
        my @template_tok = split($crispr->{spacer_sequence},$template_seq);
        
        my $pos;
        if(scalar(@template_tok) > 1){
            # found sequence on template sequence
            $pos = length($template_tok[0]);
        }
        else{
            my $template_rc_seq = $self->rc($template_seq);
            @template_tok = split($crispr->{spacer_sequence},$template_rc_seq);
            if(scalar(@template_tok) > 1){
                $pos = length($template_tok[1]);
            }
        }
        
        if(!defined($pos)){
            die("Unable to find the crispr sequence in template seq or rc template. Sequence is " . $crispr->{spacer_sequence} . "\n");
        }
        
        my $bin_index = $self->find_bin_index($template_seq,$pos);
        
        $crispr->{localisation_bin} = $bin_index;
        $crispr->{localisation_pos} = $pos;
    }
}

sub find_bin_index {
    my ($self,$template_seq,$pos) = @_;
    
    # generate bin index
    my $bin_size = int(length($template_seq)/4);
    
    if($pos < $bin_size){
        return 1;
    }
    elsif($pos >= $bin_size and $pos < (2*$bin_size)){
        return 2;
    }
    elsif($pos >= (2*$bin_size) and $pos < (3*$bin_size)){
        return 3;
    }
    elsif($pos >= (3*$bin_size)){
        return 4;
    }
    else{
        die("Unable to determine bin size. crispr pos = $pos\n");
    }
}

sub rc {
    my ($self,$seq) = @_;
    $seq = reverse($seq);
    $seq =~ tr/ACGTUacgtu/TGCAAtgcaa/;
    return $seq;
}


1; 
