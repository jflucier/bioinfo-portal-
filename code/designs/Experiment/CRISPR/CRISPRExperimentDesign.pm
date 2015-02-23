package designs::Experiment::CRISPR::CRISPRExperimentDesign;
use strict; 

use base 'designs::Experiment::ExperimentDesign';

#use designs::Experiment::CRISPR::CRISPRDesign;
use designs::Experiment::CRISPR::Constants;
use Util::FileSystemUtil;
use Error ':try';
use Regexp::Exhaustive qw(exhaustive);
use designs::Experiment::CRISPR::CRISPRCriteria::MinimalFreeEnergy;
use designs::Experiment::CRISPR::CRISPRFilters::OffTargets;
use designs::Experiment::CRISPR::CRISPRFilters::HybridFreeEnergy;
use designs::Experiment::CRISPR::CRISPRFilters::Localisation;

#use Util::Class::Constr;
use Util::Class::Props (
    {   
     name    => 'sequence',
    }
);

#### Public Methods ####

sub get_CRISPR_predictions {
    my($self,$seq) = @_;
    
    if(!defined($seq) and !defined($self->sequence())){
        die("Can't design CRISPR without a sequence.");
    }
    elsif(!defined($self->sequence())){
        $self->sequence(uc($seq));
    }
    
    my $predictions = $self->findCRISPR();
    
    return $predictions;
}

sub findCRISPR {
    my($self)=@_;
    
    #Generate all the putative crispr target seqs
    my $CRISPR_seqs = $self->findCRISPRTargetSeq($self->sequence());
    
    my @validCRISPR;
    my $pred_id = 1;
    foreach my $proto_spacer (@$CRISPR_seqs){
#         print STDERR "rc_spacer=$proto_spacer\n";
        my $spacer = $self->rc($proto_spacer);
        my $energy_crit = designs::Experiment::CRISPR::CRISPRCriteria::MinimalFreeEnergy->new();
        
#         if($energy_crit->is_valid($spacer)){
            
            push(
                @validCRISPR,
                {
                    id => $pred_id,
                    target_sequence => $proto_spacer,
                    spacer_sequence => $spacer,
                    full_sequence => $spacer . designs::Experiment::CRISPR::Constants::CRISPR_TAIL,
                    min_energy => $energy_crit->get_energy($spacer)
                }
            );
            $pred_id++;
#         }
    }
    
    # execute filters on valid crispr predictions
    if(scalar(@validCRISPR) > 0){
        # we have crispr prediction with valid minimal energy and other criterias
        print STDERR "analyzing offtargets\n";
        my $offtarget_filter = designs::Experiment::CRISPR::CRISPRFilters::OffTargets->new();
        $offtarget_filter->executeFilter(\@validCRISPR,$self->blaster());
        print STDERR "analyzing  hybrid energy\n";
        my $hybrid_filter = designs::Experiment::CRISPR::CRISPRFilters::HybridFreeEnergy->new();
        $hybrid_filter->executeFilter(\@validCRISPR);
        my $loc_filter = designs::Experiment::CRISPR::CRISPRFilters::Localisation->new();
        $loc_filter->executeFilter(\@validCRISPR,$self->sequence());
    }
    
    
    my @sorted = sort sort_results @validCRISPR;
#     use Data::Dump qw(dump);
#     print STDERR dump(@sorted) . "\n";
    
    return \@sorted;
}

sub findCRISPRTargetSeq {
    my($self,$template_seq) = @_;
    
    # use regex exaustive lib to retrieve overlapping sequences ending with NGG
    my @seqs = exhaustive($template_seq,qr/(\w{20})\wGG/);
    
    # reverse complement as crispr can target + and - strand
    my $rc_seq = $self->rc($template_seq);
    my @rc_seqs = exhaustive($rc_seq,qr/(\w{20})\wGG/);
    
    push(@seqs,@rc_seqs);
    return \@seqs;
}

sub sort_results{
    my $a_offtarget_major = scalar(@{$a->{filters}->{OffTargets}});
    my $b_offtarget_major = scalar(@{$b->{filters}->{OffTargets}});
    return 
        (
            ($a_offtarget_major <=> $b_offtarget_major)
            or ($a->{localisation_bin} <=> $b->{localisation_bin})
            or (int($b->{min_energy}) <=> int($a->{min_energy}))
            or ($a->{filters}->{hybrid_dg} <=> $b->{filters}->{hybrid_dg})
        );
}

sub isAllValidCRISPRCriteria {
    my($self,$criterias) = @_;
    foreach my $crit (@$criterias){
        if(!$crit->validateCriteria()){
            # criteria is not respected, so not all core criterias are ok
            return 0;
        }
    }
    
    return 1;
}

sub validateCRISPRCriteria{
    my($self,$spacer)=@_;
    my $directory = Util::FileSystemUtil::getFullExecPath('PERL5LIB','designs/Experiment/CRISPR/CRISPRCriteria');
    opendir (DIR, $directory) or die $!;
    my @criterias;
    while (my $file = readdir(DIR)) {
        if($file =~ m/^(\w|\d)+\.pm$/){
            ($file) = $file =~ /((\w|\d)+)\.\w+/;
            eval "require designs::Experiment::CRISPR::CRISPRCriteria::$1";
            if ($@) {
                my $msg = "unable to find crispr criteria package : require designs::Experiment::CRISPR::CRISPRCriteria::$file. Exception: $@\n";
                print STDERR $msg;
                throw Error::Simple($msg);
            }
            
            #Call the method with the parameters
            my $crit = eval "designs::Experiment::CRISPR::CRISPRCriteria::$file->new();";
            $crit->validateCriteria($spacer);
            push(@criterias,$crit);
        }

    }
    closedir(DIR);
    # sort by criteria nbr
    my @sorted = sort { $a->getCriteriaNbr() <=> $b->getCriteriaNbr() } @criterias;
    return \@sorted;
}

sub executeCRISPRFilters {
    my($validCRISPR) = @_;
    my $directory = Util::FileSystemUtil::getFullExecPath('PERL5LIB','designs/Experiment/CRISPR/CRISPRFilters');
    opendir (DIR, $directory) or die $!;
    while (my $file = readdir(DIR)) {
        if($file =~ m/^(\w|\d)+\.pm$/){
            ($file) = $file =~ /((\w|\d)+)\.\w+/;
            eval "require designs::Experiment::CRISPR::CRISPRFilters::$file";
            if ($@) {
                my $msg = "unable to find crispr filter package : require designs::Experiment::CRISPR::CRISPRFilters::$file. Exception: $@\n";
                print STDERR $msg;
                throw Error::Simple($msg);
            }
            
            #Call the method with the parameters
            my $filter = eval "designs::Experiment::CRISPR::CRISPRFilters::$file->new();";
            $filter->executeFilter($validCRISPR);
        }
    }
    closedir(DIR);
}

sub getAllCriterias{
    my $directory = Util::FileSystemUtil::getFullExecPath('PERL5LIB','designs/Experiment/CRISPR/CRISPRCriteria');
    opendir (DIR, $directory) or die $!;
    my @criterias;
    while (my $file = readdir(DIR)) {
        if($file =~ m/^(\w|\d)+\.pm$/){
            ($file) = $file =~ /((\w|\d)+)\.\w+/;
            eval "require designs::Experiment::CRISPR::CRISPRCriteria::$1";
            if ($@) {
                my $msg = "unable to find crispr criteria package : require designs::Experiment::CRISPR::CRISPRCriteria::$file. Exception: $@\n";
                print STDERR $msg;
                throw Error::Simple($msg);
            }
            
            #Call the method with the parameters
            my $crit = eval "designs::Experiment::CRISPR::CRISPRCriteria::$file->new();";
            push(@criterias,$crit);
        }
    }
    closedir(DIR);
    # sort by criteria nbr
    my @sorted = sort { $a->getCriteriaNbr() <=> $b->getCriteriaNbr() } @criterias;
    return \@sorted;
}

sub getAllFilters{
    my($geneName,$tossList) = @_;
    my $directory = Util::FileSystemUtil::getFullExecPath('PERL5LIB','designs/Experiment/CRISPR/CRISPRFilters');
    opendir (DIR, $directory) or die $!;
    my @filters = ();
    while (my $file = readdir(DIR)) {
        if($file =~ m/^(\w|\d)+\.pm$/){
            ($file) = $file =~ /((\w|\d)+)\.\w+/;
            eval "require designs::Experiment::CRISPR::CRISPRFilters::$file";
            if ($@) {
                my $msg = "unable to find crispr filter package : require designs::Experiment::CRISPR::CRISPRFilters::$file. Exception: $@\n";
                print STDERR $msg;
                throw Error::Simple($msg);
            }
            
            #Call the method with the parameters
            my $filter = eval "designs::Experiment::CRISPR::CRISPRFilters::$file->new();";
            push(@filters,$filter);
        }
    }
    closedir(DIR);
    my @sorted = sort {$a->getFilterNbr() <=> $b->getFilterNbr()} @filters;
    my @result = ();
    foreach my $filter (@sorted){
        my $names = $filter->getName();
        foreach my $n (@$names){
            push(@result,$n);
        }
    }
    return \@result;
}



1;



