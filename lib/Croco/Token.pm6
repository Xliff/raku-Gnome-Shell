use v6.c;

use Method::Also;

use Gnome::Shell::Raw::Types;
use Croco::Raw::Token;

use GLib::Roles::Implementor;

class Croco::Token {
  also does GLib::Roles::Implementor;

  has CRToken $!ct is implementor;

  submethod BUILD ( :croko-token( :$!ct ) )
  { }

  method Croco::Raw::Structs::CRToken
    is also<CRToken>
  { $!ct }

  multi method new (CRToken $cr-token) {
    $cr-token ?? self.bless( :$cr-token ) !! Nil;
  }
  multi method new {
    my $cr-token = cr_token_new();

    $cr-token ?? self.bless( :$cr-token ) !! Nil;
  }

  method destroy {
    cr_token_destroy($!ct);
  }

  method set_angle (CRNum() $a_num, Int() $a_et) is also<set-angle> {
    my CRTokenExtraType $e   = $a_et;
    my CRStatus         $crs = cr_token_set_angle($!ct, $a_num, $e);

    setCrocoStatus($crs)
  }

  method set_atkeyword (CRString() $a_atname) is also<set-atkeyword> {
    my CRStatus $crs = cr_token_set_atkeyword($!ct, $a_atname);

    setCrocoStatus($crs)
  }

  method set_bc is also<set-bc> {
    my CRStatus $crs = cr_token_set_bc($!ct);

    setCrocoStatus($crs)
  }

  method set_bo is also<set-bo> {
    my CRStatus $crs = cr_token_set_bo($!ct);

    setCrocoStatus($crs)
  }

  method set_cbc is also<set-cbc> {
    my CRStatus $crs = cr_token_set_cbc($!ct);

    setCrocoStatus($crs)
  }

  method set_cbo is also<set-cbo> {
    my CRStatus $crs = cr_token_set_cbo($!ct);

    setCrocoStatus($crs)
  }

  method set_cdc is also<set-cdc> {
    my CRStatus $crs = cr_token_set_cdc($!ct);

    setCrocoStatus($crs)
  }

  method set_cdo is also<set-cdo> {
    my CRStatus $crs = cr_token_set_cdo($!ct);

    setCrocoStatus($crs)
  }

  method set_charset_sym is also<set-charset-sym> {
    my CRStatus $crs = cr_token_set_charset_sym($!ct);

    setCrocoStatus($crs)
  }

  method set_comment (CRString() $a_str) is also<set-comment> {
    my CRStatus $crs = cr_token_set_comment($!ct, $a_str);

    setCrocoStatus($crs)
  }

  method set_dashmatch is also<set-dashmatch> {
    my CRStatus $crs = cr_token_set_dashmatch($!ct);

    setCrocoStatus($crs)
  }

  method set_delim (guint32 $a_char) is also<set-delim> {
    my guint32  $c   = $a_char;
    my CRStatus $crs = cr_token_set_delim($!ct, $c);

    setCrocoStatus($crs)
  }

  method set_dimen (CRNum() $a_num, CRString() $a_dim) is also<set-dimen> {
    my CRStatus $crs = cr_token_set_dimen($!ct, $a_num, $a_dim);

    setCrocoStatus($crs)
  }

  method set_ems (CRNum() $a_num) is also<set-ems> {
    my CRStatus $crs = cr_token_set_ems($!ct, $a_num);

    setCrocoStatus($crs)
  }

  method set_exs (CRNum() $a_num) is also<set-exs> {
    my CRStatus $crs = cr_token_set_exs($!ct, $a_num);

    setCrocoStatus($crs)
  }

  method set_font_face_sym is also<set-font-face-sym> {
    my CRStatus $crs = cr_token_set_font_face_sym($!ct);

    setCrocoStatus($crs)
  }

  method set_freq (CRNum() $a_num, Int() $a_et) is also<set-freq> {
    my CRTokenExtraType $e   = $a_et;
    my CRStatus         $crs = cr_token_set_freq($!ct, $a_num, $a_et);

    setCrocoStatus($crs)
  }

  method set_function (CRString() $a_fun_name) is also<set-function> {
    my CRStatus $crs = cr_token_set_function($!ct, $a_fun_name);

    setCrocoStatus($crs)
  }

  method set_hash (CRString() $a_hash) is also<set-hash> {
    my CRStatus $crs = cr_token_set_hash($!ct, $a_hash);

    setCrocoStatus($crs)
  }

  method set_ident (CRString() $a_ident) is also<set-ident> {
    my CRStatus $crs = cr_token_set_ident($!ct, $a_ident);

    setCrocoStatus($crs)
  }

  method set_import_sym is also<set-import-sym> {
    my CRStatus $crs = cr_token_set_import_sym($!ct);

    setCrocoStatus($crs)
  }

  method set_important_sym is also<set-important-sym> {
    my CRStatus $crs = cr_token_set_important_sym($!ct);

    setCrocoStatus($crs)
  }

  method set_includes is also<set-includes> {
    my CRStatus $crs = cr_token_set_includes($!ct);

    setCrocoStatus($crs)
  }

  method set_length (CRNum() $a_num, Int() $a_et) is also<set-length> {
    my CRTokenExtraType $e   = $a_et;
    my CRStatus         $crs = cr_token_set_length(
      $!ct,
      $a_num,
      $e
    );

    setCrocoStatus($crs)
  }

  method set_media_sym is also<set-media-sym> {
    my CRStatus $crs = cr_token_set_media_sym($!ct);

    setCrocoStatus($crs)
  }

  method set_number (CRNum() $a_num) is also<set-number> {
    my CRStatus $crs = cr_token_set_number($!ct, $a_num);

    setCrocoStatus($crs)
  }

  method set_page_sym is also<set-page-sym> {
    my CRStatus $crs = cr_token_set_page_sym($!ct);

    setCrocoStatus($crs)
  }

  method set_pc is also<set-pc> {
    my CRStatus $crs = cr_token_set_pc($!ct);

    setCrocoStatus($crs)
  }

  method set_percentage (CRNum() $a_num) is also<set-percentage> {
    my CRStatus $crs = cr_token_set_percentage($!ct, $a_num);

    setCrocoStatus($crs)
  }

  method set_po is also<set-po> {
    my CRStatus $crs = cr_token_set_po($!ct);

    setCrocoStatus($crs)
  }

  method set_rgb (CRRgb() $a_rgb) is also<set-rgb> {
    my CRStatus $crs = cr_token_set_rgb($!ct, $a_rgb);

    setCrocoStatus($crs)
  }

  method set_s is also<set-s> {
    my CRStatus $crs = cr_token_set_s($!ct);

    setCrocoStatus($crs)
  }

  method set_semicolon is also<set-semicolon> {
    my CRStatus $crs = cr_token_set_semicolon($!ct);

    setCrocoStatus($crs)
  }

  method set_string (CRString() $a_str) is also<set-string> {
    my CRStatus $crs = cr_token_set_string($!ct, $a_str);

    setCrocoStatus($crs)
  }

  method set_time (CRNum() $a_num, Int() $a_et) is also<set-time> {
    my CRTokenExtraType $e   = $a_et;
    my CRStatus         $crs = cr_token_set_time($!ct, $a_num, $e);

    setCrocoStatus($crs)
  }

  method set_uri (CRString() $a_uri) is also<set-uri> {
    my CRStatus $crs = cr_token_set_uri($!ct, $a_uri);

    setCrocoStatus($crs)
  }

}
