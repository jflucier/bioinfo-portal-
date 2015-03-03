package Util::SequenceUtil;
use strict;

##DOC
=head2 isValidRNASeq

DESC This function verifies that sequence is composed of letters A,C,G,U. If UIPAC param is
     set to true then also accepts letters R,Y,M,K,S,W,B,D,H,V,N.
ARGS $seq1: String, The sequence
ARGS $useIUPAC: boolean, use IUPAC nucleotide if true
RETV boolean, true if sequence only composed of nucleotide, false otherwise

=cut
sub isValidRNASeq {
    my ($seq1,$useIUPAC) = @_;
    $seq1 = uc($seq1);
    if($seq1 =~ /[^A|G|C|U]/){
        return 0;
    }
    
    if(defined($useIUPAC) && $useIUPAC && $seq1 =~ /[^A|G|C|U|R|Y|M|K|S|W|B|D|H|V|N]/){
        return 0;
    }
    return 1;
} 

##DOC
=head2 isValidDNASeq

DESC This function verifies that sequence is composed of letters A,C,G,T. If UIPAC param is
     set to true then also accepts letters R,Y,M,K,S,W,B,D,H,V,N.
ARGS $seq1: String, The sequence
ARGS $useIUPAC: boolean, use IUPAC nucleotide if true
RETV boolean, true if sequence only composed of nucleotide, false otherwise

=cut
sub isValidDNASeq {
    my ($seq1,$useIUPAC) = @_;
    $seq1 = uc($seq1);
    if($seq1 =~ /[^A|T|G|C]/){
        return 0;
    }
    
    if(defined($useIUPAC) && $useIUPAC && $seq1 =~ /[^A|T|G|C|R|Y|M|K|S|W|B|D|H|V|N]/){
        return 0;
    }
    return 1;
} 

##DOC
=head2 isValidAASeq

DESC This function verifies that sequence is composed of letters G,P,A,V,L,I,M,C,F,Y,W,H,K,R,Q,N,E,D,S,T.
ARGS $seq1: String, The sequence
RETV boolean, true if sequence only composed of amino acid, false otherwise

=cut
sub isValidAASeq {
    my ($seq1,$useIUPAC) = @_;
    $seq1 = uc($seq1);
    if($seq1 =~ /[^G|P|A|V|L|I|M|C|F|Y|W|H|K|R|Q|N|E|D|S|T]/){
        return 0;
    }
    
    return 1;
}

sub calculateNucleotideNbr{
    my ($seqStr,$nucl) = @_;
    my @nuclArr= split(//,$seqStr);
	my $nbNucl = 0;
	for(my $i=0; $i<@nuclArr; $i++){
		if(uc($nuclArr[$i]) eq uc($nucl)){
			$nbNucl++;
		}
	}
    return $nbNucl;
}

sub reverseComplement{
    my $seq = shift;
    my @bases = split('',$seq);
    my @reverseBases = reverse(@bases);
    my @revComBases = ();
    
    for (my $i = 0 ; $i < @reverseBases; $i++){
        my $comBase;
        
        $comBase = 'A' if (uc($reverseBases[$i]) eq 'T' || uc($reverseBases[$i]) eq 'U');
        $comBase = 'C' if (uc($reverseBases[$i]) eq 'G');
        $comBase = 'G' if (uc($reverseBases[$i]) eq 'C');
        $comBase = 'T' if (uc($reverseBases[$i]) eq 'A');
        push(@revComBases,$comBase);   
    }
    
    return join('',@revComBases);
}

1;