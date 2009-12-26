use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
    NAME                => 'CGI::Application::Plugin::PageLookup::Authentication',
    AUTHOR              => 'Nicholas Bamber <nicholas@periapt.co.uk>',
    VERSION_FROM        => 'lib/CGI/Application/Plugin/PageLookup/Authentication.pm',
    ABSTRACT_FROM       => 'lib/CGI/Application/Plugin/PageLookup/Authentication.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'DBI'=>0,
	'HTML::Template::Pluggable' => 0,
	'Test::Differences' => 0,
	'CGI::Application::Plugin::PageLookup' => '1.6',
	'CGI::Application::Plugin::Authentication' => 0,
	'Test::Exception' => 0,
	'Test::Database'=>'1.07'
    },
    META_MERGE    => {
        resources => {
            repository => 'http://github.com/periapt/CGI::Application::Plugin::PageLookup::Authentication',
        },
    },
    LICENSE		=> 'perl',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Application-Plugin-PageLookup-Authentication-*' },
);

unless (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
    delete $conf{META_MERGE};
}

WriteMakefile(%conf);

