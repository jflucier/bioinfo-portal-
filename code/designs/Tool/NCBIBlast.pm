package designs::Tool::NCBIBlast;
use strict;

use File::Temp qw/tempfile tempdir/;

use Util::Class::Constr qw/pre_process/;
use Util::Class::Props
    (
     {  
      name    => 'location',
      default => sub { '/usr/bin/blastall'}
     },
     {  
      name    => 'database',
      default => sub {'aceview_transcripts'}
     },
     {
      name    => 'parameters',
      default => sub{'-W 6 -e 500 -g F -b 50000 -v 50000 '}
     },


     {
      name    => '_hit_fields',
      default => \&_default_hit_fields,
     },
    );

# follows position in blast output file
my @__all_hit_fields =
(
 'qid',
 'sid',
 'nident',
 'alignlen',
 'nmism',
 'ngaps',
 'qstart',
 'qend',
 'sstart',
 'send',
 'E',
 'bits',
);


sub _default_hit_fields
{
    my %h; 
    $h{$_} = 0 foreach @__all_hit_fields; 
    return \%h;
}


sub pre_process
{
    my ($self, @args) = @_;
    my %args = @args;

    if (exists $args{hit_fields})
    {
        $args{_hit_fields} = {};
        $args{_hit_fields}->{$_} = 0 foreach @{$args{hit_fields}};
        delete $args{hit_fields}
    }

    return @args = %args;
}


#returns a list of hash with the following key:values
# 0:  query name
# 1:  subject name
# 2:  percent identities
# 3:  aligned length
# 4:  number of mismatched positions
# 5:  number of gap positions
# 6:  query sequence start
# 7:  query sequence end
# 8:  subject sequence start
# 9:  subject sequence end
# 10: e-value
# 11: bit score

sub run 
{
    my ($self, $sequence) = @_;
    my $com;

    my $in_fn;
    {
        my $fh;
        ($fh, $in_fn) = tempfile ("blasti.$$.XXXXXX", UNLINK => 1);
        print $fh ">seq\n$sequence\n";
        close $fh;
    }

    my $out_fn;
    {      
        my $fh;
        ($fh, $out_fn) = tempfile ("blasto.$$.XXXXXX", UNLINK => 1);
        close $fh;
    }

    my $special_parameters = '-p blastn -m 8'; #output in tabular format
    $com = sprintf "%s -d %s -i %s %s %s -o %s",
        (
         $self->get_location,
         $self->get_database,
         $in_fn,
         $self->get_parameters,
         $special_parameters,
         $out_fn,
        );
#     print STDERR "com=$com\n";
    system $com;
    die "[$com] failed with status $?, $!" unless 0 == $?;


    # parse results

    my @results;

    $self->get__hit_fields->{$_} = 0 foreach keys %{$self->get__hit_fields};
    open BLASTOUT, "$out_fn" or die "failed to open '$out_fn': $!";

    while (my $line = <BLASTOUT>) 
    {
        chomp $line;
        my %result;
        my @values = split(m/\t/, $line);
        die("Unexpected blast output '$line'") if (@values < @__all_hit_fields);

        for (my $i = 0; $i < @__all_hit_fields; ++$i) 
        {
            if (exists $self->get__hit_fields->{$__all_hit_fields[$i]})
            {
                $result{$__all_hit_fields[$i]} = $values[$i];
                $self->get__hit_fields->{$__all_hit_fields[$i]} = 1;
            }

        }

        $result{qlen} = length($sequence);
        my $qframe = $result{qend} - $result{qstart};
        if($qframe < 0){
            $qframe = -1;
        }
        else{
            $qframe = 1;
        }
        $result{qframe} = $qframe;
        
        my $sframe = $result{send} - $result{sstart};
        if($sframe < 0){
            $sframe = -1;
        }
        else{
            $sframe = 1;
        }
        $result{sframe} = $sframe;
        
        $result{nident} = int(($result{nident} / 100) * $result{qlen});
        push(@results, \%result);
    }

    close BLASTOUT or die "failed to close '$out_fn': $!";;
#     print STDERR "$out_fn\n";
    # check for missing fields
    my @missing = grep { $self->get__hit_fields->{$_} == 0 } keys %{$self->get__hit_fields};
#     die sprintf "missing %d fields in %s: %s",
#         (
#          scalar @missing,
#          $out_fn,
#          join (', ', @missing),
#         )
#             if @missing > 0;
    
    print STDERR sprintf "missing %d fields in %s: %s",
        (
         scalar @missing,
         $out_fn,
         join (', ', @missing),
        )
            if @missing > 0;
    
    
    # destroy temp files
    unlink ($in_fn);
    unlink ($out_fn);

    File::Temp::cleanup();
    return \@results;
}

1;
