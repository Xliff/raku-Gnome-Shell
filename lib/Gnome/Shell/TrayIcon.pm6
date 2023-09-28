use v6.c;

use Method::Also;

use NativeCall;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;

use Gnome::Shell::GtkEmbed;

use GLib::Roles::Implementor;

our subset ShellTrayIconAncestry is export of Mu
  where ShellTrayIcon | ShellGtkEmbedAncestry;

class Gnome::Shell::TrayIcon is Gnome::Shell::GtkEmbed {
  has ShellTrayIcon $!sti is implementor;

  submethod BUILD ( :$shell-tray-icon ) {
    self.setShellTrayIcon($shell-tray-icon) if $shell-tray-icon;
  }

  method setShellTrayIcon (ShellTrayIconAncestry $_) {
    my $to-parent;

    $!sti = do {
      when ShellTrayIcon {
        $to-parent = cast(ShellGtkEmbed, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellTrayIcon, $_);
      }
    }
    self.setShellGtkEmbed($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::ShellTrayIcon
    is also<ShellTrayIcon>
  { $!sti }

  multi method new (ShellTrayIconAncestry $shell-tray-icon, :$ref = True) {
    return unless $shell-tray-icon;

    my $o = self.bless( :$shell-tray-icon );
    $o.ref if $ref;
    $o;
  }
  multi method new (ShellEmbeddedWindow() $win) {
    my $shell-tray-icon = shell_tray_icon_new($win);

    $shell-tray-icon ?? self.bless( :$shell-tray-icon ) !! Nil;
  }

  method pid is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_UINT );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('pid', $gv);
        $gv.uint;
      },
      STORE => -> $, Int() $val is copy {
        warn 'pid does not allow writing'
      }
    );
  }

  # Type: string
  method title is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_STRING );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('title', $gv);
        $gv.string;
      },
      STORE => -> $, Str() $val is copy {
        warn 'title does not allow writing'
      }
    );
  }

  # Type: string
  method wm-class is rw  is g-property is also<wm_class> {
    my $gv = GLib::Value.new( G_TYPE_STRING );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('wm-class', $gv);
        $gv.string;
      },
      STORE => -> $, Str() $val is copy {
        warn 'wm-class does not allow writing'
      }
    );
  }

  method emit-click (MutterClutterEvent() $event) is also<emit_click> {
    shell_tray_icon_click($!sti, $event);
  }

}


### /home/cbwood/Projects/gnome-shell/src/shell-tray-icon.h

sub shell_tray_icon_click (ShellTrayIcon $icon, MutterClutterEvent $event)
  is native(gnome-shell)
  is export
{ * }

sub shell_tray_icon_new (ShellEmbeddedWindow $window)
  returns MutterClutterActor
  is      native(gnome-shell)
  is      export
{ * }
