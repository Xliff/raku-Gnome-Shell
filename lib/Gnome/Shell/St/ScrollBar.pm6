use v6.c;

use Method::Also;
use NativeCall;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;

use Gnome::Shell::St::Widget;

use GLib::Roles::Implementor;

our subset StScrollBarAncestry is export of Mu
  where StScrollBar | StWidgetAncestry;

class Gnome::Shell::St::ScrollBar is Gnome::Shell::St::Widget {
  has StScrollBar $!stsb is implementor;

  submethod BUILD ( :$st-scroll-bar ) {
    self.setStScrollBar($st-scroll-bar) if $st-scroll-bar
  }

  method setStScrollBar (StScrollBarAncestry $_) {
    my $to-parent;

    $!stsb = do {
      when StScrollBar {
        $to-parent = cast(StWidget, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StScrollBar, $_);
      }
    }
    self.setStWidget($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::StScrollBar
    is also<StScrollBar>
  { $!stsb }

  multi method new (StScrollBarAncestry $st-scroll-bar, :$ref = True) {
    return unless $st-scroll-bar;

    my $o = self.bless( :$st-scroll-bar );
    $o.ref if $ref;
    $o;
  }
  multi method new (StAdjustment() $adjustment) {
    my $st-scroll-bar = st_scroll_bar_new($adjustment);

    $st-scroll-bar ?? self.bless( :$st-scroll-bar ) !! Nil;
  }

  # Type: StAdjustment
  method adjustment ( :$raw = False ) is rw  is g-property {
    my $gv = GLib::Value.new( Gnome::Shell::St::Adjustment.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('adjustment', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Gnome::Shell::St::Adjustment.getTypePair
        );
      },
      STORE => -> $, StAdjustment() $val is copy {
        $gv.object = $val;
        self.prop_set('adjustment', $gv);
      }
    );
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

  method scroll-start is also<scroll_start> {
    self.connect($!stsb, 'scroll-start');
  }

  method scroll-stop is also<scroll_stop> {
    self.connect($!stsb, 'scroll-stop');
  }

  method get_adjustment ( :$raw = False ) is also<get-adjustment> {
    propReturnObject(
      st_scroll_bar_get_adjustment($!stsb),
      $raw,
      |Gnome::Shell::St::Adjustment.getTypePair
    );
  }

  method set_adjustment (StAdjustment() $adjustment) is also<set-adjustment> {
    st_scroll_bar_set_adjustment($!stsb, $adjustment);
  }

}

### /home/cbwood/Projects/gnome-shell/src/st/st-scroll-bar.h

sub st_scroll_bar_get_adjustment (StScrollBar $bar)
  returns StAdjustment
  is native(gnome-shell-st)
  is export
{ * }

sub st_scroll_bar_new (StAdjustment $adjustment)
  returns StWidget
  is native(gnome-shell-st)
  is export
{ * }

sub st_scroll_bar_set_adjustment (StScrollBar $bar, StAdjustment $adjustment)
  is native(gnome-shell-st)
  is export
{ * }
