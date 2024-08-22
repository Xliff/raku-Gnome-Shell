use v6.c;

use Method::Also;
use NativeCall;

use GLib::Raw::Definitions;
use GLib::Raw::Structs;
use GDK::Pixbuf::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;

unit package Gnome::Shell::Raw::St::IconCache;

### /home/cbwood/Projects/gnome-shell/src/st/st-icon-cache.h

sub st_icon_cache_add_icons (
  StIconCache $cache,
  Str         $directory,
  GHashTable  $hash_table
)
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_cache_get_directory_index (
  StIconCache $cache,
  Str         $directory
)
  returns gint
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_cache_get_icon (
  StIconCache $cache,
  Str         $icon_name,
  gint        $directory_index
)
  returns GdkPixbuf
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_cache_get_icon_flags (
  StIconCache $cache,
  Str         $icon_name,
  gint        $directory_index
)
  returns gint
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_cache_has_icon (
  StIconCache $cache,
  Str         $icon_name
)
  returns uint32
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_cache_has_icon_in_directory (
  StIconCache $cache,
  Str         $icon_name,
  Str         $directory
)
  returns uint32
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_cache_has_icons (
  StIconCache $cache,
  Str         $directory
)
  returns uint32
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_cache_new (CArray[uint8] $data)
  returns StIconCache
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_cache_new_for_path (Str $path)
  returns StIconCache
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_cache_ref (StIconCache $cache)
  returns StIconCache
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_cache_unref (StIconCache $cache)
  is      native(gnome-shell)
  is      export
{ * }
