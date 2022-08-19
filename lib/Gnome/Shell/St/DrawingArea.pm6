use v6.c;

use Method::Also;
use NativeCall;

use Cairo;

use Gnome::Shell::Raw::Types;

use Gnome::Shell::St::Widget;

use GLib::Roles::Implementor;

our subset StDrawingAreaAncestry is export of Mu
  where StDrawingArea | StWidgetAncestry;

class Gnome::Shell::St::DrawingAre is Gnome::Shell::St::Widget {
  has StDrawingArea $!stda is implementor;

  submethod BUILD ( :$st-drawing-area ) {
    self.setStDrawingArea($st-drawing-area) if $st-drawing-area;
  }

  method setStDrawingArea (StDrawingAreaAncestry $_) {
    my $to-parent;

    $!stda = do {
      when StDrawingArea {
        $to-parent = cast(StWidget, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StDrawingArea, $_);
      }
    }
    self.setStWidget($to-parent);
  }

  method Mutter::Cogl::Raw::Definitions::StDrawingArea
    is also<StDrawingArea>
  { $!stda }

  multi method new (StDrawingAreaAncestry $st-drawing-area, :$ref = True) {
    return unless $st-drawing-area;

    my $o = self.bless( :$st-drawing-area );
    $o.ref if $ref;
    $o;
  }

  method repaint {
    self.connect($!stda, 'repaint');
  }

  method get_context ( :$raw = False ) is also<get-context> {
    propReturnObject(
      st_drawing_area_get_context($!stda),
      $raw,
      cairo_t,
      Cairo::Context
    )
  }

  proto method get_surface_size (|)
    is also<get-surface-size>
  { * }

  multi method get_surface_size {
    samewith($, $);
  }
  multi method get_surface_size ($width is rw, $height is rw) {
    my guint ($w, $h) = 0 xx 2;

    st_drawing_area_get_surface_size($!stda, $w, $h);
    ($width, $height) = ($w, $h);
  }

  method queue_repaint is also<queue-repaint> {
    st_drawing_area_queue_repaint($!stda);
  }

}


### /home/cbwood/Projects/gnome-shell/src/st/st-drawing-area.h

sub st_drawing_area_get_context (StDrawingArea $area)
  returns cairo_t
  is native(gnome-shell-st)
  is export
{ * }

sub st_drawing_area_get_surface_size (
  StDrawingArea $area,
  guint         $width  is rw,
  guint         $height is rw
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_drawing_area_queue_repaint (StDrawingArea $area)
  is native(gnome-shell-st)
  is export
{ * }
