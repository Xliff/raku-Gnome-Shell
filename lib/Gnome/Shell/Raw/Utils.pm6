use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use GIO::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;

unit package Gnome::Shell::Raw::Util;

### /home/cbwood/Projects/gnome-shell/src/shell-util.h

sub shell_get_file_contents_utf8_sync (
  Str                     $path,
  CArray[Pointer[GError]] $error
)
  returns Str
  is native(gnome-shell)
  is export
{ * }

sub shell_util_check_cloexec_fds ()
  is native(gnome-shell)
  is export
{ * }

sub shell_util_composite_capture_images (
  MutterClutterCapture $captures,
  gint                 $n_captures,
  gint                 $x,
  gint                 $y,
  gint                 $target_width,
  gint                 $target_height,
  gfloat               $target_scale
)
  returns cairo_surface_t
  is native(gnome-shell)
  is export
{ * }

sub shell_util_create_pixbuf_from_data (
  Pointer       $data,
  gsize         $len,
  GdkColorspace $colorspace,
  gboolean      $has_alpha,
  gint          $bits_per_sample,
  gint          $width,
  gint          $height,
  gint          $rowstride
)
  returns GdkPixbuf
  is native(gnome-shell)
  is export
{ * }

sub shell_util_get_translated_folder_name (Str $name)
  returns Str
  is native(gnome-shell)
  is export
{ * }

sub shell_util_get_uid ()
  returns gint
  is native(gnome-shell)
  is export
{ * }

sub shell_util_get_week_start ()
  returns gint
  is native(gnome-shell)
  is export
{ * }

sub shell_util_has_x11_display_extension (
  MutterMetaDisplay $display,
  Str               $extension
)
  returns uint32
  is native(gnome-shell)
  is export
{ * }

sub shell_util_regex_escape (Str $str)
  returns Str
  is native(gnome-shell)
  is export
{ * }

sub shell_util_sd_notify ()
  is native(gnome-shell)
  is export
{ * }

sub shell_util_set_hidden_from_pick (
  MutterClutterActor $actor,
  gboolean           $hidden
)
  is native(gnome-shell)
  is export
{ * }

sub shell_util_start_systemd_unit (
  Str          $unit,
  Str          $mode,
  GCancellable $cancellable,
               &callback (GObject, GAsyncResult, gpointer),
  gpointer     $user_data
)
  is native(gnome-shell)
  is export
{ * }

sub shell_util_start_systemd_unit_finish (
  GAsyncResult            $res,
  CArray[Pointer[GError]] $error
)
  returns uint32
  is native(gnome-shell)
  is export
{ * }

sub shell_util_stop_systemd_unit (
  Str          $unit,
  Str          $mode,
  GCancellable $cancellable,
               &callback (GObject, GAsyncResult, gpointer),
  gpointer     $user_data
)
  is native(gnome-shell)
  is export
{ * }

sub shell_util_stop_systemd_unit_finish (
  GAsyncResult            $res,
  CArray[Pointer[GError]] $error
)
  returns uint32
  is native(gnome-shell)
  is export
{ * }

sub shell_util_systemd_unit_exists (
  Str          $unit,
  GCancellable $cancellable,
               &callback (GObject, GAsyncResult, gpointer),
  gpointer     $user_data
)
  is native(gnome-shell)
  is export
{ * }

sub shell_util_systemd_unit_exists_finish (
  GAsyncResult            $res,
  CArray[Pointer[GError]] $error
)
  returns uint32
  is native(gnome-shell)
  is export
{ * }

sub shell_util_touch_file_async (
  GFile    $file,
           &callback (GObject, GAsyncResult, gpointer),
  gpointer $user_data
)
  is native(gnome-shell)
  is export
{ * }

sub shell_util_touch_file_finish (
  GFile                   $file,
  GAsyncResult            $res,
  CArray[Pointer[GError]] $error
)
  returns uint32
  is native(gnome-shell)
  is export
{ * }

sub shell_util_translate_time_string (Str $str)
  returns Str
  is native(gnome-shell)
  is export
{ * }

sub shell_util_wifexited (gint $status, gint $exit is rw)
  returns uint32
  is native(gnome-shell)
  is export
{ * }

sub shell_write_string_to_stream (
  GOutputStream           $stream,
  Str                     $str,
  CArray[Pointer[GError]] $error
)
  returns uint32
  is native(gnome-shell)
  is export
{ * }
