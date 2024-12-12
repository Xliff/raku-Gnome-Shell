use v6.c;

use Method::Also;

use Gnome::Shell::Raw::Types;
use Croco::Raw::Term;

use GLib::Roles::Implementor;

class Croco::Term {
  also does GLib::Roles::Implementor;
  also does Positional;

  has CRTerm $!ct is implementor;

  submethod BUILD ( :croco-term( :$!ct ) )
  { * }

  method Croco::Raw::Structs::CRTerm
    is also<CRTerm>
  { $!ct }

  multi method new (CRTerm $croco-term) {
    $croco-term ?? self.bless( :$croco-term ) !! Nil;
  }
  multi method new {
    my $croco-term = cr_term_new();

    $croco-term ?? self.bless( :$croco-term ) !! Nil;
  }

  method append_term (CRTerm() $a_new_term, :$raw = False)
    is also<append-term>
  {
    propReturnObject(
      cr_term_append_term($!ct, $a_new_term),
      $raw,
      |self.getTypePair
    );
  }

  method destroy {
    cr_term_destroy($!ct);
  }

  method dump (gpointer $a_fp) {
    cr_term_dump($!ct, $a_fp);
  }

  method get_from_list (Int() $itemnr, :$raw = False)
    is also<get-from-list>
  {
    my gint $i = $itemnr;

    return Nil unless $i ~~ 0 .. $.nr_values;

    propReturnObject(
      cr_term_get_from_list($!ct, $itemnr),
      $raw,
      |self.getTypePair
    );
  }

  method AT-POS (\k) {
    $.get_from_list(k);
  }

  method nr_values
    is also<
      nr-values
      elems
    >
  {
    cr_term_nr_values($!ct);
  }

  method one_to_string is also<one-to-string> {
    cr_term_one_to_string($!ct);
  }

  method parse_expression_from_buf (
    Str()  $buf,
    Int()  $a_encoding,
          :$raw         = False
  )
    is also<parse-expression-from-buf>
  {
    my CREncoding $e = $a_encoding;

    propReturnObject(
       cr_term_parse_expression_from_buf($buf, $e),
       $raw,
      |self.getTypePair
    )
  }

  method prepend_term (CRTerm() $a_new_term) is also<prepend-term> {
    cr_term_prepend_term($!ct, $a_new_term);
  }

  method ref {
    cr_term_ref($!ct);
    self
  }

  method set_function (CRString() $a_func_name, CRTerm() $a_func_param)
    is also<set-function>
  {
    cr_term_set_function($!ct, $a_func_name, $a_func_param);
  }

  method set_hash (CRString() $a_str) is also<set-hash> {
    cr_term_set_hash($!ct, $a_str);
  }

  method set_ident (CRString() $a_str) is also<set-ident> {
    cr_term_set_ident($!ct, $a_str);
  }

  method set_number (CRNum() $a_num) is also<set-number> {
    cr_term_set_number($!ct, $a_num);
  }

  method set_rgb (CRRgb() $a_rgb) is also<set-rgb> {
    cr_term_set_rgb($!ct, $a_rgb);
  }

  method set_string (CRString() $a_str) is also<set-string> {
    cr_term_set_string($!ct, $a_str);
  }

  method set_uri (CRString() $a_str) is also<set-uri> {
    cr_term_set_uri($!ct, $a_str);
  }

  method to_string
    is also<
      to-string
      Str
    >
  {
    cr_term_to_string($!ct);
  }

  method unref {
    cr_term_unref($!ct);
  }

}
