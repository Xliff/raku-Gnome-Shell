use v6.c;

use Method::Also;

use Gnome::Shell::Raw::Types;
use GLib::Raw::Exceptions;
use Croco::Raw::Parser;

use GLib::GList;
use Croco::String;
use Croco::Tokenizer;
use Croco::Term;

use GLib::Roles::Implementor;

class Croco::Parser {
  does GLib::Roles::Implementor;

  has CRParser $!cp is implementor;

  submethod BUILD ( :croco-parser( :$!cp ) )
  { * }

  method Croco::Raw::Structs::CRParser
    is also<CRParser>
  { $!cp }

  multi method new (CRParser $croco-parser) {
    $croco-parser ?? self.bless( :$croco-parser ) !! Nil;
  }
  multi method new ($tokenizer is copy where $tokenizer !~~ CRParser) {
    $tokenizer .= CRTknzr if $tokenizer.^can('CRTknzr');
    X::GLib::InvalidType.new(
      messager => 'Parameter must be CRTknzr-compatible!'
    ).throw unless $tookenizer ~~ CRTknzr;

    my $croco-parser = cr_parser_new($tokenizer);

    $croco-parser ?? self.bless( :$croco-parser ) !! Nil;
  }

  method new_from_buf (
    Str() $a_buf,
    Int() $a_len,
    Int() $a_enc,
    Int() $a_free_buf
  )
    is also<new-from-buf>
  {
    my gulong     $l = $a_len;
    my CREncoding $e = $a_enc;
    my gboolean   $f = $a_free_buf;

    my $croco-parser = cr_parser_new_from_buf($a_buf, $l, $e, $f);

    $croco-parser ?? self.bless( :$croco-parser ) !! Nil;
  }

  method new_from_file (Str() $a_file_uri, Int() $a_enc)
    is also<new-from-file>
  {
    my CREncoding $e = $a_enc;

    my $croco-parser = cr_parser_new_from_file($a_file_uri, $e);

    $croco-parser ?? self.bless( :$croco-parser ) !! Nil;
  }

  method new_from_input (CRInput() $a_input) is also<new-from-input> {
    my $croco-parser = cr_parser_new_from_input($a_input);

    $croco-parser ?? self.bless( :$croco-parser ) !! Nil;
  }

  method sac_handler
    is rw
    is g-pseudo-property
    is also<sac-handler>
  {
    Proxy.new:
      FETCH => -> $     { self.get_sac_handler    },
      STORE => -> $, \v { self.set_sac_handler(v) }
  }

  method tknzr is rw is g-pseudo-property is also<tokenizer> {
    Proxy.new:
      FETCH => -> $     { self.get_tknzr    },
      STORE => -> $, \v { self.set_tknzr(v) }
  }

  method use_core_grammar
    is rw
    is g-pseudo-property
    is also<use-core-grammar>
  {
    Proxy.new:
      FETCH => -> $     { self.get_use_core_grammar    },
      STORE => -> $, \v { self.set_use_core_grammar(v) }
  }

  method destroy {
    my $crs = cr_parser_destroy($!cp);

    setCrocoStatus($crs)
  }

  proto method get_parsing_location(|)
    is also<get-parsing-location>
  { * }

  multi method get_parsing_location( :$full = False, :$raw = False )
    is also<
      parsing-location
      parsing_location
    >
  {
    my $p = CRParsingLocation.new;
    my $s = samewith($p);
    propReturnObject($p, $raw, |Croco::ParsingLocation.getTypePair);
    $full ?? ($p, $s) !! $p;
  }
  multi method get_parsing_location (CRParsingLocation() $a_loc) {
    my $crs = cr_parser_get_parsing_location($!cp, $a_loc);

    setCrocoStatus($crs)
  }

  proto method get_sac_handler (|)
    is also<get-sac-handler>
  { * }

  method get_sac_handler ( :$raw = False, :$full = False ) {
    my          $a = newCArray(CRDocHandler);
    my CRStatus $s = samewith($a);

    my $o = propReturnObject( ppr($a), $raw, |Croco::DocHandler.getTypePair );
    $full ?? ($s, $o) !! $o;
  )
  method get_sac_handler (CArray[CRDocHandler] $a_handler) {
    my $crs = cr_parser_get_sac_handler($!cp, $a_handler);

    setCrocoStatus($crs)
  }

  proto method get_tknzr (|)
    is also<get-tknzr>
  { * }

  multi method get_tknzr {
    my $a = newCArray(CRTknzr);
    my $s = samewith($a);

    my $o = propReturnObject( ppr($a), $raw, |Croco::Tokenizer.getTypePair)
    $full ?? ($s, $o) !! $o;
  }
  multi method get_tknzr (CArray[CRTknzr] $a_tknzr) {
    my $crs = cr_parser_get_tknzr($!cp, $a_tknzr);

    setCrocoStatus($crs)
  }

  proto method get_use_core_grammar (|)
    is also<get-use-core-grammar>
  { * }

  multi method get_use_core_grammar ( :$full = False ) {
    my gboolean $u = 0;
    my CRStatus $s = samewith($u);

    $full ?? ($u, $s) !! $u;
  }
  multi method get_use_core_grammar (Int() $a_use_core_grammar) {
    my gboolean $a = $a_use_core_grammar.so.Int;

    my $crs = cr_parser_get_use_core_grammar($!cp, $a);

    setCrocoStatus($crs)
  }

  method parse {
    my $crs = cr_parser_parse($!cp);

    setCrocoStatus($crs)
  }

  method parse_buf (
    Str() $a_buf,
    Int() $a_len,
    Int() $a_enc
  )
    is also<parse-buf>
  {
    my gulong     $l   = $a_len;
    my CREncoding $e   = $a_enc;
    my CRStatus   $crs = cr_parser_parse_buf($!cp, $a_buf, $a_len, $a_enc);

    setCrocoStatus($crs)
  }

  method parse_charset (
    CArray[CRString]    $a_value,
    CRParsingLocation() $a_charset_sym_location
  )
    is also<parse-charset>
  {
    my CRStatus $crs = cr_parser_parse_charset(
      $!cp,
      $a_value,
      $a_charset_sym_location
    );

    setCrocoStatus($crs)
  }

  method parse_declaration (
    CArray[CRString] $a_property,
    CArray[CRTerm]   $a_expr,
    Int()            $a_important
  )
    is also<parse-declaration>
  {
    my gboolean $i   = $a_important.so.Int;
    my CRStatus $crs = cr_parser_parse_declaration(
      $!cp,
      $a_property,
      $a_expr,
      $a_important
    );

    setCrocoStatus($crs)
  }

  proto method parse_expr (|)
    is also<parse-expr>
  { * }

  multi method parse_expr ( :$raw = False, :$full = False );
    my $a = newCArray(CRTerm);
    my $s = samewith($a);

    my $o = propReturnObject( ppr($a), $raw, |Croco::Term.getTypePair)
    $full ?? ($s, $o) !! $o;
  }
  multi method parse_expr (CArray[CRTerm] $a_expr) {
    my $crs = cr_parser_parse_expr($!cp, $a_expr);

    setCrocoStatus($crs)
  }

  method parse_file (Str() $a_file_uri, Int() $a_enc) is also<parse-file> {
    my CREncoding $e   = $a_enc;
    my CRStatus   $crs = cr_parser_parse_file($!cp, $a_file_uri, $a_enc);

    setCrocoStatus($crs)
  }

  method parse_font_face is also<parse-font-face> {
    my CRStatus $crs = cr_parser_parse_font_face($!cp);

    setCrocoStatus($crs)
  }

  proto method parse_import (|)
    is also<parse-import>
  { * }

  multi method parse_import (
    my $m = newCArray(GList);
    my $i = newCArray(CRString);
    my $s = samewith($a);

    $i = propReturnObject( ppr($i), $raw, |Croco::String.getTypePair );s
    $m = returnGList( ppr($m), $raw, $glist, |Croco::String.getTypePair );
    $full ?? ($s, $m, $i) !! ($m, $i);
  }
  multi method parse_import (
    CArray[GList]       $a_media_list,
    CArray[CRString]    $a_import_string,
    CRParsingLocation() $a_location
  ) {
    my $crs = cr_parser_parse_import(
      $!cp,
      $a_media_list,
      $a_import_string,
      $a_location
    );

    setCrocoStatus($crs)
  }

  method parse_media is also<parse-media> {
    my CRStatus $crs = cr_parser_parse_media($!cp);

    setCrocoStatus($crs)
  }

  method parse_page is also<parse-page> {
    my CRStatus $crs = cr_parser_parse_page($!cp);

    setCrocoStatus($crs)
  }

  method parse_prio (CArray[CRString] $a_prio) is also<parse-prio> {
    my CRStatus $crs = cr_parser_parse_prio($!cp, $a_prio);

    setCrocoStatus($crs)
  }

  method parse_ruleset is also<parse-ruleset> {
    my CRStatus $crs = cr_parser_parse_ruleset($!cp);

    setCrocoStatus($crs)
  }

  method parse_statement_core is also<parse-statement-core> {
    my CRStatus $crs = cr_parser_parse_statement_core($!cp);

    setCrocoStatus($crs)
  }

  proto method parse_term (|)
    is also<parse-term>
  { * }

  multi method parse_term ( :$raw = False, :$full = False ) {
    my $a = newCArray(CRTerm);
    my $s = samewith($a);

    my $o = propReturnObject( ppr($a), $raw, |Croco::Term.getTypePair )
    $full ?? ($s, $o) !! $o;
  }
  multi method parse_term (CArray[CRTerm] $a_term) {
    my CRStatus $crs = cr_parser_parse_term($!cp, $a_term);

    setCrocoStatus($crs)
  }

  method set_default_sac_handler
    is also<
      set-default-sac-handler
      set-as-default-sac-handler
      set_as_default_sac_handler
    >
  {
    my CRStatus $crs = cr_parser_set_default_sac_handler($!cp);

    setCrocoStatus($crs)
  }

  method set_sac_handler (CRDocHandler() $a_handler)
    is also<set-sac-handler>
  {
    my CRStatus $crs = cr_parser_set_sac_handler($!cp, $a_handler);

    setCrocoStatus($crs)
  }

  method set_tknzr (CRTknzr() $a_tknzr) is also<set-tknzr> {
    my CRStatus $crs = cr_parser_set_tknzr($!cp, $a_tknzr);

    setCrocoStatus($crs)
  }

  method set_use_core_grammar (Int() $a_use_core_grammar)
    is also<set-use-core-grammar>
  {
    my gboolean $a   = $a_use_core_grammar.so.Int;
    my CRStatus $crs = cr_parser_set_use_core_grammar($!cp, $a);

    setCrocoStatus($crs)
  }

  method try_to_skip_spaces_and_comments
    is also<try-to-skip-spaces-and-comments>
  {
    my CRStatus $crs = cr_parser_try_to_skip_spaces_and_comments($!cp);

    setCrocoStatus($crs)
  }

}
