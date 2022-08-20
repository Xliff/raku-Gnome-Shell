use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Mutter::Raw::Definitions;
use Mutter::Raw::Structs;
use Gnome::Shell::Raw::Definitions;
use Gnome::Shell::Raw::Enums;
use Gnome::Shell::Raw::Structs;

unit package Gnome::Shell::Raw::St::ScrollView;

### /home/cbwood/Projects/gnome-shell/src/st/st-scroll-view.h

sub st_scroll_view_get_column_size (StScrollView $scroll)
  returns gfloat
  is native(gnome-shell-st)
  is export
{ * }

sub st_scroll_view_get_hscroll_bar (StScrollView $scroll)
  returns StScrollBar
  is native(gnome-shell-st)
  is export
{ * }

sub st_scroll_view_get_mouse_scrolling (StScrollView $scroll)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_scroll_view_get_overlay_scrollbars (StScrollView $scroll)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_scroll_view_get_row_size (StScrollView $scroll)
  returns gfloat
  is native(gnome-shell-st)
  is export
{ * }

sub st_scroll_view_get_vscroll_bar (StScrollView $scroll)
  returns StScrollBar
  is native(gnome-shell-st)
  is export
{ * }

sub st_scroll_view_new ()
  returns StWidget
  is native(gnome-shell-st)
  is export
{ * }

sub st_scroll_view_set_column_size (StScrollView $scroll, gfloat $column_size)
  is native(gnome-shell-st)
  is export
{ * }

sub st_scroll_view_set_mouse_scrolling (
  StScrollView $scroll,
  gboolean     $enabled
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_scroll_view_set_overlay_scrollbars (
  StScrollView $scroll,
  gboolean     $enabled
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_scroll_view_set_policy (
  StScrollView $scroll,
  StPolicyType $hscroll,
  StPolicyType $vscroll
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_scroll_view_set_row_size (StScrollView $scroll, gfloat $row_size)
  is native(gnome-shell-st)
  is export
{ * }

sub st_scroll_view_update_fade_effect (
  StScrollView        $scroll,
  MutterClutterMargin $fade_margins
)
  is native(gnome-shell-st)
  is export
{ * }
