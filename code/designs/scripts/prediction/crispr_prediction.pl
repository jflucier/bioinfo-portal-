#!/usr/bin/perl -w
#-d:ptkdb
#-w
use strict;
use warnings;

$| = 1;

use Carp;
$SIG{__DIE__} = sub {confess $_[0]};

use designs::Experiment::CRISPR::CRISPRExperimentDesign;
use Config::EZConf;



sub configure_main{
    my $ezconf = shift;
    
    my $pred_grp = $ezconf->add_group (label => 'Global prediction parameters');
    
    $ezconf->add_option(
        id          => 'design_type',
        label       => 'Type of design',
        description => 'Tells the script what type of design to perform. Possible values are: sequence, file or annotation.',
        type        => 'string',
        default     => 'sequence',
        group       => $pred_grp, 
    );
    
    $ezconf->add_option(
        id          => 'prediction_number',
        label       => 'number of predictions',
        description => 'A number of predictions that script should output if possible.',
        type        => 'integer',
        default     => '2',
        group       => $pred_grp, 
    );
    
    my $single_ev_grp = $ezconf->add_group (label => 'Sequence design type parameters');
    
    $ezconf->add_option(
        id          => 'target_sequence',
        label       => 'Target sequence',
        description => 'The gene name that will be used to filter out blast offtargets.  This option is enabled when sequence design type is activated.',
        type        => 'string',
        default     => '',
        group       => $single_ev_grp, 
    );
    
    my $grp = $ezconf->add_group (label => 'Blast Configuration');
    
    $ezconf->add_option(
        id          => 'blast_program',
        label       => 'Blast program',
        description => 'Blast program to use for offtargets search. Possible values are NCBIBlast or WuBlast.',
        type        => 'string',
        default     => 'NCBIBlast',
        group       => $grp,
    );
    
    $ezconf->add_option(
        id          => 'blast_path',
        label       => 'Blast path',
        description => 'Blast program path',
        type        => 'string',
        default     => '/usr/bin/blastall',
        group       => $grp,
    );
    
    $ezconf->add_option(
        id          => 'blast_database',
        label       => 'Blast database',
        description => 'Blast database.',
        type        => 'string',
        default     => $ENV{BSPDATADIR} . '/BlastDB/ecoli_mg1655.fa',
        group       => $grp,                
    );

    $ezconf->add_option(
        id          => 'blast_parameters',
        label       => 'Blast parameters',
        description => 'Blast parameters.',
        type        => 'string',
        default     => '',
        group       => $grp,                
    );
}

main();

sub main {
    my $ezconf = Config::EZConf->new;
    configure_main ($ezconf);
    my $conf = $ezconf->parse_config (@ARGV);
    
    if($conf->{design_type} eq 'sequence'){
        sequence_design($conf);
    }
    else{
        print STDERR "Unrecongnised design type parameter. Only sequence type is implemented for now.\n";
        exit;
    }
}

sub sequence_design {
    my($conf) = @_;
    
    if($conf->{target_sequence} eq ''){
        print STDERR "Please provide a target sequence.\n";
        exit;
    }
    
    if($conf->{blast_database} eq ''){
        print STDERR "Please provide a blast database. See database in ".$ENV{BSPDATADIR} . '/BlastDB/'."\n";
        exit;
    }
    
    my $program = $conf->{blast_program};
    eval "use designs::Tool::$program";
    if ($@) {
        my $msg = "unable to find blaster package : use designs::Tool::$program.pm. Exception: $@\n";
        die($msg);
    }
    
    my $blaster = eval "designs::Tool::$program->new();";
    
    $blaster->location($conf->{blast_path});
    $blaster->database($conf->{blast_database});
    
    if(defined($conf->{blast_parameters}) and $conf->{blast_parameters} ne ""){
        $blaster->parameters($conf->{blast_parameters});
    }
    
    my $crispr_exp_obj = designs::Experiment::CRISPR::CRISPRExperimentDesign->new(
         'blaster'  => $blaster,
         'sequence'     => uc($conf->{target_sequence})
    );
    
    my $predictions = $crispr_exp_obj->get_CRISPR_predictions();
    print STDERR "outputting predictions\n";
    print_prediction($predictions,$conf->{prediction_number});
}

sub print_prediction {
    my($predictions) = @_;
    my $c = 1;
    print 
            "Nbr\t"
            . "spacer\t"
            . "protospacer\t"
            . "full sequence\t"
            . "localisation_bin\t"
            . "localisation_pos\t"
            . "internal dG\t"
            . "hybrydisation dG\t"
            . "offtargets\n";
    foreach my $p (@$predictions){
        print 
            $c . "\t"
            . $p->{spacer_sequence} . "\t"
            . $p->{target_sequence} . "\t"
            . $p->{full_sequence} . "\t"
            . $p->{localisation_bin} . "\t"
            . $p->{localisation_pos} . "\t"
            . $p->{min_energy} . "\t"
            . $p->{filters}->{hybrid_dg} . "\t"
            . join(",",@{$p->{filters}->{OffTargets}}) . "\n";
        $c++;
    }
}

