use v6.c;

use Method::Also;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::Widget;

use ATK::Role;
use GLib::GList;
use Mutter::Clutter::Actor;

use GLib::Roles::Implementor;

our subset StWidgetAncestry is export of Mu
  where StWidget | MutterClutterActorAncestry;

class Gnome::Shell::Widget is Mutter::Clutter::Actor {
  has StWidget $!stw is implementor;

  submethod BUILD ( :$st-widget, *%props ) {
    self.setStWidget($st-widget) if $st-widget;

    self."{ .key }"() = .value for %props.pairs;
  }

  method setStWidget (StWidgetAncestry $_) {
    my $to-parent;

    $!stw = do {
      when StWidget {
        $to-parent = cast(MutterClutterActor, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StWidget, $_);
      }
    }
    self.setMutterClutterActor($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::StWidget
    is also<StWidget>
  { $!stw }

  multi method new (StWidgetAncestry $st-widget, :$ref = True) {
    return unless $st-widget;

    my $o = self.bless( :$st-widget );
    $o.ref if $ref;
    $o;
  }

  # Type: string
  method pseudo-class is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_STRING );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('pseudo-class', $gv);
        $gv.string;
      },
      STORE => -> $, Str() $val is copy {
        $gv.string = $val;
        self.prop_set('pseudo-class', $gv);
      }
    );
  }

  # Type: string
  method style-class is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_STRING );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('style-class', $gv);
        $gv.string;
      },
      STORE => -> $, Str() $val is copy {
        $gv.string = $val;
        self.prop_set('style-class', $gv);
      }
    );
  }

  # Type: string
  method style is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_STRING );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('style', $gv);
        $gv.string;
      },
      STORE => -> $, Str() $val is copy {
        $gv.string = $val;
        self.prop_set('style', $gv);
      }
    );
  }

  # Type: boolean
  method track-hover is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('track-hover', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        $gv.boolean = $val;
        self.prop_set('track-hover', $gv);
      }
    );
  }

  # Type: boolean
  method hover is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('hover', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        $gv.boolean = $val;
        self.prop_set('hover', $gv);
      }
    );
  }

  # Type: boolean
  method can-focus is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('can-focus', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        $gv.boolean = $val;
        self.prop_set('can-focus', $gv);
      }
    );
  }

  # Type: MutterClutterActor
  method label-actor ( :$raw = False )  is rw  is g-property {
    my $gv = GLib::Value.new( Mutter::Clutter::Actor.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('label-actor', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Mutter::Clutter::Actor.getTypePair
        );
      },
      STORE => -> $, MutterClutterActor() $val is copy {
        $gv.object = $val;
        self.prop_set('label-actor', $gv);
      }
    );
  }

  # Type: AtkRole
  method accessible-role ( :$raw = False ) is rw is g-property {
    my $gv = GLib::Value.new( ATK::Role.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('accessible-role', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |ATK::Role.getTypePair
        );
      },
      STORE => -> $, AtkRole() $val is copy {
        $gv.object = $val;
        self.prop_set('accessible-role', $gv);
      }
    );
  }

  # Type: string
  method accessible-name is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_STRING );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('accessible-name', $gv);
        $gv.string;
      },
      STORE => -> $, Str() $val is copy {
        $gv.string = $val;
        self.prop_set('accessible-name', $gv);
      }
    );
  }

  # Is originally:
  # StWidget *self --> void
  method style-changed {
    self.connect($!stw, 'style-changed');
  }

  # Is originally:
  # StWidget *self --> void
  method popup-menu {
    self.connect($!stw, 'popup-menu');
  }

  method add_accessible_state (Int() $state) is also<add-accessible-state> {
    my AtkStateType $s = $state;

    st_widget_add_accessible_state($!stw, $s);
  }

  method add_style_class_name (Str() $style_class)
    is also<add-style-class-name>
  {
    st_widget_add_style_class_name($!stw, $style_class);
  }

  method add_style_pseudo_class (Str() $pseudo_class)
    is also<add-style-pseudo-class>
  {
    st_widget_add_style_pseudo_class($!stw, $pseudo_class);
  }

  method ensure_style is also<ensure-style> {
    st_widget_ensure_style($!stw);
  }

  method get_accessible_name is also<get-accessible-name> {
    st_widget_get_accessible_name($!stw);
  }

  method get_accessible_role ( :$raw = False ) is also<get-accessible-role> {
    propReturnObject(
      st_widget_get_accessible_role($!stw),
      $raw,
      |ATK::Role.getTypePair
    )
  }

  method get_can_focus is also<get-can-focus> {
    so st_widget_get_can_focus($!stw);
  }

  method get_focus_chain ( :$raw = False, :$glist = False )
    is also<get-focus-chain>
  {
    returnGList(
      st_widget_get_focus_chain($!stw),
      $raw,
      $glist,
      |Mutter::Clutter::Actor.getTypePair
    );
  }

  method get_hover is also<get-hover> {
    st_widget_get_hover($!stw);
  }

  method get_label_actor ( :$raw = False ) is also<get-label-actor> {
    propReturnObject(
      st_widget_get_label_actor($!stw),
      $raw,
      |Mutter::Clutter::Actor.getTypePair
    );
  }

  method get_style is also<get-style> {
    st_widget_get_style($!stw);
  }

  method get_style_class_name is also<get-style-class-name> {
    st_widget_get_style_class_name($!stw);
  }

  method get_style_pseudo_class is also<get-style-pseudo-class> {
    st_widget_get_style_pseudo_class($!stw);
  }

  method get_theme_node ( :$raw = False ) is also<get-theme-node> {
    propReturnObject(
      st_widget_get_theme_node($!stw),
      $raw,
      |Gnome::Shell::Theme::Node.getTypePair
    );
  }

  method get_track_hover is also<get-track-hover> {
    so st_widget_get_track_hover($!stw);
  }

  method has_style_class_name (Str() $style_class)
    is also<has-style-class-name>
  {
    so st_widget_has_style_class_name($!stw, $style_class);
  }

  method has_style_pseudo_class (Str() $pseudo_class)
    is also<has-style-pseudo-class>
  {
    so st_widget_has_style_pseudo_class($!stw, $pseudo_class);
  }

  method navigate_focus (
    MutterClutterActor() $from,
    Int()          $direction,
    Int()          $wrap_around
  )
    is also<navigate-focus>
  {
    my StDirectionType $d = $direction;
    my gboolean        $w = $wrap_around.so.Int;

    st_widget_navigate_focus($!stw, $from, $d, $w);
  }

  method paint_background (MutterClutterPaintContext() $paint_context)
    is also<paint-background>
  {
    st_widget_paint_background($!stw, $paint_context);
  }

  method peek_theme_node is also<peek-theme-node> {
    st_widget_peek_theme_node($!stw);
  }

  method popup_menu {
    st_widget_popup_menu($!stw);
  }

  method remove_accessible_state (Int() $state)
    is also<remove-accessible-state>
  {
    my AtkStateType $s = $state;

    st_widget_remove_accessible_state($!stw, $state);
  }

  method remove_style_class_name (Str() $style_class)
    is also<remove-style-class-name>
  {
    st_widget_remove_style_class_name($!stw, $style_class);
  }

  method remove_style_pseudo_class (Str() $pseudo_class)
    is also<remove-style-pseudo-class>
  {
    st_widget_remove_style_pseudo_class($!stw, $pseudo_class);
  }

  method set_accessible (AtkObject() $accessible) is also<set-accessible> {
    st_widget_set_accessible($!stw, $accessible);
  }

  method set_accessible_name (Str() $name) is also<set-accessible-name> {
    st_widget_set_accessible_name($!stw, $name);
  }

  method set_accessible_role (AtkRole() $role) is also<set-accessible-role> {
    st_widget_set_accessible_role($!stw, $role);
  }

  method set_can_focus (Int() $can_focus) is also<set-can-focus> {
    my gboolean $c = $can_focus.so.Int;

    st_widget_set_can_focus($!stw, $can_focus);
  }

  method set_hover (Int() $hover) is also<set-hover> {
    my gboolean $h = $hover.so.Int;

    st_widget_set_hover($!stw, $hover);
  }

  method set_label_actor (MutterClutterActor() $label)
    is also<set-label-actor>
  {
    st_widget_set_label_actor($!stw, $label);
  }

  method set_style (Str() $style) is also<set-style> {
    st_widget_set_style($!stw, $style);
  }

  method set_style_class_name (Str() $style_class_list)
    is also<set-style-class-name>
  {
    st_widget_set_style_class_name($!stw, $style_class_list);
  }

  method set_style_pseudo_class (Str() $pseudo_class_list)
    is also<set-style-pseudo-class>
  {
    st_widget_set_style_pseudo_class($!stw, $pseudo_class_list);
  }

  method set_track_hover (Int() $track_hover) is also<set-track-hover> {
    my gboolean $t = $track_hover.so.Int;

    st_widget_set_track_hover($!stw, $track_hover);
  }

  method describe_actor (MutterClutterActor() $actor)
    is static
    is also<describe-actor>
  {
    st_describe_actor($actor);
  }

  method style_changed {
    st_widget_style_changed($!stw);
  }

  method sync_hover is also<sync-hover> {
    st_widget_sync_hover($!stw);
  }

}
