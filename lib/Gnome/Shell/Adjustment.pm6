use v6.c;

use Method::Also;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::Adjustment;

use Mutter::Clutter::Actor;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

our subset StAdjustmentAncestry is export of Mu
  where StAdjustment | GObject;

class Gnome::Shell::Adjustment {
  also does GLib::Roles::Object;

  has StAdjustment $!sta is implementor;

  submethod BUILD ( :$st-adjustment ) {
    self.setStAdjustment($st-adjustment) if $st-adjustment
  }

  method setStAdjustment (StAdjustmentAncestry $_) {
    my $to-parent;

    $!sta = do {
      when StAdjustment {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StAdjustment, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::StAdjustment
    is also<StAdjustment>
  { $!sta }

  multi method new (StAdjustmentAncestry $st-adjustment, :$ref = True) {
    return unless $st-adjustment;

    my $o = self.bless( :$st-adjustment );
    $o.ref if $ref;
    $o;
  }
  multi method new (
    MutterClutterActor() $actor,
    Num()                $value,
    Num()                $lower,
    Num()                $upper,
    Num()                $step_increment,
    Num()                $page_increment,
    Num()                $page_size
  ) {
    my gdouble ($v, $l, $u, $si, $pi, $ps) =
      ($value, $lower, $upper, $step_increment, $page_increment, $page_size);

    my $st-adjustment = st_adjustment_new($actor, $v, $l, $u, $si, $pi, $ps);
  }

  # Type: MutterClutterActor
  method actor ( :$raw = False ) is rw  is g-property {
    my $gv = GLib::Value.new( Mutter::Clutter::Actor.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('actor', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Mutter::Clutter::Actor.getTypePair
        )
      },
      STORE => -> $, MutterClutterActor() $val is copy {
        $gv.object = $val;
        self.prop_set('actor', $gv);
      }
    );
  }

  # Type: double
  method lower is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_DOUBLE );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('lower', $gv);
        $gv.double;
      },
      STORE => -> $, Num() $val is copy {
        $gv.double = $val;
        self.prop_set('lower', $gv);
      }
    );
  }

  # Type: double
  method upper is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_DOUBLE );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('upper', $gv);
        $gv.double;
      },
      STORE => -> $, Num() $val is copy {
        $gv.double = $val;
        self.prop_set('upper', $gv);
      }
    );
  }

  # Type: double
  method value is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_DOUBLE );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('value', $gv);
        $gv.double;
      },
      STORE => -> $, Num() $val is copy {
        $gv.double = $val;
        self.prop_set('value', $gv);
      }
    );
  }

  # Type: double
  method step-increment is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_DOUBLE );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('step-increment', $gv);
        $gv.double;
      },
      STORE => -> $, Num() $val is copy {
        $gv.double = $val;
        self.prop_set('step-increment', $gv);
      }
    );
  }

  # Type: double
  method page-increment is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_DOUBLE );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('page-increment', $gv);
        $gv.double;
      },
      STORE => -> $, Num() $val is copy {
        $gv.double = $val;
        self.prop_set('page-increment', $gv);
      }
    );
  }

  # Type: double
  method page-size is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_DOUBLE );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('page-size', $gv);
        $gv.double;
      },
      STORE => -> $, Num() $val is copy {
        $gv.double = $val;
        self.prop_set('page-size', $gv);
      }
    );
  }

  # Is originally:
  # StAdjustment *adjustment --> void
  method changed {
    self.connect($!sta, 'changed');
  }

  method add_transition (Str() $name, MutterClutterTransition() $transition)
    is also<add-transition>
  {
    st_adjustment_add_transition($!sta, $name, $transition);
  }

  method adjust_for_scroll_event (Num() $delta)
    is also<adjust-for-scroll-event>
  {
    my gdouble $d = $delta;

    st_adjustment_adjust_for_scroll_event($!sta, $d);
  }

  method clamp_page (Num() $lower, Num() $upper) is also<clamp-page> {
    my gdouble ($l, $u) = ($lower, $upper);

    st_adjustment_clamp_page($!sta, $l, $u)
  }

  method get_transition (Str() $name) is also<get-transition> {
    st_adjustment_get_transition($!sta, $name);
  }

  method get_value is also<get-value> {
    st_adjustment_get_value($!sta);
  }

  proto method get_values (|)
    is also<get-values>
  { * }

  multi method get_values {
    samewith($, $, $, $, $, $);
  }
  multi method get_values (
    $value          is rw,
    $lower          is rw,
    $upper          is rw,
    $step_increment is rw,
    $page_increment is rw,
    $page_size      is rw
  ) {
    my gdouble ($v, $l, $u, $si, $pi, $ps) = 0e0 xx 6;

    st_adjustment_get_values($!sta, $v, $l, $u, $si, $pi, $ps);

    ($value, $lower, $upper, $step_increment, $page_increment, $page_size) =
      ($v, $l, $u, $si, $pi, $ps)
  }

  method remove_transition (Str() $name) is also<remove-transition> {
    st_adjustment_remove_transition($!sta, $name);
  }

  method set_value (Num() $value) is also<set-value> {
    my gdouble $v = $value;

    st_adjustment_set_value($!sta, $value);
  }

  method set_values (
    Num() $value,
    Num() $lower,
    Num() $upper,
    Num() $step_increment,
    Num() $page_increment,
    Num() $page_size
  )
    is also<set-values>
  {
    my gdouble ($v, $l, $u, $si, $pi, $ps) =
      ($value, $lower, $upper, $step_increment, $page_increment, $page_size);

    st_adjustment_set_values($!sta, $v, $l, $u, $si, $pi, $ps);
  }

}
