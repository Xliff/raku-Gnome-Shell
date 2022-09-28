use v6.c;

use Method::Also;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;

use Mutter::Clutter::Color;

use GLib::Roles::Implementor;
use GLib::Roles::Object;
use Mutter::Clutter::Roles::Signals::Generic;

our subset ShellTrayManagerAncestry is export of Mu
  where ShellTrayManager | GObject;

class Gnome::Shell::TrayManager {
  also does GLib::Roles::Object;
  also does Mutter::Clutter::Roles::Signals::Generic;

  has ShellTrayManager $!stm is implementor;

  submethod BUILD ( :$shell-tray-manager ) {
    self.setShellTrayManager($shell-tray-manager)
      if $shell-tray-manager
  }

  method setShellTrayManager (ShellTrayManagerAncestry $_) {
    my $to-parent;

    $!stm = do {
      when ShellTrayManager {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellTrayManager, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::ShellTrayManager
    is also<ShellTrayManager>
  { $!stm }

  multi method new (
    ShellTrayManagerAncestry  $shell-tray-manager,
                             :$ref                 = True
  ) {
    return unless $shell-tray-manager;

    my $o = self.bless( :$shell-tray-manager );
    $o.ref if $ref;
    $o;
  }
  multi method new {
    my $shell-tray-manager = shell_tray_manager_new();

    $shell-tray-manager ?? self.bless( :$shell-tray-manager ) !! Nil;
  }

  # Type: MutterClutterColor
  method bg-color ( :$raw = False ) is rw  is g-property is also<bg_color> {
    my $gv = GLib::Value.new( Mutter::Clutter::Color.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('bg-color', $gv);
        propReturnObject(
          $gv.pointer,
          $raw,
          |Mutter::Clutter::Color.getTypePair
        )
      },
      STORE => -> $, MutterClutterColor() $val is copy {
        $gv.pointer = $val;
        self.prop_set('bg-color', $gv);
      }
    );
  }

  method tray-icon-added is also<tray_icon_added> {
    self.connect-actor($!stm, 'tray-icon-added');
  }

  method tray-icon-removed is also<tray_icon_removed> {
    self.connect-actor($!stm, 'tray-icon-removed');
  }

  method manage_screen (StWidget() $theme_widget) is also<manage-screen> {
    shell_tray_manager_manage_screen($!stm, $theme_widget);
  }

  method unmanage_screen is also<unmanage-screen> {
    shell_tray_manager_unmanage_screen($!stm);
  }

}

### /home/cbwood/Projects/gnome-shell/src/shell-tray-manager.h

sub shell_tray_manager_manage_screen (
  ShellTrayManager $manager,
  StWidget         $theme_widget
)
  is native(gnome-shell)
  is export
{ * }

sub shell_tray_manager_new ()
  returns ShellTrayManager
  is native(gnome-shell)
  is export
{ * }

sub shell_tray_manager_unmanage_screen (ShellTrayManager $manager)
  is native(gnome-shell)
  is export
{ * }
