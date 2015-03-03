package designs::Experiment::ExperimentDesign;
use strict; 

#use Bio::Annotations::Junctions::Detector;
use File::Temp 'tempdir';


use Util::Class::Constr;
use Util::Class::Props (
    {   
     name    => 'event',
    },
    {   
     name    => 'gene',
    },
    {
     name    => 'blaster',
    },
);

#### Public Methods ####

sub rc {
    my ($self,$seq) = @_;
    $seq = reverse($seq);
    $seq =~ tr/ACGTUacgtu/TGCAAtgcaa/;
    return $seq;
}


sub getTmpPath{
    my($self) = @_;
    my $cacheName = "_tmp_path";
    if (!defined($self->{$cacheName})) {
        $self->{$cacheName} = tempdir(File::Spec->tmpdir()."/bsp_tmp.XXXX");
    }
    return $self->{$cacheName};
}


sub get_transcripts{
    my($self)=@_;
    if(defined($self->get_event)){
        return $self->get_event()->transcripts();
    }
    else{
        return $self->get_gene()->transcripts();
    }
}

# sub find_global_junctions {
#     my($self,$transcripts) = @_;
#     
#     if(!defined($transcripts)){
#         $transcripts = $self->get_transcripts();
#     }
#     
#     my $global_junctions = Bio::Annotations::Junctions::Detector::detect_global($transcripts,$self->get_event());
# #     print STDERR "global junctions = ".scalar(@$global_junctions)."\n";
#     # lets filter out junctions that include junctions with AS event
#     $global_junctions = $self->filter_out_isoform_specific_junctions($global_junctions);
# #     print STDERR "global junctions event filtered = ".scalar(@$global_junctions)."\n";
#     my @global_junctions_by_freq_dist = sort _juntions_sort @$global_junctions;
#     
#     return \@global_junctions_by_freq_dist;
# }

# sub _juntions_sort {
#     return (
#         ($b->frequency <=> $a->frequency)
#         or ($a->calculate_distance_from_event() <=> $b->calculate_distance_from_event())
#     );
# }
# 
# sub find_global_exons {
#     my($self,$transcripts) = @_;
#     
#     if(!defined($transcripts)){
#         $transcripts = $self->get_transcripts();
#     }
#     
#     my %exons;
#     foreach my $transcript (@$transcripts){
#         my @exons = @{$transcript->exons};
#         for(my $exonCnt = 0; $exonCnt < scalar(@exons); $exonCnt++){
#             my $key = $exons[$exonCnt]->ezstart() . '_' . $exons[$exonCnt]->ezend();
#             if(!exists($exons{$key})){
#                 $exons{$key} = {
#                     'exon' => $exons[$exonCnt],
#                     'freq' => 1
#                 }
#             }
#             else{
#                 $exons{$key}->{'freq'}++;
#             }
#         }
#     }
#     
#     my $sorted = $self->sort_exons_by_freq(\%exons);
#     
#     return $sorted;
# }
# 
# sub sort_exons_by_freq {
#     my($self,$exons) = @_;
#     
#     my @ex_entry;
#     foreach my $k (keys%$exons){
#         push(@ex_entry, $exons->{$k});
#     }
#     
#     my @s = sort {$b->{'freq'} <=> $a->{'freq'} } @ex_entry;
#     
#     return \@s;
# }
# 
# sub filter_out_isoform_specific_junctions {
#     my($self,$junctions) = @_;
#     if(!defined($self->get_event())){
#         return $junctions;
#     }
#     
#     my($event_start,$event_end) = $self->get_event()->coordinates();
#     
#     my @valid_junctions;
#     foreach my $j (@$junctions){
#         if(!$j->is_overlapping_event()){
# #             print STDERR "valid junction = ".$j->to_string."\n";
#             push(@valid_junctions,$j);
#         }
#         else{
# #             print STDERR "remove event junction = ".$j->to_string."\n";
#         }
#     }
#     return \@valid_junctions;
# }

sub getHitRxAmplifiedExons {
    my($self)=@_;
    
    my $prior_exons = $self->get_event()->get_expanded_exon5();
    my @reverse_prior_exons = reverse(@$prior_exons);
    my $priorExon5Seq = $self->get_sequence_from_exons(\@reverse_prior_exons);
    
    my $exons5 = $self->get_event()->get_exon5();
#     print "exon 5 nbr = " . scalar(@exons5) . "\n";
    my @sorted_exons5 = sort { $a->length <=> $b->length } @$exons5;
    my $exon5 = $sorted_exons5[0]->sequence();
    
    my $exonAseSeq = $self->get_event()->get_AS_location()->sequence();
    
    my $exons3 = $self->get_event()->get_exon3();
    my @sorted_exons3 = sort { $a->length <=> $b->length } @$exons3;
    my $exon3 = $sorted_exons3[0]->sequence();
    
    my $after_exons = $self->get_event()->get_expanded_exon3();
    my $afterExon3Seq = $self->get_sequence_from_exons($after_exons);
    
    return $priorExon5Seq . $exon5,$exonAseSeq,$exon3 . $afterExon3Seq;
}

sub get_sequence_from_exons {
    my($self,$exons)=@_;
    my $seq = "";
    foreach my $e (@$exons){
        $seq .= $e->sequence();
    }
    return $seq;
}

sub print_junctions {
    my($self,$junctions) = @_;
    print "*************************** printing junctions ***************************\n";
    foreach my $j (@$junctions){
        my $globalExon5 = $j->exon5;
        my $globalExon3 = $j->exon3;
        my $counter = $j->frequency;
        my $distance = $j->calculate_distance_from_event;
        print $globalExon5->length . "-" . $globalExon3->length . ": freq=$counter && distance=$distance\n";
    }
}

1;



