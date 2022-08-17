use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;

unit package Gnome::Shell::Raw::Icon;


### /home/cbwood/Projects/gnome-shell/src/st/st-icon.h

sub st_icon_get_fallback_gicon (StIcon $icon)
  returns GIcon
  is native(gnome-shell-st)
  is export
{ * }

sub st_icon_get_fallback_icon_name (StIcon $icon)
  returns Str
  is native(gnome-shell-st)
  is export
{ * }

sub st_icon_get_gicon (StIcon $icon)
  returns GIcon
  is native(gnome-shell-st)
  is export
{ * }

sub st_icon_get_icon_name (StIcon $icon)
  returns Str
  is native(gnome-shell-st)
  is export
{ * }

sub st_icon_get_icon_size (StIcon $icon)
  returns gint
  is native(gnome-shell-st)
  is export
{ * }

sub st_icon_new ()
  returns StIcon
  is native(gnome-shell-st)
  is export
{ * }

sub st_icon_set_fallback_gicon (StIcon $icon, GIcon $fallback_gicon)
  is native(gnome-shell-st)
  is export
{ * }

sub st_icon_set_fallback_icon_name (StIcon $icon, Str $fallback_icon_name)
  is native(gnome-shell-st)
  is export
{ * }

sub st_icon_set_gicon (StIcon $icon, GIcon $gicon)
  is native(gnome-shell-st)
  is export
{ * }

sub st_icon_set_icon_name (StIcon $icon, Str $icon_name)
  is native(gnome-shell-st)
  is export
{ * }

sub st_icon_set_icon_size (StIcon $icon, gint $size)
  is native(gnome-shell-st)
  is export
{ * }
