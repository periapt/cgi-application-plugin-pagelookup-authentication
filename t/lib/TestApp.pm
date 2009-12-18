package TestApp;

use strict;
use warnings;

use base qw(CGI::Application);
use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use CGI::Application::Plugin::PageLookup (qw/:all/);
use CGI::Application::Plugin::Forward;
use CGI::Application::Plugin::Authentication;
use HTML::Template::Pluggable;
use HTML::Template::Plugin::Dot;

sub setup {
        my $self = shift;

        $self->start_mode('basic_test');
        $self->run_modes(
		basic_test  => 'basic_test',
		pagelookup_rm=> 'pagelookup_rm',
		admin_lookup_rm => 'pagelookup_rm'

		);
	$self->authen->protected_runmodes(qr/^admin/);
	$self->authen->config(
        	DRIVER => [ 'Generic', { user1 => '123' } ],
		STORE => ['Cookie',
        		NAME   => 'MYAuthCookie',
        		SECRET => 'FortyTwo']
    	);


}

sub basic_test {
        my $self = shift;
        return "Hello World: basic_test";
}

sub cgiapp_init {
        my $self = shift;
	# use the same args as DBI->connect();
	#$self->dbh_config("dbi:SQLite:t/dbfile","","");

	my %params = (remove=>['lang', 'template', 'pageId', 'internalId', 'changefreq']);
	$params{prefix} = $self->param('prefix') if $self->param('prefix');
	$params{remove} = $self->param('remove') if $self->param('remove');
	$params{msg_param} = $self->param('msg_param') if $self->param('msg_param');
	if ($self->param('notfound_stuff')) {
		$params{status_404}=4000 ;
		$params{msg_param}='error_param';
	}
	$params{xml_sitemap_base_url} = $self->param('xml_sitemap_base_url') if $self->param('xml_sitemap_base_url');
	$params{template_params} = $self->param('template_params') if $self->param('template_params');
	$self->html_tmpl_class('HTML::Template::Pluggable');
	$params{objects} = {guard=>'CGI::Application::Plugin::PageLookup::Authentication'};

	$self->pagelookup_config(%params);
}


1
