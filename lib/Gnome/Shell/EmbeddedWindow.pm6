use v6.c;

use NativeCall;
use Method::Also;

use Gnome::Shell::Raw::Types;

use GTK::Window;

use GLib::Roles::Implementor;

our subset ShellEmbeddedWindowAncestry is export of Mu
  where ShellEmbeddedWindow | GtkWindowAncestry;

class Gnome::Shell::EmbeddedWindow is GTK::Window {
  has ShellEmbeddedWindow $!sew is implementor;

  submethod BUILD ( :$shell-embedded-window ) {
    self.setShellEmbeddedWindow($shell-embedded-window)
      if $shell-embedded-window
  }

  method setShellEmbeddedWindow (ShellEmbeddedWindowAncestry $_) {
    my $to-parent;

    $!sew = do {
      when ShellEmbeddedWindow {
        $to-parent = cast(GtkWindow, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellEmbeddedWindow, $_);
      }
    }
    self.setGtkWidget($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::ShellEmbeddedWindow
    is also<ShellEmbeddedWindow>
  { $!sew }

  multi method new (
    ShellEmbeddedWindowAncestry  $shell-embedded-window,
                                :$ref                    = True
  ) {
    return unless $shell-embedded-window;

    my $o = self.bless( :$shell-embedded-window );
    $o.ref if $ref;
    $o;
  }
  multi method new {
    my $shell-embedded-window = shell_embedded_window_new();

    $shell-embedded-window ?? self.bless( :$shell-embedded-window ) !! Nil;
  }

}


### /home/cbwood/Projects/gnome-shell/src/shell-embedded-window.h

sub shell_embedded_window_new ()
  returns ShellEmbeddedWindow
  is      native(gnome-shell)
  is      export
{ * }
