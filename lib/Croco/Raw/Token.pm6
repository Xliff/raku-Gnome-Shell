use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;
use Croco::Raw::Definitions;
use Croco::Raw::Enums;
use Croco::Raw::Structs;

unit package Croco::Raw::Token;

### /home/cbwood/Projects/gnome-shell/src/st/croco/cr-token.h

sub cr_token_destroy (CRToken $a_this)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_new
  returns CRToken
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_angle (
  CRToken          $a_this,
  CRNum            $a_num,
  CRTokenExtraType $a_et
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_atkeyword (
  CRToken  $a_this,
  CRString $a_atname
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_bc (CRToken $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_bo (CRToken $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_cbc (CRToken $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_cbo (CRToken $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_cdc (CRToken $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_cdo (CRToken $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_charset_sym (CRToken $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_comment (
  CRToken  $a_this,
  CRString $a_str
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_dashmatch (CRToken $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_delim (
  CRToken $a_this,
  guint32 $a_char
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_dimen (
  CRToken  $a_this,
  CRNum    $a_num,
  CRString $a_dim
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_ems (
  CRToken $a_this,
  CRNum   $a_num
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_exs (
  CRToken $a_this,
  CRNum   $a_num
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_font_face_sym (CRToken $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_freq (
  CRToken          $a_this,
  CRNum            $a_num,
  CRTokenExtraType $a_et
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_function (
  CRToken  $a_this,
  CRString $a_fun_name
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_hash (
  CRToken  $a_this,
  CRString $a_hash
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_ident (
  CRToken  $a_this,
  CRString $a_ident
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_import_sym (CRToken $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_important_sym (CRToken $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_includes (CRToken $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_length (
  CRToken          $a_this,
  CRNum            $a_num,
  CRTokenExtraType $a_et
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_media_sym (CRToken $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_number (
  CRToken $a_this,
  CRNum   $a_num
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_page_sym (CRToken $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_pc (CRToken $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_percentage (
  CRToken $a_this,
  CRNum   $a_num
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_po (CRToken $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_rgb (
  CRToken $a_this,
  CRRgb   $a_rgb
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_s (CRToken $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_semicolon (CRToken $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_string (
  CRToken  $a_this,
  CRString $a_str
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_time (
  CRToken          $a_this,
  CRNum            $a_num,
  CRTokenExtraType $a_et
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_token_set_uri (
  CRToken  $a_this,
  CRString $a_uri
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }
