use v6.c;

use NativeCall;

use Cairo;
use GLib::Raw::Definitions;
use GLib::Raw::Structs;
use GIO::Raw::Definitions;
use GDK::Raw::Definitions;
use Graphene::Raw::Definitions;
use Mutter::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;

unit package Gnome::Shell::Raw::Screenshot;

### /home/cbwood/Projects/gnome-shell/src/shell-screenshot.h

sub shell_screenshot_composite_to_stream (
  MutterCoglTexture $texture,
  gint              $x,
  gint              $y,
  gint              $width,
  gint              $height,
  gfloat            $scale,
  MutterCoglTexture $cursor,
  gint              $cursor_x,
  gint              $cursor_y,
  gfloat            $cursor_scale,
  GOutputStream     $stream,
                    &callback (MutterCoglTexture, GAsyncResult, gpointer),
  gpointer          $user_data
)
  is native(gnome-shell)
  is export
{ * }

sub shell_screenshot_composite_to_stream_finish (
  GAsyncResult            $result,
  CArray[Pointer[GError]] $error
)
  returns GdkPixbuf
  is native(gnome-shell)
  is export
{ * }

sub shell_screenshot_new ()
  returns ShellScreenshot
  is native(gnome-shell)
  is export
{ * }

sub shell_screenshot_pick_color (
  ShellScreenshot $screenshot,
  gint            $x,
  gint            $y,
                  &callback (ShellScreenshot, GAsyncResult, gpointer),
  gpointer        $user_data
)
  is native(gnome-shell)
  is export
{ * }

sub shell_screenshot_pick_color_finish (
  ShellScreenshot         $screenshot,
  GAsyncResult            $result,
  MutterClutterColor      $color,
  CArray[Pointer[GError]] $error
)
  returns uint32
  is native(gnome-shell)
  is export
{ * }

sub shell_screenshot_screenshot (
  ShellScreenshot $screenshot,
  gboolean        $include_cursor,
  GOutputStream   $stream,
                  &callback (ShellScreenshot, GAsyncResult, gpointer),
  gpointer        $user_data
)
  is native(gnome-shell)
  is export
{ * }

sub shell_screenshot_screenshot_area (
  ShellScreenshot $screenshot,
  gint            $x,
  gint            $y,
  gint            $width,
  gint            $height,
  GOutputStream   $stream,
                  &callback (ShellScreenshot, GAsyncResult, gpointer),
  gpointer        $user_data
)
  is native(gnome-shell)
  is export
{ * }

sub shell_screenshot_screenshot_area_finish (
  ShellScreenshot               $screenshot,
  GAsyncResult                  $result,
  CArray[cairo_rectangle_int_t] $area,
  CArray[Pointer[GError]]       $error
)
  returns uint32
  is native(gnome-shell)
  is export
{ * }

sub shell_screenshot_screenshot_finish (
  ShellScreenshot               $screenshot,
  GAsyncResult                  $result,
  CArray[cairo_rectangle_int_t] $area,
  CArray[Pointer[GError]]       $error
)
  returns uint32
  is native(gnome-shell)
  is export
{ * }

sub shell_screenshot_screenshot_stage_to_content (
  ShellScreenshot $screenshot,
                  &callback (ShellScreenshot, GAsyncResult, gpointer),
  gpointer        $user_data
)
  is native(gnome-shell)
  is export
{ * }

sub shell_screenshot_screenshot_stage_to_content_finish (
  ShellScreenshot              $screenshot,
  GAsyncResult                 $result,
  gfloat                       $scale            is rw,
  CArray[MutterClutterContent] $cursor_content,
  graphene_point_t             $cursor_point,
  gfloat                       $cursor_scale     is rw,
  CArray[Pointer[GError]]      $error
)
  returns MutterClutterContent
  is native(gnome-shell)
  is export
{ * }

sub shell_screenshot_screenshot_window (
  ShellScreenshot $screenshot,
  gboolean        $include_frame,
  gboolean        $include_cursor,
  GOutputStream   $stream,
                  &callback (ShellScreenshot, GAsyncResult, gpointer),
  gpointer        $user_data
)
  is native(gnome-shell)
  is export
{ * }

sub shell_screenshot_screenshot_window_finish (
  ShellScreenshot               $screenshot,
  GAsyncResult                  $result,
  CArray[cairo_rectangle_int_t] $area,
  CArray[Pointer[GError]]       $error
)
  returns uint32
  is native(gnome-shell)
  is export
{ * }
