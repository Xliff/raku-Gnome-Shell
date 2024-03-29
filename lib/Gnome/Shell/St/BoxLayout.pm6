use v6.c;

use Method::Also;
use NativeCall;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;

use Gnome::Shell::St::Viewport;

use GLib::Roles::Implementor;

our subset StBoxLayoutAncestry is export of Mu
  where StBoxLayout | StViewportAncestry;

class Gnome::Shell::St::BoxLayout is Gnome::Shell::St::Viewport {
  has StBoxLayout $!stbl is implementor;

  submethod BUILD ( :$st-box-layout ) {
    self.setStBoxLayout($st-box-layout) if $st-box-layout
  }

  method setStBoxLayout (StBoxLayoutAncestry $_) {
    my $to-parent;

    $!stbl = do {
      when StBoxLayout {
        $to-parent = cast(StViewport, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StBoxLayout, $_);
      }
    }
    self.setStViewport($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::StBoxLayout
    is also<StBoxLayout>
  { $!stbl }

  multi method new (StBoxLayoutAncestry $st-box-layout, :$ref = True) {
    return unless $st-box-layout;

    my $o = self.bless( :$st-box-layout );
    $o.ref if $ref;
    $o;
  }
  multi method new ( *%props ) {
    my $st-box-layout = st_box_layout_new();

    $st-box-layout ?? self.bless( :$st-box-layout, |%props ) !! Nil;
  }

  # Type: boolean
  method vertical is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('vertical', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        $gv.boolean = $val;
        self.prop_set('vertical', $gv);
      }
    );
  }

  # Type: boolean
  method pack-start is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('pack-start', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        $gv.boolean = $val;
        self.prop_set('pack-start', $gv);
      }
    );
  }

  method get_pack_start is also<get-pack-start> {
    so st_box_layout_get_pack_start($!stbl);
  }

  method get_vertical is also<get-vertical> {
    so st_box_layout_get_vertical($!stbl);
  }

  method set_pack_start (Int() $pack_start) is also<set-pack-start> {
    my gboolean $p = $pack_start.so.Int;

    st_box_layout_set_pack_start($!stbl, $pack_start);
  }

  method set_vertical (Int() $vertical) is also<set-vertical> {
    my gboolean $v = $vertical.so.Int;

    st_box_layout_set_vertical($!stbl, $v);
  }
}

### /home/cbwood/Projects/gnome-shell/src/st/st-box-layout.h

sub st_box_layout_get_pack_start (StBoxLayout $box)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_box_layout_get_vertical (StBoxLayout $box)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_box_layout_new ()
  returns StBoxLayout
  is native(gnome-shell-st)
  is export
{ * }

sub st_box_layout_set_pack_start (StBoxLayout $box, gboolean $pack_start)
  is native(gnome-shell-st)
  is export
{ * }

sub st_box_layout_set_vertical (StBoxLayout $box, gboolean $vertical)
  is native(gnome-shell-st)
  is export
{ * }
