use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;

unit package Gnome::Shell::Raw::IconColors;

### /home/cbwood/Projects/gnome-shell/src/st/st-icon-colors.h

sub st_icon_colors_copy (StIconColors $colors)
  returns StIconColors
  is native(gnome-shell-st)
  is export
{ * }

sub st_icon_colors_equal (StIconColors $colors, StIconColors $other)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_icon_colors_get_type ()
  returns GType
  is native(gnome-shell-st)
  is export
{ * }

sub st_icon_colors_new ()
  returns StIconColors
  is native(gnome-shell-st)
  is export
{ * }

sub st_icon_colors_ref (StIconColors $colors)
  returns StIconColors
  is native(gnome-shell-st)
  is export
{ * }

sub st_icon_colors_unref (StIconColors $colors)
  is native(gnome-shell-st)
  is export
{ * }
