use v6.c;

use Method::Also;
use Gnome::Shell::Raw::Types;
use Croco::Raw::StyleSheet;

use GLib::Roles::Implementor;

class Croco::StyleSheet {
  also does GLib::Roles::Implementor;
  also does Positional;

  has CRStyleSheet $!cs is implementor;

  submethod BUILD ( :croco-stylesheet( :$!cs ) )
  { }

  method Croco::Raw::Structs::CRStyleSheet
    is also<CRStyleSheet>
  { $!cs }

  proto method new (|)
  { * }

  multi method new (CRStyleSheet $croco-stylesheet) {
    $croco-stylesheet ?? self.bless( :$croco-stylesheet ) !! Nil;
  }
  multi method new (CRStatement() $s) {
    my $croco-stylesheet = cr_stylesheet_new($s);

    $croco-stylesheet ?? self.bless( :$croco-stylesheet ) !! Nil;
  }

  method destroy {
    cr_stylesheet_destroy($!cs);
  }

  method dump (gpointer $a_fp) {
    cr_stylesheet_dump($!cs, $a_fp);
  }

  method AT-POS (\k) {
    $.statement_get_from_list(k);
  }

  method nr_rules
    is also<
      nr-rules
      elems
    >
  {
    cr_stylesheet_nr_rules($!cs);
  }

  method ref {
    cr_stylesheet_ref($!cs);
    self;
  }

  method statement_get_from_list (Int() $itemnr, :$raw = False)
    is also<
      statement-get-from-list
      get_from_list
      get-from-list
    >
  {
    my gint $i = $itemnr;

    return Nil unless $i ~~ 0 .. $.nr_rules;

    propReturnObject(
      cr_stylesheet_statement_get_from_list($!cs, $i),
      $raw,
      |Croco::Statement.getTypePair
    );
  }

  method to_string
    is also<
      to-string
      Str
    >
  {
    cr_stylesheet_to_string($!cs);
  }

  method unref {
    cr_stylesheet_unref($!cs);
  }

}
