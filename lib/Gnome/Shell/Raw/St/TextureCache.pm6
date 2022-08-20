use v6.c;

use NativeCall;

use Cairo;

use GLib::Raw::Definitions;
use GLib::Raw::Object;
use GLib::Raw::Structs;
use GIO::Raw::Definitions;
use Mutter::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;
use Gnome::Shell::Raw::Enums;
use Gnome::Shell::Raw::Structs;

unit package Gnome::Shell::Raw::TextureCache;

### /home/cbwood/Projects/gnome-shell/src/st/st-texture-cache.h

sub st_texture_cache_bind_cairo_surface_property (
  StTextureCache $cache,
  GObject        $object,
  Str            $property_name
)
  returns GIcon
  is native(gnome-shell-st)
  is export
{ * }

sub st_texture_cache_get_default ()
  returns StTextureCache
  is native(gnome-shell-st)
  is export
{ * }

sub st_texture_cache_load (
  StTextureCache          $cache,
  Str                     $key,
  StTextureCachePolicy    $policy,
                          &load (
                            StTextureCache,
                            Str,
                            gpointer,
                            CArray[Pointer[GError]]
                          ),
  Pointer                 $data,
  CArray[Pointer[GError]] $error
)
  returns MutterCoglTexture
  is native(gnome-shell-st)
  is export
{ * }

sub st_texture_cache_load_cairo_surface_to_gicon (
  StTextureCache  $cache,
  cairo_surface_t $surface
)
  returns GIcon
  is native(gnome-shell-st)
  is export
{ * }

sub st_texture_cache_load_file_async (
  StTextureCache $cache,
  GFile          $file,
  gint           $available_width,
  gint           $available_height,
  gint           $paint_scale,
  gfloat         $resource_scale
)
  returns MutterClutterActor
  is native(gnome-shell-st)
  is export
{ * }

sub st_texture_cache_load_file_to_cairo_surface (
  StTextureCache $cache,
  GFile          $file,
  gint           $paint_scale,
  gfloat         $resource_scale
)
  returns cairo_surface_t
  is native(gnome-shell-st)
  is export
{ * }

sub st_texture_cache_load_file_to_cogl_texture (
  StTextureCache $cache,
  GFile          $file,
  gint           $paint_scale,
  gfloat         $resource_scale
)
  returns MutterCoglTexture
  is native(gnome-shell-st)
  is export
{ * }

sub st_texture_cache_load_gicon (
  StTextureCache $cache,
  StThemeNode    $theme_node,
  GIcon          $icon,
  gint           $size,
  gint           $paint_scale,
  gfloat         $resource_scale
)
  returns MutterClutterActor
  is native(gnome-shell-st)
  is export
{ * }

sub st_texture_cache_load_sliced_image (
  StTextureCache $cache,
  GFile          $file,
  gint           $grid_width,
  gint           $grid_height,
  gint           $paint_scale,
  gfloat         $resource_scale,
                 &load_callback (GObject, gpointer),
  gpointer       $user_data
)
  returns MutterClutterActor
  is native(gnome-shell-st)
  is export
{ * }

sub st_texture_cache_rescan_icon_theme (StTextureCache $cache)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }
