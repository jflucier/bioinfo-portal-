#!/usr/bin/perl -w
use strict;

use FindBin;
use lib "$FindBin::Bin/../../webapps/";
use lib "$FindBin::Bin/../../code/";

use CrispyCrunch::DesignsUI;
use Error qw(:try);

my $webAppRoot = "$FindBin::Bin/../../webapps/CrispyCrunch/";
my $htmlWebDir = "$FindBin::Bin/../../htdocs/CrispyCrunch/";
my $blast_db_path = "$FindBin::Bin/../../code/Data/BlastDB/";
try{
	my $app = CrispyCrunch::DesignsUI->new(
			TMPL_PATH => $webAppRoot . 'templates/',
			PARAMS => {
					'WEBAPPROOT' => $webAppRoot,
                    'STATICWEBDIR' => $htmlWebDir,
                    'BLAST_LOCATION' => "blastall",
                    'BLAST_DB' => $blast_db_path
					}
			);
	$app->run();
}
catch Error::Simple with {
		my $E = shift;
		my $tmpl_obj = HTML::Template->new( filename => 'templates/error.tmpl', path => [$webAppRoot]);
		$tmpl_obj->param( FILE => $E->{'-file'} );
		$tmpl_obj->param( LINE => $E->{'-line'} );
		$tmpl_obj->param( TEXT => $E->{'-text'} );
		$tmpl_obj->param( VALUE => $E->{'-value'} );
		print "Content-Type: text/html\n\n", $tmpl_obj->output();
};
