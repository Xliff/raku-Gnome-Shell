use v6.c;

use Method::Also;

use NativeCall;

use Gnome::Shell::Raw::Types;

use Mutter::Clutter::Text;
use Gnome::Shell::Widget;

our subset StLabelAncestry is export of Mu
  where StLabel | StWidgetAncestry;

class Gnome::Shell::Label is Gnome::Shell::Widget {
  has StLabel $!stl is implementor;

  submethod BUILD ( :$st-label ) {
    self.setStLabel($st-label) if $st-label
  }

  method setStLabel (StLabelAncestry $_) {
    my $to-parent;

    $!stl = do {
      when StLabel {
        $to-parent = cast(StWidget, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StLabel, $_);
      }
    }
    self.setStWidget($to-parent);
  }

  method Mutter::Clutter::Raw::Definitions::StLabel
    is also<StLabel>
  { $!stl }

  multi method new (StLabelAncestry $st-label, :$ref = True) {
    return unless $st-label;

    my $o = self.bless( :$st-label );
    $o.ref if $ref;
    $o;
  }

  method new {
    my $st-label = st_label_new();

    $st-label ?? self.bless( :$st-label ) !! Nil;
  }

  # Type: StText
  method clutter-text ( :$raw = False ) is rw is g-property
    is also<clutter_text>
  {
    my $gv = GLib::Value.new( StText );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('clutter-text', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Mutter::Clutter::Text.getTypePair
        )
      },
      STORE => -> $,  $val is copy {
        warn 'clutter-text does not allow writing'
      }
    );
  }

  # Type: string
  method text is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_STRING );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('text', $gv);
        $gv.string;
      },
      STORE => -> $, Str() $val is copy {
        $gv.string = $val;
        self.prop_set('text', $gv);
      }
    );
  }

  method get_clutter_text ( :$raw = False ) is also<get-clutter-text> {
    propReturnObject(
      st_label_get_clutter_text($!stl),
      $raw,
      |Mutter::Clutter::Text.getTypePair
    );
  }

  method get_text is also<get-text> {
    st_label_get_text($!stl);
  }

  method set_text (Str() $text) is also<set-text> {
    st_label_set_text($!stl, $text);
  }

}

### /home/cbwood/Projects/gnome-shell/src/st/st-label.h

sub st_label_get_clutter_text (StLabel $label)
  returns MutterClutterText
  is native(gnome-shell-st)
  is export
{ * }

sub st_label_get_text (StLabel $label)
  returns Str
  is native(gnome-shell-st)
  is export
{ * }

sub st_label_new (Str $text)
  returns StLabel
  is native(gnome-shell-st)
  is export
{ * }

sub st_label_set_text (StLabel $label, Str $text)
  is native(gnome-shell-st)
  is export
{ * }
