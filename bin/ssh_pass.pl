# Code:

$^W = 1;  # enable warnings

use POSIX qw(:sys_wait_h setsid);
use Symbol;
use strict;

my $progname = $0;
my @exit_hook;

END { map {&$_} @exit_hook }

sub getpass
{
  my $prompt = shift;
  $prompt = "Password: " unless (defined $prompt);

  my $tty_restore_fn;
  if (-t 0)
    {
      my $stty_settings = `stty -g`;
      chop $stty_settings;
      $tty_restore_fn = sub { system ("stty", $stty_settings) };
      push @exit_hook, $tty_restore_fn;
      system ("stty", "-echo");
    }

  print STDERR $prompt;
  my $pass = <STDIN>;
  $pass =~ s/\r?\n$//;

  if ($tty_restore_fn)
    {
      print STDERR "\n";
      &$tty_restore_fn;
      pop @exit_hook;
    }

  return $pass;
}

sub start
{
  my $pid = fork;
  die "fork: $!" unless (defined $pid);
  if ($pid == 0) # child
    {
      # dissociate from controlling tty because openssh client will insist
      # on reading password from controlling tty if it has one.
      setsid ();
      local $^W = 0; # turn off duplicate warning from die
      exec (@_) || die "exec: $_[0]: $!\n\tDied";
    }
  return $pid;
}

sub exitstat
{
  my ($pid, $nowaitp) = @_;
  my $result = waitpid ($pid, ($nowaitp? WNOHANG : 0));
  return undef if (!defined $result || $result == -1);
  return WEXITSTATUS ($?) if WIFEXITED   ($?);
  return WTERMSIG    ($?) if WIFSIGNALED ($?);
  return WSTOPSIG    ($?) if WIFSTOPPED  ($?);
  return undef;
}

# These are not meant to be cryptographically secure; they are just meant
# to obfuscate sensitive data so they are not discovered accidentally.

sub scramble
{
  local $_ = shift;
  tr/[\x00-\x7f][\x80-\xff]/[\x80-\xff][\x00-\x7f]/; # rot128
  $_ = $_ ^ ("\xff" x length ($_));                  # invert bits
  s/(.)/sprintf "%02x", ord($1)/ego;                 # base16-encode
  return $_;
}

sub unscramble
{
  local $_ = shift;
  s/(..)/chr hex $1/ego;                             # base16-decode
  $_ = $_ ^ ("\xff" x length ($_));                  # invert bits
  tr/[\x00-\x7f][\x80-\xff]/[\x80-\xff][\x00-\x7f]/; # rot128
  return $_;
}

sub handle_subcall
{
  # We might be invoked to inquire whether or not to
  # connect to a host for which we have no stored key;
  # if that happens, inquire from user.
  if ($ARGV[0] =~ m|yes/no|o)
    {
      print STDERR $ARGV[0];
      my $ans = <STDIN>;
      print $ans;
      return;
    }

  print unscramble ($ENV{_ssp_data}), "\n";
}

sub pkill
{
  my ($sig, $pid) = @_;
  # subprocess is the session leader via setsid; signal whole session
  kill ($sig, -$pid);
}

sub main
{
  unless (@ARGV)
    {
      print STDERR "Usage: $0 [command {command args...}]\n";
      exit (1);
    }

  unless ($progname =~ m|^/|)
    {
      use Cwd;
      my $pwd = getcwd ();
      $progname =~ s|^|$pwd/|;
    }

  return handle_subcall ()
    if (exists $ENV{_ssp_data}
        && exists $ENV{SSH_ASKPASS}
        && $ENV{SSH_ASKPASS} eq $progname
        && @ARGV == 1
        && ! -t 1);

  $ENV{DISPLAY} = "none." unless exists $ENV{DISPLAY};
  $ENV{SSH_ASKPASS} = $progname;
  #$ENV{_ssp_data} = scramble (getpass ("Password to use for ssh sessions: "));
  $ENV{_ssp_data} = scramble ( get_password() );

  my $pid = start (@ARGV);
  my $sighandler = sub { pkill ($_[0], $pid); };
  map { $SIG{$_} = $sighandler } qw(HUP INT QUIT TERM TSTP);
  exit (exitstat ($pid));
}

sub get_password()
{
  return "password"
}

main ();
