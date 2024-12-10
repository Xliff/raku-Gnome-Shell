use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;
use Croco::Raw::Definitions;
use Croco::Raw::Enums;
use Croco::Raw::Structs;

unit package Croco::Raw::SimpleSel;

### /home/cbwood/Projects/gnome-shell-st/src/st/croco/cr-simple-sel.h

sub cr_simple_sel_append_simple_sel (
  CRSimpleSel $a_this,
  CRSimpleSel $a_sel
)
  returns CRSimpleSel
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_simple_sel_compute_specificity (CRSimpleSel $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_simple_sel_destroy (CRSimpleSel $a_this)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_simple_sel_dump (
  CRSimpleSel $a_this,
  gpointer    $a_fp
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_simple_sel_dump_attr_sel_list (CRSimpleSel $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_simple_sel_new
  returns CRSimpleSel
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_simple_sel_one_to_string (CRSimpleSel $a_this)
  returns Str
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_simple_sel_prepend_simple_sel (
  CRSimpleSel $a_this,
  CRSimpleSel $a_sel
)
  returns CRSimpleSel
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_simple_sel_to_string (CRSimpleSel $a_this)
  returns Str
  is      native(gnome-shell-st)
  is      export
{ * }
