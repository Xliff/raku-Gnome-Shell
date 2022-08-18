use v6.c;

use Method::Also;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::Icon;

use Gnome::Shell::Widget;

use GLib::Roles::Implementor;
use GIO::Roles::Icon;

our subset StIconAncestry is export of Mu
  where StIcon | StWidgetAncestry;

class Gnome::Shell::Icon is Gnome::Shell::Widget {
  has StIcon $!sti is implementor;

  submethod BUILD ( :$st-icon ) {
    self.setStIcon($st-icon) if $st-icon;
  }

  method setStIcon (StIconAncestry $_) {
    my $to-parent;

    $!sti = do {
      when StIcon {
        $to-parent = cast(StWidget, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StIcon, $_);
      }
    }
    self.setStWidget($to-parent);
  }

  method Gnome::Shell::Raw::Structs::StIcon
    is also<StIcon>
  { $!sti }

  multi method new (StIconAncestry $st-icon, :$ref = True) {
    return unless $st-icon;

    my $o = self.bless( :$st-icon );
    $o.ref if $ref;
    $o;
  }
  multi method new {
    my $st-icon = st_icon_new();

    $st-icon ?? self.bless( :$st-icon ) !! Nil;
  }

  # Type: StIcon
  method gicon ( :$raw = False ) is rw is g-property {
    my $gv = GLib::Value.new( StIcon );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('gicon', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |GIO::Icon.getTypePair
        );
      },
      STORE => -> $, StIcon() $val is copy {
        $gv.object = $val;
        self.prop_set('gicon', $gv);
      }
    );
  }

  # Type: StIcon
  method fallback-gicon ( :$raw = False ) is rw is g-property {
    my $gv = GLib::Value.new( GIO::Icon.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('fallback-gicon', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |GIO::Icon.getTypePair
        );
      },
      STORE => -> $, GIcon() $val is copy {
        $gv.object = $val;
        self.prop_set('fallback-gicon', $gv);
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

  # Type: int
  method icon-size is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_INT );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('icon-size', $gv);
        $gv.int;
      },
      STORE => -> $, Int() $val is copy {
        $gv.int = $val;
        self.prop_set('icon-size', $gv);
      }
    );
  }

  # Type: string
  method fallback-icon-name is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_STRING );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('fallback-icon-name', $gv);
        $gv.string;
      },
      STORE => -> $, Str() $val is copy {
        $gv.string = $val;
        self.prop_set('fallback-icon-name', $gv);
      }
    );
  }

  method get_fallback_gicon ( :$raw = False ) is also<get-fallback-gicon> {
    propReturnObject(
      st_icon_get_fallback_gicon($!sti),
      $raw,
      |GIO::Icon.getTypePair
    );
  }

  method get_fallback_icon_name is also<get-fallback-icon-name> {
    st_icon_get_fallback_icon_name($!sti);
  }

  method get_gicon ( :$raw = False ) is also<get-gicon> {
    propReturnObject(
      st_icon_get_gicon($!sti),
      $raw,
      |GIO::Icon.getTypePair
    );
  }

  method get_icon_name is also<get-icon-name> {
    st_icon_get_icon_name($!sti);
  }

  method get_icon_size is also<get-icon-size> {
    st_icon_get_icon_size($!sti);
  }

  method set_fallback_gicon (GIcon() $fallback_gicon)
    is also<set-fallback-gicon>
  {
    st_icon_set_fallback_gicon($!sti, $fallback_gicon);
  }

  method set_fallback_icon_name (Str() $fallback_icon_name)
    is also<set-fallback-icon-name>
  {
    st_icon_set_fallback_icon_name($!sti, $fallback_icon_name);
  }

  method set_gicon (GIcon() $gicon) is also<set-gicon> {
    st_icon_set_gicon($!sti, $gicon);
  }

  method set_icon_name (Str() $icon_name) is also<set-icon-name> {
    st_icon_set_icon_name($!sti, $icon_name);
  }

  method set_icon_size (Int() $size) is also<set-icon-size> {
    my gint $s = $size;

    st_icon_set_icon_size($!sti, $s);
  }

}
