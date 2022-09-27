use v6.c;

use NativeCall;

use Gnome::Shell::Raw::Compat;
use Gnome::Shell::Raw::Types;

use Polkit::Listener;

use GLib::Roles::Implementor;
use GLib::Roles::Object;
use Gnome::Shell::Roles::Signals::Polkit::AuthenticationAgent;

our subset ShellPolkitAuthenticationAgentAncestry is export of Mu
  where ShellPolkitAuthenticationAgent | PolkitListenerAncestry;

class Gnome::Shell::Polkit::AuthenticationAgent is Polkit::Listener {
  also does Gnome::Shell::Roles::Signals::Polkit::AuthenticationAgent;

  has ShellPolkitAuthenticationAgent $!spaa is implementor;

  submethod BUILD ( :$shell-auth-agent ) {
    self.setShellPolkitAuthenticationAgent($shell-auth-agent)
      if $shell-auth-agent
  }

  method setShellPolkitAuthenticationAgent (ShellPolkitAuthenticationAgentAncestry $_) {
    my $to-parent;

    $!spaa = do {
      when ShellPolkitAuthenticationAgent {
        $to-parent = cast(PolkitListener, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellPolkitAuthenticationAgent, $_);
      }
    }
    self.setPolkitListener($to-parent);
  }

  method Mutter::Cogl::Raw::Definitions::ShellPolkitAuthenticationAgent
  { $!spaa }

  multi method new (ShellPolkitAuthenticationAgentAncestry $shell-auth-agent, :$ref = True) {
    return unless $shell-auth-agent;

    my $o = self.bless( :$shell-auth-agent );
    $o.ref if $ref;
    $o;
  }

  multi method new {
    my $shell-auth-agent = shell_polkit_authentication_agent_new();

    $shell-auth-agent ?? self.bless( :$shell-auth-agent ) !! Nil;
  }

  method initiate {
    self.connect-initiate($!spaa);
  }

  method cancel {
    self.connect($!spaa, 'cancel');
  }

  method complete (Int() $dismissed) {
    my gboolean $d = $dismissed.so.Int;

    shell_polkit_authentication_agent_complete($!spaa, $d);
  }

  method get_type {
    state ($n, $t);

    unstable_get_type (
      self.^name,
      &shell_polkit_authentication_agent_get_type,
      $n,
      $t
    );
  }

  method register (CArray[Pointer[GError]] $error = gerror) {
    clear_error;
    shell_polkit_authentication_agent_register($!spaa, $error);
    set_error($error);
  }

  method unregister {
    shell_polkit_authentication_agent_unregister($!spaa);
  }

}

### /home/cbwood/Projects/gnome-shell/src/shell-polkit-authentication-agent.h

sub shell_polkit_authentication_agent_complete (
  ShellPolkitAuthenticationAgent $agent,
  gboolean                       $dismissed
)
  is native(gnome-shell)
  is export
{ * }

sub shell_polkit_authentication_agent_new ()
  returns ShellPolkitAuthenticationAgent
  is      native(gnome-shell)
  is      export
{ * }

sub shell_polkit_authentication_agent_register (
  ShellPolkitAuthenticationAgent $agent,
  CArray[Pointer[GError]]        $error
)
  is native(gnome-shell)
  is export
{ * }

sub shell_polkit_authentication_agent_unregister (
  ShellPolkitAuthenticationAgent $agent
)
  is native(gnome-shell)
  is export
{ * }

sub shell_polkit_authentication_agent_get_type
  returns GType
  is      native(gnome-shell)
  is      export
{ * }
