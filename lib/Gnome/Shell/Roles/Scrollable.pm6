use v6.c;

use NativeCall;

use Gnome::Shell::Raw::Types;

use Gnome::Shell::Adjustment;

role Gnome::Shell::Roles::Scrollable {
  has StScrollable $!sts is implementor;

  method Mutter::Clutter::Raw::Definitions::StScrollable
    is also<StScrollable>
  { $!sts }

  proto method get_adjustments (|)
  { * }

  multi method get_adjustments ( $raw = False ) (
    samewith( newCArray(StAdjustment), newCArray(StAdjustment). :$raw )
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

    constant GSA = Gnome::Shell::Adjustment;
    (
      propReturnObject($hadjustment, $raw, |GSA.getTypePair),
      propReturnObject($vadjustment, $raw, |GSA.getTypePair)
    );
  }

  method set_adjustments (
    StAdjustment() $hadjustment,
    StAdjustment() $vadjustment
  ) {
    st_scrollable_set_adjustments($!st-scrollable, $hadjustment, $vadjustment);
  }

}

our subset StViewportAncestry is export of Mu
  where StScrollable | StWidgetAncestry;

class Gnome::Shell::Scrollable is Gnome::Shell::Widget {
  also does Gnome::Shell::Roles::Scrollable;

  submethod BUILD ( :$st-scrollable ) {
    self.setStScrollable($st-scrollable) if $st-scrollable
  }

  method setStScrollable (StScrollableAncestry $_) {
    my $to-parent;

    $!stv = do {
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

  multi method new (StScrollableAncestry $st-viewport, :$ref = True) {
    return unless $st-viewport;

    my $o = self.bless( :$st-viewport );
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
