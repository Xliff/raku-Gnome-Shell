use v6.c;

use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::Utils;

use GLib::Roles::StaticClass;

class Gnome::Shell::Utils {
  also does GLib::Roles::StaticClass;

  method shell_get_file_contents_utf8_sync (
    Str()                   $path,
    CArray[Pointer[GError]] $error = gerror
  ) {
    clear_error;
    my $mrv = shell_get_file_contents_utf8_sync($path, $error);
    set_error($error);
    $mrv;
  }

  method check_cloexec_fds {
    shell_util_check_cloexec_fds();
  }

  method composite_capture_images (
    MutterClutterCapture()  $captures,
    Int()                   $n_captures,
    Int()                   $x,
    Int()                   $y,
    Int()                   $target_width,
    Int()                   $target_height,
    Num()                   $target_scale,
                           :$raw            = False
  ) {
    my gint ($n, $xx, $yy, $tw, $th) =
      ($n_captures, $x, $y, $target_width, $target_height);
      
    my gfloat $ts = $target_scale;

    propReturObject(
      shell_util_composite_capture_images(
        $captures,
        $n,
        $xx,
        $yy,
        $tw,
        $th,
        $ts
      ),
      $raw,
      cairo_surface_t,
      Cairo::Surface
    );
  }

  proto method create_pixbuf_from_data (|)
  { * }

  multi method create_pixbuf_from_data (
    Str()  $data,
    Int()  $colorspace,
    Int()  $has_alpha,
    Int()  $bits_per_sample,
    Int()  $width,
    Int()  $height,
    Int()  $rowstride,
    Int() :$len                        = $data.chars,
    Str() :$encoding                   = 'utf8'
  ) {
    samewith(
      $data.encode($encoding),
      $len,
      $colorspace,
      $has_alpha,
      $bits_per_sample,
      $width,
      $height,
      $rowstride
    );
  }
  multi method create_pixbuf_from_data (
    Buf()  $data,
    Int()  $colorspace,
    Int()  $has_alpha,
    Int()  $bits_per_sample,
    Int()  $width,
    Int()  $height,
    Int()  $rowstride,
    Int() :$len                        = $data.bytes
  ) {
    samewith(
      CArray[uint8].new($data),
      $len,
      $colorspace,
      $has_alpha,
      $bits_per_sample,
      $width,
      $height,
      $rowstride
    );
  }
  multi method create_pixbuf_from_data (
    CArray[uint8]  $data,
    Int()          $colorspace,
    Int()          $has_alpha,
    Int()          $bits_per_sample,
    Int()          $width,
    Int()          $height,
    Int()          $rowstride,
    Int()         :$len                = $data.elems
  ) {
    samewith(
      cast(Pointer, $data),
      $len,
      $colorspace,
      $has_alpha,
      $bits_per_sample,
      $width,
      $height,
      $rowstride
    );
  }
  multi method create_pixbuf_from_data (
    gpointer         $data,
    Int()            $len,
    GdkColorspace()  $colorspace,
    Int()            $has_alpha,
    Int()            $bits_per_sample,
    Int()            $width,
    Int()            $height,
    Int()            $rowstride,
                    :$raw = False
  ) {
    my gsize     $l = $len;
    my gboolean  $h = $has_alpha.so.Int;

    my gint ($b, $w, $h, $r) = ($bits_per_sample, $width, $height, $rowstride);

    propReturnObject(
      shell_util_create_pixbuf_from_data(
        $data,
        $l,
        $colorspace,
        $h,
        $b,
        $w,
        $h,
        $r
      ),
      $raw,
      |GDK::Pixbuf.getTypePair
    );
  }

  method get_translated_folder_name (Str() $name) {
    shell_util_get_translated_folder_name($name);
  }

  method get_uid {
    shell_util_get_uid();
  }

  method get_week_start {
    shell_util_get_week_start();
  }

  method has_x11_display_extension (
    MutterMetaDisplay() $display,
    Str()               $extension
  ) {
    so shell_util_has_x11_display_extension($display, $extension);
  }

  method regex_escape (Str() $str) {
    shell_util_regex_escape($str);
  }

  method sd_notify {
    shell_util_sd_notify();
  }

  method set_hidden_from_pick (MutterClutterActor() $actor, Int() $hidden) {
    my gboolean $h = $hidden.so.Int;

    shell_util_set_hidden_from_pick($actor, $hidden);
  }

  proto method start_systemd_unit (|)
  { * }
  multi method start_systemd_unit (
    Str()           $unit,
    Str()           $mode,
                    &callback,
    gpointer        $user_data    = gpointer
    GCancellable() :$cancellable,
  ) {
    samewith($unit, $mode, $cancellable, &callback, $user_data);
  }
  multi method start_systemd_unit (
    Str()          $unit,
    Str()          $mode,
    GCancellable() $cancellable,
                   &callback,
    gpointer       $user_data    = gpointer
  ) {
    shell_util_start_systemd_unit(
      $unit,
      $mode,
      $cancellable,
      &callback,
      $user_data
    );
  }

  method start_systemd_unit_finish (
    GAsyncResult()          $res,
    CArray[Pointer[GError]] $error = gerror
  ) {
    clear_error;
    my $mrv = shell_util_start_systemd_unit_finish($res, $error);
    set_error($error);
    $mrv;
  }

  proto method stop_systemd_unit (|)
  { * }

  multi method stop_systemd_unit (
    Str()           $unit,
    Str()           $mode,
                    &callback,
    gpointer        $user_data   = gpointer,
    GCancellable() :$cancellable = GCancellable
  ) {
    samewith($unit, $mode, $cancellable, &callback, $user_data);
  }
  multi method stop_systemd_unit (
    Str()          $unit,
    Str()          $mode,
    GCancellable() $cancellable,
                   &callback,
    gpointer       $user_data     = gpointer
  ) {
    shell_util_stop_systemd_unit(
      $unit,
      $mode,
      $cancellable,
      $callback,
      $user_data
    );
  }

  method stop_systemd_unit_finish (
    GAsyncResult()          $res,
    CArray[Pointer[GError]] $error = gerror
  ) {
    clear_error;
    my $mrv = shell_util_stop_systemd_unit_finish($res, $error);
    set_error($error);
    $mrv;
  }

  proto method systemd_unit_exists (|)
  { * }

  multi method systemd_unit_exists (
    Str             $unit,
                    &callback,
    gpointer        $user_data   = gpointer,
    GCancellable() :$cancellable = GCancellable
  ) {
    samewith($unit, $cancellable, &callback, $user_data);
  }
  multi method systemd_unit_exists (
    Str()          $unit,
    GCancellable() $cancellable,
                   &callback,
    gpointer       $user_data    = gpointer
  ) {
    shell_util_systemd_unit_exists($unit, $cancellable, $callback, $user_data);
  }

  method systemd_unit_exists_finish (
    GAsyncResult()          $res,
    CArray[Pointer[GError]] $error = gerror
  ) {
    clear_error;
    my $mrv = shell_util_systemd_unit_exists_finish($res, $error);
    set_error($error);
    $mrv;
  }

  method touch_file_async (
    GFile()  $file,
             &callback,
    gpointer $user_data = gpointer
  ) {
    shell_util_touch_file_async($file, $callback, $user_data);
  }

  method touch_file_finish (
    GFile()                 $file,
    GAsyncResult()          $res,
    CArray[Pointer[GError]] $error = gerror
  ) {
    clear_error;
    my $mrv = shell_util_touch_file_finish($file, $res, $error);
    set_error($error);
    $mrv;
  }

  method translate_time_string (Str() $str) {
    shell_util_translate_time_string($str);
  }

  proto method wifexited (|)
  { * }

  method wifexited (Int() $status, $exit is rw) {
    samewith($status, $);
  }
  method wifexited (Int() $status, $exit is rw) {
    my gint ($s, $e) = ($status, 0);

    shell_util_wifexited($status, $e);
    $e;
  }

  method write_string_to_stream (
    GOutputStream()         $stream,
    Str()                   $str,
    CArray[Pointer[GError]] $error   = gerror
  ) {
    clear_error;
    my $mrv = shell_write_string_to_stream($stream, $str, $error);
    set_error($error);
    $mrv;
  }

}
