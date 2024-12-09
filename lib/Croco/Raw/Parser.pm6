use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use GLib::Raw::Structs;
use Gnome::Shell::Raw::Definitions;
use Croco::Raw::Definitions;
use Croco::Raw::Enums;
use Croco::Raw::Structs;

### /home/cbwood/Projects/gnome-shell-st-st/src/st/croco/cr-parser.h

sub cr_parser_destroy (CRParser $a_this)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_get_parsing_location (
  CRParser          $a_this,
  CRParsingLocation $a_loc
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_get_sac_handler (
  CRParser             $a_this,
  CArray[CRDocHandler] $a_handler
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_get_tknzr (
  CRParser        $a_this,
  CArray[CRTknzr] $a_tknzr
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_get_use_core_grammar (
  CRParser $a_this,
  gboolean $a_use_core_grammar
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_new (CRTknzr $a_tknzr)
  returns CRParser
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_new_from_buf (
  Str        $a_buf,
  gulong     $a_len,
  CREncoding $a_enc,
  gboolean   $a_free_buf
)
  returns CRParser
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_new_from_file (
  Str        $a_file_uri,
  CREncoding $a_enc
)
  returns CRParser
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_new_from_input (CRInput $a_input)
  returns CRParser
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_parse (CRParser $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_parse_buf (
  CRParser   $a_this,
  Str        $a_buf,
  gulong     $a_len,
  CREncoding $a_enc
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_parse_charset (
  CRParser          $a_this,
  CArray[CRString]  $a_value,
  CRParsingLocation $a_charset_sym_location
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_parse_declaration (
  CRParser         $a_this,
  CArray[CRString] $a_property,
  CArray[CRTerm]   $a_expr,
  gboolean         $a_important
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_parse_expr (
  CRParser       $a_this,
  CArray[CRTerm] $a_expr
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_parse_file (
  CRParser   $a_this,
  Str        $a_file_uri,
  CREncoding $a_enc
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_parse_font_face (CRParser $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_parse_import (
  CRParser          $a_this,
  CArray[GList]     $a_media_list,
  CArray[CRString]  $a_import_string,
  CRParsingLocation $a_location
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_parse_media (CRParser $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_parse_page (CRParser $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_parse_prio (
  CRParser         $a_this,
  CArray[CRString] $a_prio
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_parse_ruleset (CRParser $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_parse_statement_core (CRParser $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_parse_term (
  CRParser       $a_this,
  CArray[CRTerm] $a_term
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_set_default_sac_handler (CRParser $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_set_sac_handler (
  CRParser     $a_this,
  CRDocHandler $a_handler
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_set_tknzr (
  CRParser $a_this,
  CRTknzr  $a_tknzr
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_set_use_core_grammar (
  CRParser $a_this,
  gboolean $a_use_core_grammar
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_parser_try_to_skip_spaces_and_comments (CRParser $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }
