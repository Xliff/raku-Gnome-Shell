use v6.c;

use Method::Also;

use Gnome::Shell::Raw::Types;
use Croco::Raw::AdditionalSel;

use GLib::Roles::Implementor;

class Croco::AdditionalSel {
  also does GLib::Roles::Implementor;

  has CRAdditionalSel $!cas is implementor;

  submethod BUILD ( :croco-add-sel( :$!cas ) )
  { }

  method Croco::Raw::Structs::CRAdditionalSel
    is also<CRAdditionalSel>
  { $!cas }

  multi method new (CRAdditionalSel $croco-add-sel) {
    $croco-add-sel ?? self.bless( :$croco-add-sel ) !! Nil;
  }
  multi method new {
    my $croco-add-sel = cr_additional_sel_new();

    $croco-add-sel ?? self.bless( :$croco-add-sel ) !! Nil;
  }

  method new_with_type (Int() $a_sel_type) is also<new-with-type> {
    my CRAddSelectorType $s = $a_sel_type;

    my $croco-add-sel = cr_additional_sel_new_with_type($!cas, $s);

    $croco-add-sel ?? self.bless( :$croco-add-sel ) !! Nil;
  }

  method append (CRAdditionalSel() $a_sel, :$raw = False) {
    propReturnObject(
      cr_additional_sel_append($!cas, $a_sel),
      $raw,
      |self.getTypePair
    );
  }

  method destroy {
    cr_additional_sel_destroy($!cas);
  }

  method dump (gpointer $a_fp) {
    cr_additional_sel_dump($!cas, $a_fp);
  }

  method one_to_string is also<one-to-string> {
    cr_additional_sel_one_to_string($!cas);
  }

  method prepend (CRAdditionalSel() $a_sel, :$raw = False) {
    propReturnObject(
      cr_additional_sel_prepend($!cas, $a_sel),
      $raw,
      |self.getTypePair
    );
  }

  method set_attr_sel (CRAttrSel() $a_sel) is also<set-attr-sel> {
    cr_additional_sel_set_attr_sel($!cas, $a_sel);
  }

  method set_class_name (CRString() $a_class_name) is also<set-class-name> {
    cr_additional_sel_set_class_name($!cas, $a_class_name);
  }

  method set_id_name (CRString() $a_id) is also<set-id-name> {
    cr_additional_sel_set_id_name($!cas, $a_id);
  }

  method set_pseudo (CRPseudo() $a_pseudo) is also<set-pseudo> {
    cr_additional_sel_set_pseudo($!cas, $a_pseudo);
  }

  method to_string is also<to-string> {
    cr_additional_sel_to_string($!cas);
  }

}
