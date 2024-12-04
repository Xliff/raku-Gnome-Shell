use v6.c;

use Method::Also;

use Gnome::Shell::Raw::Types;
use Croco::Raw::RGB;

class Croco::RGB {
  also does GLib::Roles::Implementor;

  has CRRgb $!cr is implementor;

  submethod BUILD ( :croco-rgb( :$!cr) )
  { }

  method Croco::Raw::Definition::CRRgb
    is also<CRRgb>
  { $!cr }

  multi method new (CrocoRgb :$croco-rgb!) {
    $croco-rgb ?? self.bless( :$croco-rgb ) !! Nil;
  )
  multi method new (CrocoRgb $croco-rgb) {
    $croco-rgb ?? self.bless( :$croco-rgb ) !! Nil;
  }
  multi method new {
    my $croco-rgb = cr_rgb_new();

    $croco-rgb ?? self.bless( :$croco-rgb ) !! Nil;
  }

  method new_with_vals (
    Int() $a_red,
    Int() $a_green,
    Int() $a_blue,
    Int() $a_is_percentage
  )
    is also<new-with-vals>
  {
    my gulong   ($r, $g, $b) = ($a_red, $a_green, $a_blue);
    my gboolean  $i          =  $a_is_percentage.so.Int;

    cr_rgb_new_with_vals($!cr, $r, $g, $b, $i);
  }

  method compute_from_percentage is also<compute-from-percentage> {
    cr_rgb_compute_from_percentage($!cr);
  }

  method copy (CRRgb() $a_src, :$raw = False) {
    propReturnObject(
      cr_rgb_copy($!cr, $a_src),
      $raw,
      |self.getTypePair
    );
  }

  method destroy {
    cr_rgb_destroy($!cr);
  }

  method dump (gpointer $a_fp) {
    cr_rgb_dump($!cr, $a_fp);
  }

  method parse_from_buf (Str() $buf, Int() $a_enc, :$raw = False)
    is also<parse-from-buf>
  {
    my CREncoding $a = $a_enc;

    propReturnObject(
      cr_rgb_parse_from_buf($buf, $a),
      $raw,
      |self.getTypePair
    );
  }

  method set (
    Int() $a_red,
    Int() $a_green,
    Int() $a_blue,
    Int() $a_is_percentage
  ) {
    my gulong   ($r, $g, $b) = ($a_red, $a_green, $a_blue);
    my gboolean  $i          =  $a_is_percentage.so.Int;

    cr_rgb_set($!cr, $r, $g, $b, $i);
  }

  method set_from_hex_str (Str() $a_hex_value) is also<set-from-hex-str> {
    cr_rgb_set_from_hex_str($!cr, $a_hex_value);
  }

  method set_from_name (Str() $a_color_name) is also<set-from-name> {
    cr_rgb_set_from_name($!cr, $a_color_name);
  }

  method set_from_rgb (CRRgb() $a_rgb) is also<set-from-rgb> {
    cr_rgb_set_from_rgb($!cr, $a_rgb);
  }

  method set_from_term (CRTerm() $a_value) is also<set-from-term> {
    cr_rgb_set_from_term($!cr, $a_value);
  }

  method to_string is also<Str> is also<to-string> {
    cr_rgb_to_string($!cr);
  }

}
