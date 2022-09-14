use v6.c;

use Method::Also;
use NativeCall;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;

use Mutter::Clutter::Actor;
use Mutter::Meta::Startup;
use Gnome::Shell::St::Widget;

use GLib::Roles::Implementor;

our subset ShellWindowPreviewAncestry is export of Mu
  where ShellWindowPreview | StWidgetAncestry;

class Gnome::Shell::WindowPreview is Gnome::Shell::St::Widget {
  has ShellWindowPreview $!swp is implementor;

  submethod BUILD ( :$shell-window-preview ) {
    self.setShellWindowPreview($shell-window-preview)
      if $shell-window-preview
  }

  method setShellWindowPreview (ShellWindowPreviewAncestry $_) {
    my $to-parent;

    $!swp = do {
      when ShellWindowPreview {
        $to-parent = cast(StWidget, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellWindowPreview, $_);
      }
    }
    self.setStWidget($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::ShellWindowPreview
    is also<ShellWindowPreview>
  { $!swp }

  method new (
    ShellWindowPreviewAncestry  $shell-window-preview,
                               :$ref                   = True
  ) {
    return unless $shell-window-preview;

    my $o = self.bless( :$shell-window-preview );
    $o.ref if $ref;
    $o;
  }

  # Type: MutterClutterActor
  method window-container ( :$raw = False ) is rw is g-property is also<window_container> {
    my $gv = GLib::Value.new( Mutter::Clutter::Actor.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('window-container', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Mutter::Clutter::Actor.getTypePair
        );
      },
      STORE => -> $, MutterClutterActor() $val is copy {
        $gv.object = $val;
        self.prop_set('window-container', $gv);
      }
    );
  }

  method get_type is also<get-type> {
    state ($n, $t);

    unstable_get_type( self.^name, &shell_window_preview_get_type, $n, $t );
  }
}

### /home/cbwood/Projects/gnome-shell/src/shell-window-preview.h
sub shell_window_preview_get_type
  returns GType
  is export
  is native(gnome-shell)
{ * }
