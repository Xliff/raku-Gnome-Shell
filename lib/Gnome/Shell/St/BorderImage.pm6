use v6.c;

use NativeCall;

use Gnome::Shell::Raw::Types;

use GLib::Roles::Object;
use GIO::Roles::GFile;

use GLib::Roles::Implementor;

class Gnome::Shell::St::BorderImage {
  also does GLib::Roles::Object;

  has StBorderImage $!stbi is implementor;

  method new (
    GFile() $file,
    Int()   $border_top,
    Int()   $border_right,
    Int()   $border_bottom,
    Int()   $border_left,
    Int()   $scale_factor
  ) {
    my gint ($bt, $br, $bb, $bl, $sf) = (
      $border_top,
      $border_right,
      $border_bottom,
      $border_left,
      $scale_factor
    );

    my $st-border-image = st_border_image_new($file, $bt, $br, $bb, $bl, $sf);

    $st-border-image ?? self.bless( :$st-border-image ) !! Nil;
  }

  method equal (StBorderImage() $other) {
    st_border_image_equal($!stbi, $other);
  }

  proto method get_borders (|)
  { * }

  multi method get_borders {
    samewith($, $, $, $);
  }
  multi method get_borders (
    $border_top    is rw,
    $border_right  is rw,
    $border_bottom is rw,
    $border_left   is rw
  ) {
    my gint ($bt, $br, $bb, $bl) =  0 xx 4;

    st_border_image_get_borders($!stbi, $bt, $br, $bb, $bl);

    ($border_top, $border_right, $border_bottom, $border_left) =
      ($bt, $br, $bb, $bl);
  }

  method get_file ( :$raw = False ) {
    propReturnObject(
      st_border_image_get_file($!stbi),
      $raw,
      |GIO::GFile.getTypePair
    );
  }
}

### /home/cbwood/Projects/gnome-shell/src/st/st-border-image.h

sub st_border_image_equal (StBorderImage $image, StBorderImage $other)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_border_image_get_borders (
  StBorderImage $image,
  gint          $border_top    is rw,
  gint          $border_right  is rw,
  gint          $border_bottom is rw,
  gint          $border_left   is rw
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_border_image_get_file (StBorderImage $image)
  returns GFile
  is native(gnome-shell-st)
  is export
{ * }

sub st_border_image_new (
  GFile $file,
  gint  $border_top,
  gint  $border_right,
  gint  $border_bottom,
  gint  $border_left,
  gint  $scale_factor
)
  returns StBorderImage
  is native(gnome-shell-st)
  is export
{ * }
