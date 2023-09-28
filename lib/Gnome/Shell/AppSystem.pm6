use v6.c;

use Method::Also;

use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::AppSystem;

use GLib::Roles::Implementor;
use GLib::Roles::Object;
use Gnome::Shell::Roles::Signals::Generic;

our subset ShellAppSystemAncestry is export of Mu
  where ShellAppSystem | GObject;

class Gnome::Shell::AppSystem {
	also does GLib::Roles::Object;
  also does Gnome::Shell::Roles::Signals::Generic;

	has ShellAppSystem $!sas is implementor;

  submethod BUILD ( :$shell-app-system ) {
    self.setShellAppSystem($shell-app-system)
      if $shell-app-system
  }

  method setShellAppSystem (ShellAppSystemAncestry $_) {
    my $to-parent;

    $!sas = do {
      when ShellAppSystem {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellAppSystem, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Mutter::Cogl::Raw::Definitions::ShellAppSystem
    is also<ShellAppSystem>
  { $!sas }

  multi method new (ShellAppSystemAncestry $shell-app-system, :$ref = True) {
    return unless $shell-app-system;

    my $o = self.bless( :$shell-app-system );
    $o.ref if $ref;
    $o;
  }

  method app-state-changed {
    self.connect-shell-app($!gsas, 'app-state-changed');
  }

  method installed-changed {
    self.connect($!gsas, 'installed-changed')
  }

  method get_default is also<get-default> {
    my $shell-app-system = shell_app_system_get_default($!gsas);

    $shell-app-system ?? self.bless( :$shell-app-system ) !! Nil
  }

  method get_installed ( :$raw = False, :$glist = False ) 
    is also<get-installed> 
  {
    returnGList(
      shell_app_system_get_installed($!gsas),
      $raw,
      $glist,
      GAppInfo
    );
  }

  method get_running ( :$raw = False, :$glist = False ) 
    is also<get-running> 
  {
    returnGSList(
      shell_app_system_get_running($!gsas),
      $raw,
      $glist,
      |Gnome::Shell::App.getTypePair
    );
  }

  method lookup_app (Str() $id, :$raw = False) is also<lookup-app> {
    propReturnObject(
      shell_app_system_lookup_app($!gsas, $id),
      $raw,
      |Gnome::Shell::App.getTypePair
    );
  }

  method lookup_desktop_wmclass (Str() $wmclass, :$raw = False) 
    is also<lookup-desktop-wmclass> 
  {
    propReturnObject(
      shell_app_system_lookup_desktop_wmclass($!gsas, $wmclass),
      $raw,
      |Gnome::Shell::App.getTypePair
    );
  }

  method lookup_heuristic_basename (Str() $id, :$raw = False) 
    is also<lookup-heuristic-basename> 
  {
    propReturnObject(
      shell_app_system_lookup_heuristic_basename($!gsas, $id),
      $raw,
      |Gnome::Shell::App.getTypePair
    );
  }

  method lookup_startup_wmclass (Str() $wmclass, :$raw = False) 
    is also<lookup-startup-wmclass> 
  {
    propReturnObject(
      shell_app_system_lookup_startup_wmclass($!gsas, $wmclass),
      $raw,
      |Gnome::Shell::App.getTypePair
    );
  }

  method search ( :$raw = False ) is also<search> {
  	# cw: Returns an array of GStrVs.

		my $agv = shell_app_system_search($!gsas);
		return $agv if $raw;
		
    my @r = CArrayToArray($agv);
    @r .= map( CArrayToArray($_) );
    @r;
  }

}
