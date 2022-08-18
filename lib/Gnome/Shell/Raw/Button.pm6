use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;
use Gnome::Shell::Raw::Enums;

unit package Gnome::Shell::Raw::Button;

### /home/cbwood/Projects/gnome-shell/src/st/st-button.h

sub st_button_fake_release (StButton $button)
  is native(gnome-shell-st)
  is export
{ * }

sub st_button_get_button_mask (StButton $button)
  returns StButtonMask
  is native(gnome-shell-st)
  is export
{ * }

sub st_button_get_checked (StButton $button)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_button_get_icon_name (StButton $button)
  returns Str
  is native(gnome-shell-st)
  is export
{ * }

sub st_button_get_label (StButton $button)
  returns Str
  is native(gnome-shell-st)
  is export
{ * }

sub st_button_get_toggle_mode (StButton $button)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_button_new ()
  returns StButton
  is native(gnome-shell-st)
  is export
{ * }

sub st_button_new_with_label (Str $text)
  returns StButton
  is native(gnome-shell-st)
  is export
{ * }

sub st_button_set_button_mask (StButton $button, StButtonMask $mask)
  is native(gnome-shell-st)
  is export
{ * }

sub st_button_set_checked (StButton $button, gboolean $checked)
  is native(gnome-shell-st)
  is export
{ * }

sub st_button_set_icon_name (StButton $button, Str $icon_name)
  is native(gnome-shell-st)
  is export
{ * }

sub st_button_set_label (StButton $button, Str $text)
  is native(gnome-shell-st)
  is export
{ * }

sub st_button_set_toggle_mode (StButton $button, gboolean $toggle)
  is native(gnome-shell-st)
  is export
{ * }
