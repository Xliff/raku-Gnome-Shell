use v6.c;

use Method::Also;

use NativeCall;

use Gnome::Shell::Raw::Types;

use Gnome::Shell::St::Adjustment;
use Gnome::Shell::St::Widget;

use GLib::Roles::Implementor;

role Gnome::Shell::Roles::St::Scrollable {
  has StScrollable $!st-scrollable is implementor;

  method Gnome::Shell::Raw::Definitions::StScrollable
    is also<StScrollable>
  { $!st-scrollable }

  proto method get_adjustments (|)
    is also<get-adjustments>
  { * }

  multi method get_adjustments ( :$raw = False ) {
    samewith( newCArray(StAdjustment), newCArray(StAdjustment), :$raw )
  }
  multi method get_adjustments (
    CArray[StAdjustment]  $hadjustment,
    CArray[StAdjustment]  $vadjustment,
                         :$raw          = False
  ) {
    st_scrollable_get_adjustments(
      $!st-scrollable,
      $hadjustment,
      $vadjustment
    );

    my constant GSA = Gnome::Shell::St::Adjustment;
    (
      propReturnObject($hadjustment, $raw, |GSA.getTypePair),
      propReturnObject($vadjustment, $raw, |GSA.getTypePair)
    );
  }

  method set_adjustments (
    StAdjustment() $hadjustment,
    StAdjustment() $vadjustment
  )
    is also<set-adjustments>
  {
    st_scrollable_set_adjustments($!st-scrollable, $hadjustment, $vadjustment);
  }

}

our subset StScrollableAncestry is export of Mu
  where StScrollable | StWidgetAncestry;

class Gnome::Shell::St::Scrollable is Gnome::Shell::St::Widget {
  also does Gnome::Shell::Roles::St::Scrollable;

  submethod BUILD ( :$st-scrollable ) {
    self.setStScrollable($st-scrollable) if $st-scrollable
  }

  method setStScrollable (StScrollableAncestry $_) {
    my $to-parent;

    $!st-scrollable = do {
      when StScrollable {
        $to-parent = cast(StWidget, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StScrollable, $_);
      }
    }
    self.setStWidget($to-parent);
  }

  multi method new (StScrollableAncestry $st-scrollable, :$ref = True) {
    return unless $st-scrollable;

    my $o = self.bless( :$st-scrollable );
    $o.ref if $ref;
    $o;
  }

}

### /home/cbwood/Projects/gnome-shell/src/st/st-scrollable.h

sub st_scrollable_get_adjustments (
  StScrollable         $scrollable,
  CArray[StAdjustment] $hadjustment,
  CArray[StAdjustment] $vadjustment
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_scrollable_set_adjustments (
  StScrollable $scrollable,
  StAdjustment $hadjustment,
  StAdjustment $vadjustment
)
  is native(gnome-shell-st)
  is export
{ * }
