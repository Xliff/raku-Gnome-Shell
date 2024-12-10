use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;
use Croco::Raw::Definitions;
use Croco::Raw::Structs;

unit package Croco::Raw::StyleSheet;

### /home/cbwood/Projects/gnome-shell-st/src/st/croco/cr-stylesheet.h

sub cr_stylesheet_destroy (CRStyleSheet $a_this)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_stylesheet_dump (
  CRStyleSheet $a_this,
  gpointer     $a_fp
)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_stylesheet_new (CRStatement $a_stmts)
  returns CRStyleSheet
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_stylesheet_nr_rules (CRStyleSheet $a_this)
  returns gint
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_stylesheet_ref (CRStyleSheet $a_this)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_stylesheet_statement_get_from_list (
  CRStyleSheet $a_this,
  gint         $itemnr
)
  returns CRStatement
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_stylesheet_to_string (CRStyleSheet $a_this)
  returns Str
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_stylesheet_unref (CRStyleSheet $a_this)
  returns uint32
  is      native(gnome-shell-st)
  is      export
{ * }
