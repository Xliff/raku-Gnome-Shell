use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;
use Croco::Raw::Definitions;
use Croco::Raw::Enums;
use Croco::Raw::Structs;

unit package Croco::Raw::AdditionalSel;

### /home/cbwood/Projects/gnome-shell-st/src/st/croco/cr-additional-sel.h

sub cr_additional_sel_append (
  CRAdditionalSel $a_this,
  CRAdditionalSel $a_sel
)
  returns CRAdditionalSel
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_additional_sel_destroy (CRAdditionalSel $a_this)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_additional_sel_dump (
  CRAdditionalSel $a_this,
  gpointer        $a_fp
)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_additional_sel_new
  returns CRAdditionalSel
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_additional_sel_new_with_type (CRAddSelectorType $a_sel_type)
  returns CRAdditionalSel
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_additional_sel_one_to_string (CRAdditionalSel $a_this)
  returns Str
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_additional_sel_prepend (
  CRAdditionalSel $a_this,
  CRAdditionalSel $a_sel
)
  returns CRAdditionalSel
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_additional_sel_set_attr_sel (
  CRAdditionalSel $a_this,
  CRAttrSel       $a_sel
)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_additional_sel_set_class_name (
  CRAdditionalSel $a_this,
  CRString        $a_class_name
)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_additional_sel_set_id_name (
  CRAdditionalSel $a_this,
  CRString        $a_id
)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_additional_sel_set_pseudo (
  CRAdditionalSel $a_this,
  CRPseudo        $a_pseudo
)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_additional_sel_to_string (CRAdditionalSel $a_this)
  returns Str
  is      native(gnome-shell-st)
  is      export
{ * }
