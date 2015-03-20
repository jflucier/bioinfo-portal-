#!/usr/bin/perl -w
use strict;

#print "Content-Type: text/html\n\n";
#print "$htmlWebDir"

use CrispyCrunch::DesignsUI;
use Error qw(:try);

my $blast_db_path = $ENV{'BLASTDB '};
my $webAppRoot = $ENV{'WEB_APP_DIR'};
my $htmlWebDir = $ENV{'HTML_WEB_DIR'};


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
