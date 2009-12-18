#!perl  

use strict;
use warnings;
use Test::More;
use Test::Database;
use Test::Differences;
use Test::Exception;
use lib qw(t/lib);

# get all available handles
my @handles;

BEGIN {
	@handles  = Test::Database->handles({dbd=>'SQLite'},{dbd=>'mysql'});

	# plan the tests
	plan tests => 1 + 14 * @handles;
	
	use_ok( 'CGI::Application::Plugin::PageLookup' );
}

use DBI;
use CGI;
use TestApp;

$ENV{CGI_APP_RETURN_ONLY} = 1;
my $params = {};

sub response_like {
        my ($app, $header_re, $body_re, $comment) = @_;

        local $ENV{CGI_APP_RETURN_ONLY} = 1;
        my $output = $app->run;
        my ($header, $body) = split /\r\n\r\n/m, $output;
        $header =~ s/\r\n/|/g;
        like($header, $header_re, "$comment (header match)");
        eq_or_diff($body,      $body_re,       "$comment (body match)");
}

# run the tests
for my $handle (@handles) {
       diag "Testing with " . $handle->dbd();    # mysql, SQLite, etc.

       # let $handle do the connect()
       my $dbh = $handle->dbh();
       drop_tables($dbh) if $ENV{DROP_TABLES};
       $params->{'::Plugin::DBH::dbh_config'}=[$dbh];

       $dbh->do("create table cgiapp_pages (pageId varchar(255), lang varchar(2), internalId int, home TEXT, path TEXT)");
       $dbh->do("create table cgiapp_structure (internalId int, template varchar(20), changefreq varchar(20))");
       $dbh->do("create table cgiapp_lang (lang varchar(2))");
       $dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('test1', 'en', 0, 'HOME', 'PATH')");
       $dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('test2', 'en', 1, 'HOME1', 'PATH1')");
       $dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('test3', 'en', 2, 'HOME1', 'PATH1')");
       $dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('en/404', 'en', 404, 'HOME1', 'PATH1')");
       $dbh->do("insert into  cgiapp_lang (lang) values('en')");
       $dbh->do("insert into  cgiapp_structure(internalId, template, changefreq) values(0,'t/templ/test.tmpl', NULL)");
       $dbh->do("insert into  cgiapp_structure(internalId, template, changefreq) values(1,'t/templ/test.tmpl', NULL)");
       $dbh->do("insert into  cgiapp_structure(internalId, template, changefreq) values(2,'t/templ/testG.tmpl', NULL)");
       $dbh->do("insert into  cgiapp_structure(internalId, template, changefreq) values(404,'t/templ/testN.tmpl', NULL)");

       {
                my $app = TestApp->new(QUERY => CGI->new(""));
               isa_ok($app, 'CGI::Application');

                response_like(
                        $app,
                        qr{^Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                        "Hello World: basic_test",
                        'TestApp, blank query',
                );
       }


{
my $html=<<EOS
<html>
  <head><title>Test Template</title>
  <body>
  My Home Directory is HOME
  <p>
  My Path is set to PATH
  </body>
  </html>
EOS
;

	local $params->{pageid} = 'test1';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query( CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, test1'
        );
}

{
my $html=<<EOS
<html>
  <head><title>Test Template</title>
  <body>
  My Home Directory is HOME1
  <p>
  My Path is set to PATH1
  </body>
  </html>
EOS
;

	local $params->{pageid} = 'test2';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query(CGI->new({'rm' => 'pagelookup_rm', pageid=>'test2'}));
        response_like(
                $app,
                qr{^Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, test2'
        );
}

{
my $html=<<EOS
<html>
  <head><title>Test Template</title>
  <body>
  My Home Directory is HOME1
  <p>
  My Path is set to PATH1

  Did not find the page: testN
  </body>
  </html>
EOS
;

	local $params->{pageid} = 'testN';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query(CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Status: 404\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, notfound'
        );
}

{
	my $html=<<EOS
<!DOCTYPE html
\tPUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
\t "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
<head>
<title>Sign In</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
</head>
<body>

<style type="text/css">
<!--/* <![CDATA[ */
div.login {
  width: 25em;
  margin: auto;
  padding: 3px;
  font-weight: bold;
  border: 2px solid #445588;
  color: #303c5f;
  font-family: sans-serif;
}
div.login div {
  margin: 0;
  padding: 0;
  border: none;
}
div.login .login_header {
  background: #445588;
  border-bottom: 1px solid #1b2236;
  height: 1.5em;
  padding: 0.45em;
  text-align: left;
  color: #fff;
  font-size: 100%;
  font-weight: bold;
}
div.login .login_content {
  background: #d0d5e1;
  padding: 0.8em;
  border-top: 1px solid white;
  border-bottom: 1px solid #565656;
  font-size: 80%;
}
div.login .login_footer {
  background: #a2aac4;
  border-top: 1px solid white;
  border-bottom: 1px solid white;
  text-align: left;
  padding: 0;
  margin: 0;
  min-height: 2.8em;
}
div.login fieldset {
  margin: 0;
  padding: 0;
  border: none;
  width: 100%;
}
div.login label {
  clear: left;
  float: left;
  padding: 0.6em 1em 0.6em 0;
  width: 8em;
  text-align: right;
}
/* image courtesy of http://www.famfamfam.com/lab/icons/silk/  */
#authen_loginfield {
  background: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAG5SURBVHjaYvz//z8DJQAggFiIVfh0twHn9w8KD9+/ZBT+9/cfExfvwwc87GxWAAFEtAFf3yl++/9XikHXL56BkYmJ4dKmcoUPT99PBQggRmK8ALT9v4BUBQMLrxxQMztY7N+PjwyXtk76BxBATMRoFjGewsDCx8jw9Oxyht9vboIxCDAxs/wCCCC8LoBrZv/A8PPpVoZ/39gZ7p57xcDLJ8Xw5tkdBrO8DYwAAcRElOYXaxn+/73DwC4vzyAmzsLw58kJsGaQOoAAYiJK868nDGwSXgxvjp1n+Hz7HoNawRFGmFqAAMIw4MBEDaI1gwBAAKEYsKtL/b9x2HSiNYMAQACBA3FmiqKCohrbfQ2nLobn97Yz6Br/JEozCAAEEDgh/eb6d98yYhEDBxsnw5VNZxnOffjLIKltw/D52B6GH89fMVjUnGbEFdgAAQRPiexMzAyfDk9gMJbmYbh17irDueMrGbjExBi8Oy8z4ksnAAEENuDY1S8MjjsnMSgaezJ8Z2Bm+P95PgPX6ycENYMAQACBwyDSUeQ/GzB926kLMEjwsjOwifKvcy05EkxMHgEIIEZKszNAgAEA+j3MEVmacXUAAAAASUVORK5CYII=') no-repeat 0 1px;
  background-color: #fff;
  border-top: solid 1px #565656;
  border-left: solid 1px #565656;
  border-bottom: solid 1px #a2aac4;
  border-right: solid 1px #a2aac4;
  padding: 2px 0 2px 18px;
  margin: 0.3em 0;
  width: 12em;
}
/* image courtesy of http://www.famfamfam.com/lab/icons/silk/  */
#authen_passwordfield {
  background: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAKbSURBVHjaYvz//z8DPvBko+s0IJUJ5U6X8d+dhSwPEEAMIANw4ccbXKYB8f8/P+6BMYgNEkNWAxBAhDV/Pff/5+t5/39/2gcU/gc25P5qpzkwdQABxIjNCzBnS7p2Mfz5tJ+BkVWE4dWRxWA5oBcYHiyyYnj5heGAedYxR4AAwmXAf0mPWQx/3q9n+P/3I9AAMaCoBsPr4x0MDH/+MUgHrGG4P8eF4fVf9gMAAcSEK/D+/3oA1gxm/3kLJG8wSDhWMAjoeTJ8fxjNoJDQzyD0+7sDQACx4DKAkVWcgZGZG2jIV6AJfxn+/37F8OfPO6BhRxl+f/nIwC7xluHPm58MAAHEhMX5ILHp787OYvj/7zvDr7f7Gf59vw804DUwPM4x/P3+loFb0ZfhVlc1wxMu7psAAcSCEd9MjAzswoYMAppmDD9e9DKwcIkwMHFyMPx+dZnh7+9vDDxqwQx3Ji1jeMrJc9W1/JQOQAAheyFT2mctw9+vpxh+fz7A8O1JDQMrEz/QK2YMb47uZpD0SmEAmsRwu7eJ4QUX1wWXklOGIE0AAcQIim9YShOzSmf49W4xw5+PdxlYeIUYWLh9GS6vXPH+3U/Gd3K/vikzcTAzvOTkOmNXeNIUZitAALFAbF4D9N8Bhl+vJjP8/vCUgY1fkoGZ24PhysoV7178Y9vmW3M8FqZBHS3MAAIIZMDnP59P835/3Mnw98t7Bg5xNQZGNnOgzSvfv2ZgX+dbfiwVX14BCCCQAbyMrNwMDKxcDOxi/Az/WU0YLi1b8/E9K8cqr6JjGQwEAEAAMf378+/cn+//GFi5bRiYuMOBzt7w4RMH50IPIjSDAEAAsbz8+Gfdh9VFEr9//WX7//s/009uzlmuWUcqGYgEAAEGAIZWUhP4bjW1AAAAAElFTkSuQmCC') no-repeat 0 1px;
  background-color: #fff;
  border-top: solid 1px #565656;
  border-left: solid 1px #565656;
  border-bottom: solid 1px #a2aac4;
  border-right: solid 1px #a2aac4;
  padding: 2px 0 2px 18px;
  margin: 0.3em 0;
  width: 12em;
}
#authen_rememberuserfield {
  clear: left;
  margin-left: 8em;
}
#authen_loginfield:focus {
  background-color: #ffc;
  color: #000;
}
#authen_passwordfield:focus {
  background-color: #ffc;
  color: #000;
}
div.login a {
  font-size: 80%;
  color: #303c5f;
}
div.login div.buttons input {
  border-top: solid 2px #a2aac4;
  border-left: solid 2px #a2aac4;
  border-bottom: solid 2px #565656;
  border-right: solid 2px #565656;
  background-color: #d0d5e1;
  padding: .2em 1em ;
  font-size: 80%;
  font-weight: bold;
  color: #303c5f;
}
div.login div.buttons {
  display: block;
  margin: 8px 4px;
  width: 100%;
}
#authen_loginbutton {
  float: right;
  margin-right: 1em;
}
#authen_registerlink {
  display: block;
}
#authen_forgotpasswordlink {
  display: block;
}
ul.message {
  margin-top: 0;
  margin-bottom: 0;
  list-style: none;
}
ul.message li {
  text-indent: -2em;
  padding: 0px;
  margin: 0px;
  font-style: italic;
}
ul.message li.warning {
  color: red;
}

/* ]]> */-->
</style>

<form name="loginform" method="post" action="">
  <div class="login">
    <div class="login_header">
      Sign In
    </div>
    <div class="login_content">
      <ul class="message">
<li class="warning">Invalid username or password<br />(login attempt 1)</li>
      </ul>
      <fieldset>
        <label for="authen_username">User Name</label>
        <input id="authen_loginfield" tabindex="1" type="text" name="authen_username" size="20" value="user1" /><br />
        <label for="authen_password">Password</label>
        <input id="authen_passwordfield" tabindex="2" type="password" name="authen_password" size="20" /><br />
        <input id="authen_rememberuserfield" tabindex="3" type="checkbox" name="authen_rememberuser" value="1" />Remember User Name<br />
      </fieldset>
    </div>
    <div class="login_footer">
      <div class="buttons">
        <input id="authen_loginbutton" tabindex="4" type="submit" name="authen_loginbutton" value="Sign In" class="button" />
        
        
      </div>
    </div>
  </div>
  <input type="hidden" name="destination" value="http://localhost?rm=admin_lookup_rm;authen_username=user1" />
  <input type="hidden" name="rm" value="authen_login" />
</form>
<script type="text/javascript" language="JavaScript">document.loginform.authen_username.select();
</script>


</body>
</html>
EOS
;
	chop $html;
        local $params->{pageid} = 'test3';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query(CGI->new({authen_username => 'user1', 'rm' => 'admin_lookup_rm'}));
        response_like(
                $app,
                qr{^Set-Cookie: MYAuthCookie=\w{1,2000}%3D%3D; path=/\|Date: \w{3}, \d{2} \w{3} \d{4} \d{1,2}:\d{2}:\d{2} GMT\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, no password'
        );

}

{
        local $params->{pageid} = 'test3';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query(CGI->new({authen_username => 'user1', authen_password => '123', 'rm' => 'pagelookup_rm'}));
        Test::Exception::throws_ok( sub {$app->run}, qr/Attempt to bypass authentication on protected template/, 'bypassing authentication');
}

{
my $html=<<EOS
<html>
  <head>
	<title>Test Template</title>
	<!-- AUTHENTICATED -->

  </head>
  <body>
  My Home Directory is HOME1
  <p>
  My Path is set to PATH1
  </body>
  </html>
EOS
;

        local $params->{pageid} = 'test3';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query(CGI->new({authen_username => 'user1', authen_password => '123', 'rm' => 'admin_lookup_rm'}));
        response_like(
                $app,
                qr{^Set-Cookie: MYAuthCookie=\w{1,2000}%3D%3D; path=/\|Date: \w{3}, \d{2} \w{3} \d{4} \d{1,2}:\d{2}:\d{2} GMT\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, authentication success'
        );
}
        drop_tables($dbh);

}


sub drop_tables {
	my $dbh = shift;
       $dbh->do("drop table cgiapp_pages");
       $dbh->do("drop table cgiapp_structure");
       $dbh->do("drop table cgiapp_lang");
}
