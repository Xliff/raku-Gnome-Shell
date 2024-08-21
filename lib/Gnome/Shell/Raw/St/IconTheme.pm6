use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use GLib::Raw::Structs;
use GIO::Raw::Definitions;
use GDK::Pixbuf::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;
use Gnome::Shell::Raw::Structs;
use Gnome::Shell::Raw::Enums;

### /home/cbwood/Projects/gnome-shell/src/st/st-icon-theme.h

unit package Gnome::Shell::Raw::St::IconTheme;

sub st_icon_theme_add_resource_path (
  StIconTheme $icon_theme,
  Str         $path
)
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_theme_append_search_path (
  StIconTheme $icon_theme,
  Str         $path
)
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_theme_choose_icon (
  StIconTheme       $icon_theme,
  Str               $icon_names,
  gint              $size,
  StIconLookupFlags $flags
)
  returns StIconInfo
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_theme_choose_icon_for_scale (
  StIconTheme       $icon_theme,
  Str               $icon_names,
  gint              $size,
  gint              $scale,
  StIconLookupFlags $flags
)
  returns StIconInfo
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_theme_error_quark
  returns GQuark
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_theme_get_icon_sizes (
  StIconTheme $icon_theme,
  Str         $icon_name
)
  returns gint
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_theme_get_search_path (
  StIconTheme $icon_theme,
  CArray[Str] $path,
  gint        $n_elements is rw
)
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_theme_has_icon (
  StIconTheme $icon_theme,
  Str         $icon_name
)
  returns uint32
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_theme_list_contexts (StIconTheme $icon_theme)
  returns GList
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_theme_list_icons (
  StIconTheme $icon_theme,
  Str         $context
)
  returns GList
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_theme_load_icon (
  StIconTheme             $icon_theme,
  Str                     $icon_name,
  gint                    $size,
  StIconLookupFlags       $flags,
  CArray[Pointer[GError]] $error
)
  returns GdkPixbuf
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_theme_load_icon_for_scale (
  StIconTheme             $icon_theme,
  Str                     $icon_name,
  gint                    $size,
  gint                    $scale,
  StIconLookupFlags       $flags,
  CArray[Pointer[GError]] $error
)
  returns GdkPixbuf
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_theme_lookup_by_gicon (
  StIconTheme       $icon_theme,
  GIcon             $icon,
  gint              $size,
  StIconLookupFlags $flags
)
  returns StIconInfo
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_theme_lookup_by_gicon_for_scale (
  StIconTheme       $icon_theme,
  GIcon             $icon,
  gint              $size,
  gint              $scale,
  StIconLookupFlags $flags
)
  returns StIconInfo
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_theme_lookup_icon (
  StIconTheme       $icon_theme,
  Str               $icon_name,
  gint              $size,
  StIconLookupFlags $flags
)
  returns StIconInfo
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_theme_lookup_icon_for_scale (
  StIconTheme       $icon_theme,
  Str               $icon_name,
  gint              $size,
  gint              $scale,
  StIconLookupFlags $flags
)
  returns StIconInfo
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_theme_new
  returns StIconTheme
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_theme_prepend_search_path (
  StIconTheme $icon_theme,
  Str         $path
)
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_theme_rescan_if_needed (StIconTheme $icon_theme)
  returns uint32
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_theme_set_search_path (
  StIconTheme  $icon_theme,
  CArray[Str]  $path,
  gint         $n_elements
)
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_info_get_base_scale (StIconInfo $icon_info)
  returns gint
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_info_get_base_size (StIconInfo $icon_info)
  returns gint
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_info_get_filename (StIconInfo $icon_info)
  returns Str
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_info_is_symbolic (StIconInfo $icon_info)
  returns uint32
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_info_load_icon (
  StIconInfo              $icon_info,
  CArray[Pointer[GError]] $error
)
  returns GdkPixbuf
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_info_load_icon_async (
  StIconInfo          $icon_info,
  GCancellable        $cancellable,
  GAsyncReadyCallback $callback,
  gpointer            $user_data
)
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_info_load_icon_finish (
  StIconInfo              $icon_info,
  GAsyncResult            $res,
  CArray[Pointer[GError]] $error
)
  returns GdkPixbuf
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_info_load_symbolic (
  StIconInfo              $icon_info,
  StIconColors            $colors,
  gboolean                $was_symbolic,
  CArray[Pointer[GError]] $error
)
  returns GdkPixbuf
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_info_load_symbolic_async (
  StIconInfo          $icon_info,
  StIconColors        $colors,
  GCancellable        $cancellable,
  GAsyncReadyCallback $callback,
  gpointer            $user_data
)
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_info_load_symbolic_finish (
  StIconInfo              $icon_info,
  GAsyncResult            $res,
  gboolean                $was_symbolic,
  CArray[Pointer[GError]] $error
)
  returns GdkPixbuf
  is      native(gnome-shell)
  is      export
{ * }

sub st_icon_info_new_for_pixbuf (
  StIconTheme $icon_theme,
  GdkPixbuf   $pixbuf
)
  returns StIconInfo
  is      native(gnome-shell)
  is      export
{ * }
