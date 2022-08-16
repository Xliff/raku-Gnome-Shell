use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;

unit package Gnome::Shell::Raw::Adjustment;

### /home/cbwood/Projects/gnome-shell/src/st/st-adjustment.h

sub st_adjustment_add_transition (
  StAdjustment            $adjustment,
  Str                     $name,
  MutterClutterTransition $transition
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_adjustment_adjust_for_scroll_event (
  StAdjustment $adjustment,
  gdouble      $delta
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_adjustment_clamp_page (
  StAdjustment $adjustment,
  gdouble      $lower,
  gdouble      $upper
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_adjustment_get_transition (StAdjustment $adjustment, Str $name)
  returns MutterClutterTransition
  is native(gnome-shell-st)
  is export
{ * }

sub st_adjustment_get_value (StAdjustment $adjustment)
  returns gdouble
  is native(gnome-shell-st)
  is export
{ * }

sub st_adjustment_get_values (
  StAdjustment $adjustment,
  gdouble      $value          is rw,
  gdouble      $lower          is rw,
  gdouble      $upper          is rw,
  gdouble      $step_increment is rw,
  gdouble      $page_increment is rw,
  gdouble      $page_size      is rw
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_adjustment_new (
  MutterClutterActor $actor,
  gdouble            $value,
  gdouble            $lower,
  gdouble            $upper,
  gdouble            $step_increment,
  gdouble            $page_increment,
  gdouble            $page_size
)
  returns StAdjustment
  is native(gnome-shell-st)
  is export
{ * }

sub st_adjustment_remove_transition (StAdjustment $adjustment, Str $name)
  is native(gnome-shell-st)
  is export
{ * }

sub st_adjustment_set_value (StAdjustment $adjustment, gdouble $value)
  is native(gnome-shell-st)
  is export
{ * }

sub st_adjustment_set_values (
  StAdjustment $adjustment,
  gdouble      $value,
  gdouble      $lower,
  gdouble      $upper,
  gdouble      $step_increment,
  gdouble      $page_increment,
  gdouble      $page_size
)
  is native(gnome-shell-st)
  is export
{ * }
