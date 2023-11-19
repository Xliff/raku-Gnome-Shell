use v6.c;

use Method::Also;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::St::ScrollView;

use Gnome::Shell::St::Widget;

use GLib::Roles::Implementor;


our subset StScrollViewAncestry is export of Mu
  where StScrollView | StWidgetAncestry;

class Gnome::Shell::St::ScrollView is Gnome::Shell::St::Widget {
  has StScrollView $!stsv is implementor;

  submethod BUILD ( :$st-scroll-view ) {
    self.setStScrollView($st-scroll-view) if $st-scroll-view;
  }

  method setStScrollView (StScrollViewAncestry $_) {
    my $to-parent;

    $!stsv = do {
      when StScrollView {
        $to-parent = cast(StWidget, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StScrollView, $_);
      }
    }
    self.setStWidget($to-parent);
  }

  method Mutter::Cogl::Raw::Definitions::StScrollView
    is also<StScrollView>
  { $!stsv }

  multi method new (StScrollViewAncestry $st-scroll-view, :$ref = True) {
    return unless $st-scroll-view;

    my $o = self.bless( :$st-scroll-view );
    $o.ref if $ref;
    $o;
  }
  multi method new ( *%a ) {
    my $st-scroll-view = st_scroll_view_new();

    my $o = $st-scroll-view ?? self.bless( $st-scroll-view ) !! Nil;
    $o.setAtributes( |%a ) if $o && +%a;
    $o;
  }

  # Type: StScrollBar
  method hscroll ( :$raw = False ) is rw is g-property {
    my $gv = GLib::Value.new( Gnome::Shell::ScrollBar.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('hscroll', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Gnome::Shell::ScrollBar.getTypePair
        );
      },
      STORE => -> $,  $val is copy {
        warn 'hscroll does not allow writing'
      }
    );
  }

  # Type: StScrollBar
  method vscroll ( :$raw = False ) is rw is g-property {
    my $gv = GLib::Value.new( Gnome::Shell::ScrollBar.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('vscroll', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Gnome::Shell::ScrollBar.getTypePair
        );
      },
      STORE => -> $,  $val is copy {
        warn 'vscroll does not allow writing'
      }
    );
  }

  # Type: StPolicyType
  method vscrollbar-policy is rw is g-property is also<vscrollbar_policy> {
    my $gv = GLib::Value.new( GLib::Value.typeFromEnum(StPolicyType) );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('vscrollbar-policy', $gv);
        StPolicyTypeEnum( $gv.valueFromEnum(StPolicyType) );
      },
      STORE => -> $, Int() $val is copy {
        $gv.valueFromEnum(StPolicyType) = $val;
        self.prop_set('vscrollbar-policy', $gv);
      }
    );
  }

  # Type: StPolicyType
  method hscrollbar-policy is rw is g-property is also<hscrollbar_policy> {
    my $gv = GLib::Value.new( GLib::Value.typeFromEnum(StPolicyType) );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('hscrollbar-policy', $gv);
        StPolicyTypeEnum( $gv.valueFromEnum(StPolicyType) );
      },
      STORE => -> $, Int() $val is copy {
        $gv.valueFromEnum(StPolicyType) = $val;
        self.prop_set('hscrollbar-policy', $gv);
      }
    );
  }

  # Type: boolean
  method hscrollbar-visible is rw  is g-property is also<hscrollbar_visible> {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('hscrollbar-visible', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        warn 'hscrollbar-visible does not allow writing'
      }
    );
  }

  # Type: boolean
  method vscrollbar-visible is rw  is g-property is also<vscrollbar_visible> {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('vscrollbar-visible', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        warn 'vscrollbar-visible does not allow writing'
      }
    );
  }

  # Type: boolean
  method enable-mouse-scrolling
    is rw
    is g-property
    is also<enable_mouse_scrolling>
  {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('enable-mouse-scrolling', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        $gv.boolean = $val;
        self.prop_set('enable-mouse-scrolling', $gv);
      }
    );
  }

  # Type: boolean
  method overlay-scrollbars
    is rw
    is g-property
    is also<overlay_scrollbars>
  {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('overlay-scrollbars', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        $gv.boolean = $val;
        self.prop_set('overlay-scrollbars', $gv);
      }
    );
  }

  method get_column_size is also<get-column-size> {
    st_scroll_view_get_column_size($!stsv);
  }

  method get_hscroll_bar( :$raw = False ) is also<get-hscroll-bar> {
    propReturnObject(
      st_scroll_view_get_hscroll_bar($!stsv),
      $raw,
      |Gnome::Shell::ScrollBar.getTypePair
    );
  }

  method get_mouse_scrolling is also<get-mouse-scrolling> {
    st_scroll_view_get_mouse_scrolling($!stsv);
  }

  method get_overlay_scrollbars is also<get-overlay-scrollbars> {
    st_scroll_view_get_overlay_scrollbars($!stsv);
  }

  method get_row_size is also<get-row-size> {
    st_scroll_view_get_row_size($!stsv);
  }

  method get_vscroll_bar ( :$raw = False ) is also<get-vscroll-bar> {
    propReturnObject(
      st_scroll_view_get_vscroll_bar($!stsv),
      $raw,
      |Gnome::Shell::ScrollBar.getTypePair
    );
  }

  method set_column_size (Num() $column_size) is also<set-column-size> {
    my gfloat $c = $column_size;

    st_scroll_view_set_column_size($!stsv, $c);
  }

  method set_mouse_scrolling (Int() $enabled) is also<set-mouse-scrolling> {
    my gboolean $e = $enabled.so.Int;

    st_scroll_view_set_mouse_scrolling($!stsv, $e);
  }

  method set_overlay_scrollbars (Int() $enabled)
    is also<set-overlay-scrollbars>
  {
    my gboolean $e = $enabled.so.Int;

    st_scroll_view_set_overlay_scrollbars($!stsv, $e);
  }

  method set_policy (Int() $hscroll, Int() $vscroll) is also<set-policy> {
    my StPolicyType ($h, $v) = ($hscroll, $vscroll);

    st_scroll_view_set_policy($!stsv, $h, $v);
  }

  method set_row_size (Num() $row_size) is also<set-row-size> {
    my gfloat $r = $row_size;

    st_scroll_view_set_row_size($!stsv, $r);
  }

  method update_fade_effect (MutterClutterMargin() $fade_margins)
    is also<update-fade-effect>
  {
    st_scroll_view_update_fade_effect($!stsv, $fade_margins);
  }

}
