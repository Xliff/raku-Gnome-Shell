use v6.c;

use Method::Also;

use Gnome::Shell::Raw::Types
use Croco::Raw::Declaration;

class Croco::Declaration {
  also does GLib::Roles::Implementor;

  has CRDeclaration $!cd is implementor;

  submethod BUILD ( :croco-dec(:$!cd) )
  { * }

  method Croco::Raw::Definition::CRDeclaration
    is also<CRDeclaration>
  { $!cd }

  method new (
    CRStatement() $a_statement,
    CRString()    $a_property,
    CRTerm()      $a_value
  ) {
    my $croco-dec = cr_declaration_new($a_statement, $a_property, $a_value);

    $croco-dec ?? self.bless( :$croco-dec ) !! Nil;
  }

  method append (CRDeclaration() $a_new) {
    cr_declaration_append($!cd, $a_new);
  }

  method append2 (CRString() $a_prop, CRTerm() $a_value) {
    cr_declaration_append2($!cd, $a_prop, $a_value);
  }

  method destroy {
    cr_declaration_destroy($!cd);
  }

  multi method dump (
    gpointer  $a_fp,
             :i(:$indent)                             = 0,
             :o(:line(:one_per_line(:$one-per-line))) = False
  ) {
    samewith($a_fp, $indent, $one-per-line);
  }
  multi method dump (
    gpointer $a_fp,
    Int()    $a_indent,
    Int()    $a_one_per_line
  ) {
    my glong    $i = $a_indent;
    my gboolean $o = $a_one_per_line;

    cr_declaration_dump($!cd, $a_fp, $i, $o);
  }

  method dump_one (
    gpointer $a_fp,
    Int()    $a_indent = 0
  )
    is also<dump-one>
  {
    my glong $a = $a_indent;

    cr_declaration_dump_one($!cd, $a_fp, $a);
  }

  method get_by_prop_name (Str() $a_str) is also<get-by-prop-name> {
    cr_declaration_get_by_prop_name($!cd, $a_str);
  }

  method get_from_list (Int() $itemnr, :$raw = False) is also<get-from-list> {
    my gint $i = $itemnr;

    propReturnObject(
      cr_declaration_get_from_list($!cd, $i),
      $raw,
      |self.getTypePair
    );
  }

  method list_to_string (Int() $a_indent = 0) is also<list-to-string> {
    my gulong $a = $a_indent;

    cr_declaration_list_to_string($!cd, $a);
  }

  proto method list_to_string2 (|)
    is also<list-to-string2>
  { * }

  multi method list_to_string2 (
    :i(:$indent)                             = 0,
    :o(:line(:one_per_line(:$one-per-line))) = False
  ) {
    samewith($indent, $one-per-line);
  }
  multi method list_to_string2 (Int() $a_indent, Int() $a_one_decl_per_line) {
    my glong    $i = $a_indent,
    my gboolean $o = $a_one_per_line;

    cr_declaration_list_to_string2($!cd, $i, $o);
  }

  method nr_props is also<elems> is also<nr-props> {
    cr_declaration_nr_props($!cd);
  }

  method AT-POS (Int() $k) is also<AT_POS> {
    return Nil unless $k ~~ 0 .. $.nr_props;
    $.get_from_list($k);
  }

  method parse_from_buf (
    Str()  $a_str,
    Int()  $a_enc,
          :$raw    = False
  )
    is also<parse-from-buf>
  {
    my CREncoding $a = $a_enc;

    propReturnObject(
      cr_declaration_parse_from_buf($!cd, $a_str, $a),
      $raw,
      |self.getTypePair
    );
  }

  method parse_list_from_buf (Int() $a_enc, :$raw = False)
    is also<parse-list-from-buf>
  {
    my CREncoding $a = $a_enc;

    propReturnObject(
      cr_declaration_parse_list_from_buf($!cd, $a),
      $raw,
      |self.getTypePair
    );
  }

  method prepend (CRDeclaration() $a_new) {
    cr_declaration_prepend($!cd, $a_new);
  }

  method ref {
    cr_declaration_ref($!cd);
    self;
  }

  method to_string (Int() $a_indent = 0) is also<to-string> {
    my gulong $a = $a_indent;

    cr_declaration_to_string($!cd, $a);
  }

  method unlink {
    cr_declaration_unlink($!cd);
  }

  method unref {
    cr_declaration_unref($!cd);
  }

}
