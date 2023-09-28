use v6.c;

use Method::Also;
use NativeCall;

use Gnome::Shell::Raw::Types;

use Mutter::Clutter::Clone;

use GLib::Roles::Implementor;

our subset ShellGtkEmbedAncestry is export of Mu
  where ShellGtkEmbed | MutterClutterCloneAncestry;

class Gnome::Shell::GtkEmbed is Mutter::Clutter::Clone {
  has ShellGtkEmbed $!sge is implementor;

  submethod BUILD ( :$shell-gtk-embed ) {
    self.setShellGtkEmbed($shell-gtk-embed)
      if $shell-gtk-embed
  }

  method setShellGtkEmbed (ShellGtkEmbedAncestry $_) {
    my $to-parent;

    $!sge = do {
      when ShellGtkEmbed {
        $to-parent = cast(MutterClutterClone, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellGtkEmbed, $_);
      }
    }
    self.setMutterClutterClone($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::ShellGtkEmbed
    is also<ShellGtkEmbed>
  { $!sge }

  multi method new (ShellGtkEmbedAncestry $shell-gtk-embed, :$ref = True) {
    return unless $shell-gtk-embed;

    my $o = self.bless( :$shell-gtk-embed );
    $o.ref if $ref;
    $o;
  }

  multi method new (ShellEmbeddedWindow() $win) {
    my $shell-gtk-embed = shell_gtk_embed_new($win);

    $shell-gtk-embed ?? self.bless( :$shell-gtk-embed ) !! Nil;
  }
}

### /home/cbwood/Projects/gnome-shell/src/shell-gtk-embed.h

sub shell_gtk_embed_new (ShellEmbeddedWindow $window)
  returns MutterClutterActor
  is      native(gnome-shell)
  is      export
{ * }
