use v6.c;

use NativeCall;

use Cairo;
use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::Screenshot;

use Graphene::Point;

use GLib::Roles::Implementor;

class Gnome::Shell::Screenshot {
  has ShellScreenshot $!mss is implementor;

  method new {
    my $shell-screenshot = shell_screenshot_new();

    $shell-screenshot ?? self.bless( :$shell-screenshot ) !!! Nil
  }

  method composite_to_stream (
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
                      &callback (ShellScreenshot, GAsyncResult, gpointer),
    gpointer          $user_data
  ) {
    shell_screenshot_composite_to_stream(
      $!gss,
      $x,
      $y,
      $width,
      $height,
      $scale,
      $cursor,
      $cursor_x,
      $cursor_y,
      $cursor_scale,
      $stream,
      &callback,
      $user_data
    );
  }

  method composite_to_stream_finish (
    CArray[Pointer[GError]] $error = gerror
  ) {
    clear_error;
    shell_screenshot_composite_to_stream_finish($!gss, $error);
    set_error($error);
  }

  method pick_color (
    gint     $x,
    gint     $y,
             &callback,
    gpointer $user_data = gpointer
  ) {
    shell_screenshot_pick_color($!gss, $x, $y, $callback, $user_data);
  }

  method pick_color_finish (
    GAsyncResult()          $result,
    MutterClutterColor()    $color,
    CArray[Pointer[GError]] $error   = gerror
  ) {
    clear_error;
    my $c = shell_screenshot_pick_color_finish(
      $!gss,
      $result,
      $color,
      $error
    );
    set_error($error);
  }

  method screenshot (
    gboolean      $include_cursor,
    GOutputStream $stream,
                  &callback (ShellScreenshot, GAsyncResult, gpointer),
    gpointer      $user_data = gpointer
  ) {
    shell_screenshot_screenshot(
      $!gss,
      $include_cursor,
      $stream,
      &callback,
      $user_data
    );
  }

  proto method screenshot_area (|)
  { * }

  # cw: Here's an example of another way to handle callback routines and
  #     give the user more control over the process.
  #       - 2022/09/13
  multi method screenshot_area (
    gint          $x,
    gint          $y,
    gint          $width,
    gint          $height,
    GOutputStream $stream,
    gpointer      $user_data                        = gpointer,
                  :as-supply(:$supply) is required
  ) {
    my $s = Supplier::Preserving.new;

    my $callback = -> *@a {
      $s.emit( [ self, @a.skip(1) ]);
    }

    samewith($x, $y, $width, $height, $stream, $callback, $user_data);
    $s.Supply
  }
  multi method screenshot_area (
    gint          $x,
    gint          $y,
    gint          $width,
    gint          $height,
    GOutputStream $stream,
                  &callback (ShellScreenshot, GAsyncResult, gpointer),
    gpointer      $user_data = gpointer,
  ) {
    shell_screenshot_screenshot_area(
      $!gss,
      $x,
      $y,
      $width,
      $height,
      $stream,
      $callback,
      $user_data
    );
  }

  method screenshot_area_finish (
    GAsyncResult()                $result,
    CArray[cairo_rectangle_int_t] $area,
    CArray[Pointer[GError]]       $error    = gerror
  ) {
    clear_error;
    shell_screenshot_screenshot_area_finish($!gss, $result, $area, $error);
    set_error($error);

    my $a = ppr($area);
    return $a if $raw;
    # cw: -XXX- Fix object!
    $a;
  }

  method screenshot_finish (
    GAsyncResult                  $result,
    CArray[cairo_rectangle_int_t] $area,
    CArray[Pointer[GError]]       $error
  ) {
    shell_screenshot_screenshot_finish($!gss, $result, $area, $error);
  }

  method screenshot_stage_to_content (
             &callback (ShellScreenshot, GAsyncResult, gpointer),
    gpointer $user_data
  ) {
    shell_screenshot_screenshot_stage_to_content($!gss, $callback, $user_data);
  }

  proto method screenshot_stage_to_content_finish (|)
  { * }

  method screenshot_stage_to_content_finish (
    GAsyncResult()                $result,
    CArray[Pointer[GError]]       $error   = gerror
  ) {
    samewith(
      $result,
      $
      newCArray(MutterClutterContent),
      Graphene::Point.alloc,
      $,
      $error
    );
  }
  method screenshot_stage_to_content_finish (
    GAsyncResult()               $result,
    Num()                        $scale           is rw,
    CArray[MutterClutterContent] $cursor_content,
    graphene_point_t()           $cursor_point,
    Num()                        $cursor_scale    is rw,
    CArray[Pointer[GError]]      $error                  = gerror
  ) {
    my gfloat ($s, $c) = 0e0 xx 2;

    shell_screenshot_screenshot_stage_to_content_finish(
      $!gss,
      $result,
      $s,
      $cursor_content,
      $cursor_point,
      $c,
      $error
    );
    ($scale, $cursor_scale) = ($s, $c);
  }

  proto method screenshot_window (|)
  { * }

  multi method screenshot_window (
    GOutputStream  $stream,
                   &callback,
    gpointer       $user_data      = gpointer,
                  :$include_frame  = False,
                  :$include_cursor = False
  ) {
    samewith($include_frame, $include_cursor, $stream, &callback, $user_data);
  }
  multi method screenshot_window (
    Int()           $include_frame,
    Int()           $include_cursor,
    GOutputStream() $stream,
                    &callback,
    gpointer        $user_data       = gpointer
  ) {
    my gboolean $if = $include_frame.so.Int;
    my gboolean $ic = $include_cursor.so.Int;

    shell_screenshot_screenshot_window(
      $!gss,
      $if,
      $ic,
      $stream,
      &callback,
      $user_data
    );
  }

  method screenshot_window_finish (
    GAsyncResult()                 $result,
    CArray[cairo_rectangle_int_t]  $area,
    CArray[Pointer[GError]]        $error   = gerror,
                                  :$raw     = False
  ) {
    clear_error;
    my $r = shell_screenshot_screenshot_window_finish(
      $!gss,
      $result,
      $area,
      $error
    );
    set_error($error);
    propReturnObject($r, $raw, cairo_rectangle_int_t, Cairo::Rectangle);
  }

}
