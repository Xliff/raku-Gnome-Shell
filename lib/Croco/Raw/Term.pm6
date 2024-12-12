use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;
use Croco::Raw::Definitions;
use Croco::Raw::Enums;
use Croco::Raw::Structs;

unit package Croco::Raw::Term;

### /home/cbwood/Projects/gnome-shell/src/st/croco/cr-term.h

sub cr_term_append_term (CRTerm $a_this, CRTerm $a_new_term)
  returns CRTerm
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_term_destroy (CRTerm $a_term)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_term_dump (CRTerm $a_this, gpointer $a_fp)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_term_get_from_list (CRTerm $a_this, gint $itemnr)
  returns CRTerm
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_term_new
  returns CRTerm
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_term_nr_values (CRTerm $a_this)
  returns gint
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_term_one_to_string (CRTerm $a_this)
  returns Str
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_term_parse_expression_from_buf (Str $a_buf, CREncoding $a_encoding)
  returns CRTerm
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_term_prepend_term (CRTerm $a_this, CRTerm $a_new_term)
  returns CRTerm
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_term_ref (CRTerm $a_this)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_term_set_function (
  CRTerm   $a_this,
  CRString $a_func_name,
  CRTerm   $a_func_param
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_term_set_hash (CRTerm $a_this, CRString $a_str)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_term_set_ident (CRTerm $a_this, CRString $a_str)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_term_set_number (CRTerm $a_this, CRNum $a_num)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_term_set_rgb (CRTerm $a_this, CRRgb $a_rgb)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_term_set_string (CRTerm $a_this, CRString $a_str)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_term_set_uri (CRTerm $a_this, CRString $a_str)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_term_to_string (CRTerm $a_this)
  returns Str
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_term_unref (CRTerm $a_this)
  returns uint32
  is      native(gnome-shell-st)
  is      export
{ * }
