use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use GLib::Raw::Structs;
use Mutter::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;
use Gnome::Shell::Raw::Enums;
use Gnome::Shell::Raw::Structs;

unit package Gnome::Shell::Raw::Clipboard;

### /home/cbwood/Projects/gnome-shell/src/st/st-clipboard.h

sub st_clipboard_get_content (
  StClipboard     $clipboard,
  StClipboardType $type,
  Str             $mimetype,
                  &callback (StClipboard, GBytes, gpointer),
  gpointer        $user_data
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_clipboard_get_default ()
  returns StClipboard
  is native(gnome-shell-st)
  is export
{ * }

sub st_clipboard_get_mimetypes (StClipboard $clipboard, StClipboardType $type)
  returns GList
  is native(gnome-shell-st)
  is export
{ * }

sub st_clipboard_get_text (
  StClipboard     $clipboard,
  StClipboardType $type,
                  &callback (StClipboard, Str, gpointer),
  gpointer        $user_data
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_clipboard_set_content (
  StClipboard     $clipboard,
  StClipboardType $type,
  Str             $mimetype,
  GBytes          $bytes
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_clipboard_set_selection (MutterMetaSelection $selection)
  is native(gnome-shell-st)
  is export
{ * }

sub st_clipboard_set_text (
  StClipboard     $clipboard,
  StClipboardType $type,
  Str             $text
)
  is native(gnome-shell-st)
  is export
{ * }
