use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Croco::Raw::Definitions;
use Croco::Raw::Enums;
use Gnome::Shell::Raw::Definitions;

unit package Croco::Raw::Declaration;

### /home/cbwood/Projects/gnome-shell-st/src/st/croco/cr-declaration.h

sub cr_declaration_append (
  CRDeclaration $a_this,
  CRDeclaration $a_new
)
  returns CRDeclaration
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_declaration_append2 (
  CRDeclaration $a_this,
  CRString      $a_prop,
  CRTerm        $a_value
)
  returns CRDeclaration
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_declaration_destroy (CRDeclaration $a_this)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_declaration_dump (
  CRDeclaration $a_this,
  gpointer      $a_fp,
  glong         $a_indent,
  gboolean      $a_one_per_line
)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_declaration_dump_one (
  CRDeclaration $a_this,
  gpointer      $a_fp,
  glong         $a_indent
)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_declaration_get_by_prop_name (
  CRDeclaration $a_this,
  Str           $a_str
)
  returns CRDeclaration
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_declaration_get_from_list (
  CRDeclaration $a_this,
  gint          $itemnr
)
  returns CRDeclaration
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_declaration_list_to_string (
  CRDeclaration $a_this,
  gulong        $a_indent
)
  returns Str
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_declaration_list_to_string2 (
  CRDeclaration $a_this,
  gulong        $a_indent,
  gboolean      $a_one_decl_per_line
)
  returns Str
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_declaration_new (
  CRStatement $a_statement,
  CRString    $a_property,
  CRTerm      $a_value
)
  returns CRDeclaration
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_declaration_nr_props (CRDeclaration $a_this)
  returns gint
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_declaration_parse_from_buf (
  CRStatement $a_statement,
  Str         $a_str,
  CREncoding  $a_enc
)
  returns CRDeclaration
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_declaration_parse_list_from_buf (
  Str        $a_str,
  CREncoding $a_enc
)
  returns CRDeclaration
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_declaration_prepend (
  CRDeclaration $a_this,
  CRDeclaration $a_new
)
  returns CRDeclaration
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_declaration_ref (CRDeclaration $a_this)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_declaration_to_string (
  CRDeclaration $a_this,
  gulong        $a_indent
)
  returns Str
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_declaration_unlink (CRDeclaration $a_decl)
  returns CRDeclaration
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_declaration_unref (CRDeclaration $a_this)
  returns uint32
  is      native(gnome-shell-st)
  is      export
{ * }
