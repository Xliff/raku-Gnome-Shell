use v6.c;

use Method::Also;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;

use Gnome::Shell::St::Widget;

use GLib::Roles::Implementor;
use Gnome::Shell::Roles::St::Scrollable;

our subset StViewportAncestry is export of Mu
  where StViewport | StScrollable | StWidgetAncestry;

class Gnome::Shell::St::Viewport is Gnome::Shell::St::Widget {
  also does Gnome::Shell::Roles::St::Scrollable;

  has StViewport $!stv is implementor;

  submethod BUILD ( :$st-viewport ) {
    self.setStViewport($st-viewport) if $st-viewport
  }

  method setStViewport (StViewportAncestry $_) {
    my $to-parent;

    $!stv = do {
      when StViewport {
        $to-parent = cast(StWidget, $_);
        $_;
      }

      when StScrollable {
        $to-parent      = cast(StWidget, $_);
        $!st-scrollable = $_;
        cast(StViewport, $_);
      }

      default {
        $to-parent = $_;
        cast(StViewport, $_);
      }
    }
    self.setStWidget($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::StViewport
    is also<StViewport>
  { $!stv }

  multi method new (StViewportAncestry $st-viewport, :$ref = True) {
    return unless $st-viewport;

    my $o = self.bless( :$st-viewport );
    $o.ref if $ref;
    $o;
  }

  # Type: boolean
  method clip-to-view is rw  is g-property is also<clip_to_view> {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('clip-to-view', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        $gv.boolean = $val;
        self.prop_set('clip-to-view', $gv);
      }
    );
  }

}

### /home/cbwood/Projects/gnome-shell/src/st/st-viewport.h
# cw: No subs
