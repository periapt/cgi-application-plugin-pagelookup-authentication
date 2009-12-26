package CGI::Application::Plugin::PageLookup::Authentication;

use warnings;
use strict;
use Carp;

=head1 NAME

CGI::Application::Plugin::PageLookup::Authentication - Allow a template to check that it is only used by authenticated run modes

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

If using L<HTML::Template>, then to protect a template include

    <TMPL_VAR NAME="guard.enforce_protection">

Then, if using L<CGI::Application::Plugin::PageLookup>, the following would have to be added to the list 
of smart objects

    guard => 'CGI::Application::Plugin::PageLookup::Authentication',

Otherwise the code would be something like:

    use CGI::Application;
    use CGI::Application::Plugin::Authentication;
    use CGI::Application::Plugin::PageLookup::Authentication;

    my auth_runmode {
	my $self = shift;
	my $guard = CGI::Application::Plugin::PageLookup::Authentication->new($self);
	my $template = $self->load_tmpl('auth_runmode.tmpl');
	$template->param(guard=>$guard);
	return $template->output;
    }

=head1 DESCRIPTION

    An L<HTML::Template> helper class that assumes the presence of L<CGI::Application::Plugin::Authentication>
    and is intended to mark a given template as requiring authentication. If the current user is authenticated,
    a simple HTML comment will be returned; otherwise the function croaks. This ensures that the template can only
    be used after successful authentication. This makes perfect sense in, and is 
    motivated by, L<CGI::Application::Plugin::PageLookup> where a run mode is not that granular and the object 
    will be created automatically if it is used by the template.

=head1 INTERFACE 

=head2 new

A constructor following the requirements set out in L<CGI::Application::Plugin::PageLookup>.

=cut

sub new {
    my $class = shift;
    my $self = {};
    $self->{cgiapp} = shift;
    bless $self, $class;
    return $self;
}

=head2 enforce_protection

This will return a benign comment if the user is authenticated but will croak otherwise.

=cut

sub enforce_protection {
    my $self = shift;
    unless ($self->{cgiapp}->authen->is_authenticated) {
	croak "Attempt to bypass authentication on protected template";
    }
    return "<!-- AUTHENTICATED -->\n";
}

=head1 DIAGNOSTICS

=over

=item C<< Attempt to bypass authentication on protected template >>

This implies that a protected template was used by an unprotected run mode.

=back


=head1 CONFIGURATION AND ENVIRONMENT

CGI::Application::Plugin::PageLookup::Authentication requires no configuration files or environment variables.

=head1 DEPENDENCIES

There is a fundamental dependency on L<CGI::Application::Plugin::Authentication> and ultimately L<CGI::Application>.
Realistically I can see no reason not to assume the presence of L<CGI::Application::Plugin::PageLookup> from a documentation
and testing point of view, but as far as I can see it could be useful in some variant cases.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-pagelookup-authentication@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Nicholas Bamber  C<< <nicholas@periapt.co.uk> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Nicholas Bamber C<< <nicholas@periapt.co.uk> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1; # End of CGI::Application::Plugin::PageLookup::Authentication
