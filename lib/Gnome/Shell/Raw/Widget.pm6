use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use ATK::Raw::Definitions:
use Mutter::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;

unit package Gnome::Shell::Raw::Widget;

### /home/cbwood/Projects/gnome-shell/src/st/st-widget.h

sub st_widget_add_accessible_state (StWidget $widget, AtkStateType $state)
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_add_style_class_name (StWidget $actor, Str $style_class)
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_add_style_pseudo_class (StWidget $actor, Str $pseudo_class)
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_ensure_style (StWidget $widget)
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_get_accessible_name (StWidget $widget)
  returns Str
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_get_accessible_role (StWidget $widget)
  returns AtkRole
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_get_can_focus (StWidget $widget)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_get_focus_chain (StWidget $widget)
  returns GList
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_get_hover (StWidget $widget)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_get_label_actor (StWidget $widget)
  returns MutterClutterActor
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_get_style (StWidget $actor)
  returns Str
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_get_style_class_name (StWidget $actor)
  returns Str
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_get_style_pseudo_class (StWidget $actor)
  returns Str
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_get_theme_node (StWidget $widget)
  returns StThemeNode
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_get_track_hover (StWidget $widget)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_has_style_class_name (StWidget $actor, Str $style_class)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_has_style_pseudo_class (StWidget $actor, Str $pseudo_class)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_navigate_focus (
  StWidget        $widget,
  MutterClutterActor    $from,
  StDirectionType $direction,
  gboolean        $wrap_around
)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_paint_background (
  StWidget            $widget,
  MutterClutterPaintContext $paint_context
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_peek_theme_node (StWidget $widget)
  returns StThemeNode
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_popup_menu (StWidget $self)
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_remove_accessible_state (StWidget $widget, AtkStateType $state)
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_remove_style_class_name (StWidget $actor, Str $style_class)
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_remove_style_pseudo_class (StWidget $actor, Str $pseudo_class)
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_set_accessible (StWidget $widget, AtkObject $accessible)
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_set_accessible_name (StWidget $widget, Str $name)
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_set_accessible_role (StWidget $widget, AtkRole $role)
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_set_can_focus (StWidget $widget, gboolean $can_focus)
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_set_hover (StWidget $widget, gboolean $hover)
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_set_label_actor (StWidget $widget, MutterClutterActor $label)
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_set_style (StWidget $actor, Str $style)
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_set_style_class_name (StWidget $actor, Str $style_class_list)
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_set_style_pseudo_class (StWidget $actor, Str $pseudo_class_list)
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_set_track_hover (StWidget $widget, gboolean $track_hover)
  is native(gnome-shell-st)
  is export
{ * }

sub st_describe_actor (MutterClutterActor $actor)
  returns Str
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_style_changed (StWidget $widget)
  is native(gnome-shell-st)
  is export
{ * }

sub st_widget_sync_hover (StWidget $widget)
  is native(gnome-shell-st)
  is export
{ * }
