use v6.c;

use Method::Also;

use Gnome::Shell::Raw::Types;
use Croco::Raw::SimpleSel;

use GLib::Roles::Implementor;

class Croco::SimpleSel {
  also does GLib::Roles::Implementor;

  has CRSimpleSel $!css is implementor handles<location>;

  submethod BUILD ( :croco-simple-sel( :$!css ) )
  {  }

  method Croco::Raw::Structs::CRSimpleSel
    is also<CRSimpleSel>
  { $!css }

  multi method new (CRSimpleSel $croco-simple-sel) {
    $croco-simple-sel ?? self.bless( :$croco-simple-sel ) !! Nil;
  }
  multi method new {
    my $croco-simple-sel = cr_simple_sel_new();

    $croco-simple-sel ?? self.bless( :$croco-simple-sel ) !! Nil;
  }

  method append_simple_sel (CRSimpleSel() $a_sel, :$raw = False)
    is also<append-simple-sel>
  {
    propReturnObject(
      cr_simple_sel_append_simple_sel($!css, $a_sel),
      $raw,
      |self.getTypePair
    );
  }

  method combinator ( :$enum = True ) {
    my $c = $!css.combinator;
    return $c unless $enum;
    CRCombinatorEnum($c);
  }

  method compute_specificity is also<compute-specificity> {
    my $crs = cr_simple_sel_compute_specificity($!css);

    setCrocoStatus($crs);
  }

  method destroy {
    cr_simple_sel_destroy($!css);
  }

  method dump (gpointer $a_fp) {
    my $crs = cr_simple_sel_dump($!css, $a_fp);

    setCrocoStatus($crs);
  }

  method dump_attr_sel_list is also<dump-attr-sel-list> {
    my $crs = cr_simple_sel_dump_attr_sel_list($!css);

    setCrocoStatus($crs);
  }

  method name ( :$raw = False ) {
    propReturnObject($!css.name, $raw, |Croco::String.getTypePair);
  }

  method next ( :$raw = False ) {
    propReturnObject($!css.next, $raw, |self.getTypePair);
  }

  method one_to_string is also<one-to-string> {
    cr_simple_sel_one_to_string($!css);
  }

  method prepend_simple_sel (CRSimpleSel() $a_sel, :$raw = False)
    is also<prepend-simple-sel>
  {
    propReturnObject(
      cr_simple_sel_prepend_simple_sel($!css, $a_sel),
      $raw,
      |self.getTypePair
    );
  }

  method prev ( :$raw = False ) {
    propReturnObject($!css.prev, $raw, |self.getTypePair);
  }

  method specificity {
    $.compute_specificity;
    $!css.specificity;
  }

  method to_string
    is also<
      to-string
      Str
    >
  {
    cr_simple_sel_to_string($!css);
  }

}
