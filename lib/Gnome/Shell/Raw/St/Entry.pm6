use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Mutter::Raw::Definitions;
use Mutter::Raw::Enums;
use Gnome::Shell::Raw::Definitions;

unit package Gnome::Shell::Raw::St::Entry;

### /home/cbwood/Projects/gnome-shell/src/st/st-entry.h

sub st_entry_get_clutter_text (StEntry $entry)
  returns MutterClutterText
  is native(gnome-shell-st)
  is export
{ * }

sub st_entry_get_hint_actor (StEntry $entry)
  returns MutterClutterActor
  is native(gnome-shell-st)
  is export
{ * }

sub st_entry_get_hint_text (StEntry $entry)
  returns Str
  is native(gnome-shell-st)
  is export
{ * }

sub st_entry_get_input_hints (StEntry $entry)
  returns MutterClutterInputContentHintFlags
  is native(gnome-shell-st)
  is export
{ * }

sub st_entry_get_input_purpose (StEntry $entry)
  returns MutterClutterInputContentPurpose
  is native(gnome-shell-st)
  is export
{ * }

sub st_entry_get_primary_icon (StEntry $entry)
  returns MutterClutterActor
  is native(gnome-shell-st)
  is export
{ * }

sub st_entry_get_secondary_icon (StEntry $entry)
  returns MutterClutterActor
  is native(gnome-shell-st)
  is export
{ * }

sub st_entry_get_text (StEntry $entry)
  returns Str
  is native(gnome-shell-st)
  is export
{ * }

sub st_entry_new (Str $text)
  returns StWidget
  is native(gnome-shell-st)
  is export
{ * }

sub st_entry_set_cursor_func (
           &func (StEntry, gboolean, gpointer),
  gpointer $user_data
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_entry_set_hint_actor (StEntry $entry, MutterClutterActor $hint_actor)
  is native(gnome-shell-st)
  is export
{ * }

sub st_entry_set_hint_text (StEntry $entry, Str $text)
  is native(gnome-shell-st)
  is export
{ * }

sub st_entry_set_input_hints (
  StEntry                            $entry,
  MutterClutterInputContentHintFlags $hints
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_entry_set_input_purpose (
  StEntry                          $entry,
  MutterClutterInputContentPurpose $purpose
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_entry_set_primary_icon (StEntry $entry, MutterClutterActor $icon)
  is native(gnome-shell-st)
  is export
{ * }

sub st_entry_set_secondary_icon (StEntry $entry, MutterClutterActor $icon)
  is native(gnome-shell-st)
  is export
{ * }

sub st_entry_set_text (StEntry $entry, Str $text)
  is native(gnome-shell-st)
  is export
{ * }
