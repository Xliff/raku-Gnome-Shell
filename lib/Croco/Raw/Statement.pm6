use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Croco::Raw::Definitions;
use Croco::Raw::Enums;
use Gnome::Shell::Raw::Definitions;

unit package Croco::Raw::Statement;

### /home/cbwood/Projects/gnome-shell-st/src/st/croco/cr-statement.h

sub cr_statement_append (CRStatement $a_this, CRStatement $a_new)
  returns CRStatement
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_at_charset_rule_get_charset (
  CRStatement      $a_this,
  CArray[CRString] $a_charset
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_at_charset_rule_parse_from_buf (
  Str        $a_buf,
  CREncoding $a_encoding
)
  returns CRStatement
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_at_charset_rule_set_charset (
  CRStatement $a_this,
  CRString    $a_charset
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_at_font_face_rule_add_decl (
  CRStatement $a_this,
  CRString    $a_prop,
  CRTerm      $a_value
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_at_font_face_rule_get_decls (
  CRStatement           $a_this,
  CArray[CRDeclaration] $a_decls
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_at_font_face_rule_set_decls (
  CRStatement   $a_this,
  CRDeclaration $a_decls
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_at_import_rule_get_imported_sheet (
  CRStatement          $a_this,
  CArray[CRStyleSheet] $a_sheet
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_at_import_rule_get_url (
  CRStatement      $a_this,
  CArray[CRString] $a_url
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_at_import_rule_parse_from_buf (
  Str        $a_buf,
  CREncoding $a_encoding
)
  returns CRStatement
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_at_import_rule_set_imported_sheet (
  CRStatement  $a_this,
  CRStyleSheet $a_sheet
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_at_import_rule_set_url (
  CRStatement $a_this,
  CRString    $a_url
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_at_media_get_from_list (
  CRStatement $a_this,
  gint        $itemnr
)
  returns CRStatement
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_at_media_nr_rules (CRStatement $a_this)
  returns gint
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_at_media_rule_parse_from_buf (
  Str        $a_buf,
  CREncoding $a_enc
)
  returns CRStatement
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_at_page_rule_get_declarations (
  CRStatement           $a_this,
  CArray[CRDeclaration] $a_decl_list
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_at_page_rule_get_sel (
  CRStatement        $a_this,
  CArray[CRSelector] $a_sel
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_at_page_rule_parse_from_buf (
  Str        $a_buf,
  CREncoding $a_encoding
)
  returns CRStatement
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_at_page_rule_set_declarations (
  CRStatement   $a_this,
  CRDeclaration $a_decl_list
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_at_page_rule_set_sel (
  CRStatement $a_this,
  CRSelector  $a_sel
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_destroy (CRStatement $a_this)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_does_buf_parses_against_core (
  Str        $a_buf,
  CREncoding $a_encoding
)
  returns uint32
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_dump (
  CRStatement $a_this,
  gpointer    $a_fp,
  gulong      $a_indent
)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_dump_charset (
  CRStatement $a_this,
  gpointer    $a_fp,
  gulong      $a_indent
)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_dump_font_face_rule (
  CRStatement $a_this,
  gpointer    $a_fp,
  glong       $a_indent
)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_dump_import_rule (
  CRStatement $a_this,
  gpointer    $a_fp,
  gulong      $a_indent
)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_dump_media_rule (
  CRStatement $a_this,
  gpointer    $a_fp,
  gulong      $a_indent
)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_dump_page (
  CRStatement $a_this,
  gpointer    $a_fp,
  gulong      $a_indent
)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_dump_ruleset (
  CRStatement $a_this,
  gpointer    $a_fp,
  glong       $a_indent
)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_font_face_rule_parse_from_buf (
  Str        $a_buf,
  CREncoding $a_encoding
)
  returns CRStatement
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_get_from_list (
  CRStatement $a_this,
  gint        $itemnr
)
  returns CRStatement
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_get_parent_sheet (
  CRStatement          $a_this,
  CArray[CRStyleSheet] $a_sheet
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_list_to_string (
  CRStatement $a_this,
  gulong      $a_indent
)
  returns Str
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_new_at_charset_rule (
  CRStyleSheet $a_sheet,
  CRString     $a_charset
)
  returns CRStatement
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_new_at_font_face_rule (
  CRStyleSheet  $a_sheet,
  CRDeclaration $a_font_decls
)
  returns CRStatement
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_new_at_import_rule (
  CRStyleSheet $a_container_sheet,
  CRString     $a_url,
  GList        $a_media_list,
  CRStyleSheet $a_imported_sheet
)
  returns CRStatement
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_new_at_media_rule (
  CRStyleSheet $a_sheet,
  CRStatement  $a_ruleset,
  GList        $a_media
)
  returns CRStatement
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_new_at_page_rule (
  CRStyleSheet  $a_sheet,
  CRDeclaration $a_decl_list,
  CRString      $a_name,
  CRString      $a_pseudo
)
  returns CRStatement
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_new_ruleset (
  CRStyleSheet  $a_sheet,
  CRSelector    $a_sel_list,
  CRDeclaration $a_decl_list,
  CRStatement   $a_media_rule
)
  returns CRStatement
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_nr_rules (CRStatement $a_this)
  returns gint
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_parse_from_buf (
  Str        $a_buf,
  CREncoding $a_encoding
)
  returns CRStatement
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_prepend (
  CRStatement $a_this,
  CRStatement $a_new
)
  returns CRStatement
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_ruleset_append_decl (
  CRStatement   $a_this,
  CRDeclaration $a_decl
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_ruleset_append_decl2 (
  CRStatement $a_this,
  CRString    $a_prop,
  CRTerm      $a_value
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_ruleset_get_declarations (
  CRStatement           $a_this,
  CArray[CRDeclaration] $a_decl_list
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_ruleset_get_sel_list (
  CRStatement        $a_this,
  CArray[CRSelector] $a_list
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_ruleset_parse_from_buf (
  Str        $a_buf,
  CREncoding $a_enc
)
  returns CRStatement
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_ruleset_set_decl_list (
  CRStatement   $a_this,
  CRDeclaration $a_list
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_ruleset_set_sel_list (
  CRStatement $a_this,
  CRSelector  $a_sel_list
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_set_parent_sheet (
  CRStatement  $a_this,
  CRStyleSheet $a_sheet
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_to_string (
  CRStatement $a_this,
  gulong      $a_indent
)
  returns Str
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_statement_unlink (CRStatement $a_stmt)
  returns CRStatement
  is      native(gnome-shell-st)
  is      export
{ * }
