use v6.c;

use Method::Also;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::Button;

use Gnome::Shell::Widget;

use GLib::Roles::Implementor;


our subset StButtonAncestry is export of Mu
  where StButton | StWidgetAncestry;

class Gnome::Shell::Button is Gnome::Shell::Widget {
  has StButton $!stb is implementor;

  submethod BUILD ( :$st-widget ) {
    self.setStButton($st-widget) if $st-widget
  }

  method setStButton (StButtonAncestry $_) {
    my $to-parent;

    $!stb = do {
      when StButton {
        $to-parent = cast(StWidget, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StButton, $_);
      }
    }
    self.setStWidget($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::StButton
    is also<StButton>
  { $!stb }

  multi method new (StButtonAncestry $st-widget, :$ref = True) {
    return unless $st-widget;

    my $o = self.bless( :$st-widget );
    $o.ref if $ref;
    $o;
  }
  multi method new (*%props) {
    my $st-button = st_button_new();

    $st-button ?? self.bless( :$st-button, |%props ) !! Nil;
  }

  method new_with_label (Str() $text, *%props) is also<new-with-label> {
    my $st-button = st_button_new_with_label($text);

    $st-button ?? self.bless( :$st-button, |%props ) !! Nil;
  }

  # Type: string
  method label is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_STRING );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('label', $gv);
        $gv.string;
      },
      STORE => -> $, Str() $val is copy {
        $gv.string = $val;
        self.prop_set('label', $gv);
      }
    );
  }

  # Type: string
  method icon-name is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_STRING );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('icon-name', $gv);
        $gv.string;
      },
      STORE => -> $, Str() $val is copy {
        $gv.string = $val;
        self.prop_set('icon-name', $gv);
      }
    );
  }

  # Type: StButtonMask
  method button-mask is rw  is g-property {
    my $gv = GLib::Value.new( GLib::Value.typeFromEnum(StButtonMask) );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('button-mask', $gv);
        $gv.valueFromEnum(StButtonMask);
      },
      STORE => -> $, Int() $val is copy {
        $gv.valueFromEnum(StButtonMask) = $val;
        self.prop_set('button-mask', $gv);
      }
    );
  }

  # Type: boolean
  method toggle-mode is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('toggle-mode', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        $gv.boolean = $val;
        self.prop_set('toggle-mode', $gv);
      }
    );
  }

  # Type: boolean
  method checked is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('checked', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        $gv.boolean = $val;
        self.prop_set('checked', $gv);
      }
    );
  }

  # Type: boolean
  method pressed is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('pressed', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        warn 'pressed does not allow writing'
      }
    );
  }

  method clicked {
    self.connect($!stb, 'clicked');
  }

  method fake_release is also<fake-release> {
    st_button_fake_release($!stb);
  }

  method get_button_mask is also<get-button-mask> {
    st_button_get_button_mask($!stb);
  }

  method get_checked is also<get-checked> {
    so st_button_get_checked($!stb);
  }

  method get_icon_name is also<get-icon-name> {
    st_button_get_icon_name($!stb);
  }

  method get_label is also<get-label> {
    st_button_get_label($!stb);
  }

  method get_toggle_mode is also<get-toggle-mode> {
    so st_button_get_toggle_mode($!stb);
  }

  method set_button_mask (Int() $mask) is also<set-button-mask> {
    my StButtonMask $m = $mask;

    st_button_set_button_mask($!stb, $m);
  }

  method set_checked (Int() $checked) is also<set-checked> {
    my gboolean $c = $checked.so.Int;

    st_button_set_checked($!stb, $checked);
  }

  method set_icon_name (Str() $icon_name) is also<set-icon-name> {
    st_button_set_icon_name($!stb, $icon_name);
  }

  method set_label (Str() $text) is also<set-label> {
    st_button_set_label($!stb, $text);
  }

  method set_toggle_mode (Int() $toggle) is also<set-toggle-mode> {
    my gboolean $t = $toggle.so.Int;

    st_button_set_toggle_mode($!stb, $t);
  }

}
