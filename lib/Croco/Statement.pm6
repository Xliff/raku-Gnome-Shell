
use v6.c;

use Method::Also;

use Gnome::Shell::Raw::Types;
use Croco::Raw::Statement;

class Croco::Statement {
  also does GLib::Roles::Implementor;

  has CRStatement $!cs is implementor

  method Croco::Raw::Definitions::CRStatement
    is also<CRStatement>
  { $!cs }

  submethod BUILD ( :croco-statement(:$!cs) )
  { }

  proto method new (|)
  { * }

  multi method new (CrocoStatement :$croco-statement ) {
    $croco-statement ?? self.bless( :$croco-statement ) !! Nil
  }
  multi method new (CrocoStatement $croco-statement) {
    $croco-statement ?? self.bless( :$croco-statement ) !! Nil
  }

  method new_at_charset_rule (
    CRStyleSheet() $a_sheet,
    CRString()     $a_charset
  )
    is also<new-at-charset-rule>
  {
    my $croco-statement = cr_statement_new_at_charset_rule(
      $a_sheet,
      $a_charset
    );

    $croco-statement ?? self.bless( :$croco-statement ) !! Nil
  }

  method new_at_font_face_rule (
    CRStyleSheet()  $a_sheet,
    CRDeclaration() $a_font_decls
  )
    is also<new-at-font-face-rule>
  {
    my $croco-statement = cr_statement_new_at_font_face_rule(
      $a_sheet,
      $a_font_decls
    );

    $croco-statement ?? self.bless( :$croco-statement ) !! Nil
  }

  method new_at_import_rule (
    CRStyleSheet() $a_container_sheet,
    CRString()     $a_url,
    GList()        $a_media_list,
    CRStyleSheet() $a_imported_sheet
  )
    is also<new-at-import-rule>
  {
    my $croco-statement = cr_statement_new_at_import_rule(
      $a_container_sheet,
      $a_url,
      $a_media_list,
      $a_imported_sheet
    );

    $croco-statement ?? self.bless( :$croco-statement ) !! Nil
  }

  method new_at_media_rule (
    CRStyleSheet() $a_sheet,
    CRStatement()  $a_ruleset,
    GList()        $a_media
  )
    is also<new-at-media-rule>
  {
    my $croco-statement = cr_statement_new_at_media_rule(
      $a_sheet,
      $a_ruleset,
      $a_media
    );

    $croco-statement ?? self.bless( :$croco-statement ) !! Nil
  }

  method new_at_page_rule (
    CRStyleSheet()  $a_sheet,
    CRDeclaration() $a_decl_list,
    CRString()      $a_name,
    CRString()      $a_pseudo
  )
    is also<new-at-page-rule>
  {
    my $croco-statement = cr_statement_new_at_page_rule(
      $a_sheet,
      $a_decl_list,
      $a_name,
      $a_pseudo
    );

    $croco-statement ?? self.bless( :$croco-statement ) !! Nil
  }

  method new_ruleset (
    CRStyleSheet()  $a_sheet,
    CRSelector()    $a_sel_list,
    CRDeclaration() $a_decl_list,
    CRStatement()   $a_media_rule
  )
    is also<new-ruleset>
  {
    my $croco-statement = cr_statement_new_ruleset(
      $a_sheet,
      $a_sel_list,
      $a_decl_list,
      $a_media_rule
    );

    $croco-statement ?? self.bless( :$croco-statement ) !! Nil
  }

  method append (CRStatement() $a_new) {
    cr_statement_append($!cs, $a_new);
  }

  proto method at_charset_rule_get_charset (|)
    is also<at-charset-rule-get-charset>
  { * }

  multi method at_charset_rule_get_charset {
    samewith( newCArray(CRString) );
  }
  multi method at_charset_rule_get_charset (CArray[CRString] $a_charset) {
    cr_statement_at_charset_rule_get_charset($!cs, $a_charset);
    $a_charset[0];
  }

  method at_charset_rule_parse_from_buf (Str() $a_buf, Int() $a_encoding)
    is also<at-charset-rule-parse-from-buf>
  {
    my CREncoding $a = $a_encoding;

    cr_statement_at_charset_rule_parse_from_buf($!cs, $a);
  }

  method at_charset_rule_set_charset (CRString() $a_charset)
    is also<at-charset-rule-set-charset>
  {
    cr_statement_at_charset_rule_set_charset($!cs, $a_charset);
  }

  method at_font_face_rule_add_decl (CRString() $a_prop, CRTerm() $a_value)
    is also<at-font-face-rule-add-decl>
  {
    cr_statement_at_font_face_rule_add_decl($!cs, $a_prop, $a_value);
  }

  proto method at_font_face_rule_get_decls (|)
    is also<at-font-face-rule-get-decls>
  { * }

  multi method at_font_face_rule_get_decls ( :$raw = False ) {
    samewith( newCArray(CRDeclaration), :$raw );
  }
  multi method at_font_face_rule_get_decls (
    CArray[CRDeclaration]  $a_decls,
                          :$raw      = False
  ) {
    cr_statement_at_font_face_rule_get_decls($!cs, $a_decls);
    propReturnObject(
      $a_decls[0],
      $raw,
      |Croco::Declaration.getTypePair
    );
  }

  method at_font_face_rule_set_decls (CRDeclaration() $a_decls)
    is also<at-font-face-rule-set-decls>
  {
    cr_statement_at_font_face_rule_set_decls($!cs, $a_decls);
  }

  method at_import_rule_get_imported_sheet (CArray[CRStyleSheet] $a_sheet)
    is also<at-import-rule-get-imported-sheet>
  {
    cr_statement_at_import_rule_get_imported_sheet($!cs, $a_sheet);
  }

  proto method at_import_rule_get_url (|)
    is also<at-import-rule-get-url>
  { * }

  multi method at_import_rule_get_url ( :$raw = False ) {
    samewith( newCarray(CRString), :$raw = False );
  }

  multi method at_import_rule_get_url (
    CArray[CRString]  $a_url,
                     :$raw    = False
  ) {
    cr_statement_at_import_rule_get_url($!cs, $a_url);
    propReturnObject(
      $a_url[0],
      $raw,
      |Croco::String.getTypePair
    );
  }

  method at_import_rule_parse_from_buf (
    Str()  $buf,
    Int()  $a_encoding,
          :$raw         = False
  )
    is also<at-import-rule-parse-from-buf>
  {
    my CREncoding $a = $a_encoding;

    propReturnObject(
      cr_statement_at_import_rule_parse_from_buf($buf, $a),
      $raw,
      |self.getTypePair
    );
  }

  method at_import_rule_set_imported_sheet (CRStyleSheet() $a_sheet)
    is also<at-import-rule-set-imported-sheet>
  {
    cr_statement_at_import_rule_set_imported_sheet($!cs, $a_sheet);
  }

  method at_import_rule_set_url (CRString() $a_url)
    is also<at-import-rule-set-url>
  {
    cr_statement_at_import_rule_set_url($!cs, $a_url);
  }

  method at_media_get_from_list (Int() $itemnr, :$raw = False)
    is also<at-media-get-from-list>
  {
    my gint $i = $itemnr;

    propReturnObject(
      cr_statement_at_media_get_from_list($!cs, $i),
      $raw,
      |self.getTypePair
    );
  }

  method at_media_nr_rules is also<at-media-nr-rules> {
    cr_statement_at_media_nr_rules($!cs);
  }

  has $!media;
  method media {
    unless $!media {
      my $s = self;

      $!media = (class :: {
        also does Positional;

        method AT-POS (Int() $k) is also<AT_POS> {
          return Nil unless $k ~~ 0 .. $s.at_media_nr_rules;
          $s.at_media_get_from_list($k);
        }

        method elems {
          $s.at_media_nr_rules;
        }
      }).new;
    }
    $!media;
  }

  method at_media_rule_parse_from_buf (
    Str()  $a_buf,
    Int()  $a_enc,
          :$raw     = False
  )
    is also<at-media-rule-parse-from-buf>
  {
    my CREncoding $a = $a_enc;

    propReturnObject(
      cr_statement_at_media_rule_parse_from_buf($!cs, $a_enc),
      $raw,
      |self.getTypePair
    )
  }

  proto method at_page_rule_get_declarations (|)
    is also<at-page-rule-get-declarations>
  { * }

  multi method at_page_rule_get_declarations ( :$raw = False ) {
    samewith( newCArray(CRDeclaration), :$raw );
  }
  multi method at_page_rule_get_declarations (
    CArray[CRDeclaration]  $a_decl_list
                          :$raw         = False
  ) {
    cr_statement_at_page_rule_get_declarations($!cs, $a_decl_list),
    propReturnObject($a_decl_list[0] $raw, |Croco::Declaration.getTypePair);
  }

  proto method at_page_rule_get_sel (|)
    is also<at-page-rule-get-sel>
  { * }

  multi method at_page_rule_get_sel ( :$raw = False ) {
    samewith( newCArray(CRSelector), :$raw );
  }
  multi method at_page_rule_get_sel (
    CArray[CRSelector]  $a_sel,
                       :$raw     = False
  ) {
    cr_statement_at_page_rule_get_sel($!cs, $a_sel);
    propReturnObject($a_sel[0], $raw, |Croco::Selector.getTypePair);
  }

  method at_page_rule_parse_from_buf (Str() $a_buf, Int() $a_encoding)
    is also<at-page-rule-parse-from-buf>
  {
    my CREncoding $a = $a_encoding;

    propReturnObject(
      cr_statement_at_page_rule_parse_from_buf($!cs, $a_buf, $a);
      $raw,
      |self.getTypePair
    );
  }

  method at_page_rule_set_declarations (CRDeclaration() $a_decl_list)
    is also<at-page-rule-set-declarations>
  {
    cr_statement_at_page_rule_set_declarations($!cs, $a_decl_list);
  }

  method at_page_rule_set_sel (CRSelector() $a_sel)
    is also<at-page-rule-set-sel>
  {
    cr_statement_at_page_rule_set_sel($!cs, $a_sel);
  }

  method destroy {
    cr_statement_destroy($!cs);
  }

  method does_buf_parses_against_core (Str() $a_buf, Int() $a_encoding)
    is also<does-buf-parses-against-core>
  {
    my CREncoding $a = $a_encoding;

    cr_statement_does_buf_parses_against_core($!cs, $a);
  }

  method dump (gpointer $a_fp, Int() $a_indent) {
    my gulong $a = $a_indent;

    cr_statement_dump($!cs, $a_fp, $a);
  }

  method dump_charset (gpointer $a_fp, Int() $a_indent)
    is also<dump-charset>
  {
    my gulong $a = $a_indent;

    cr_statement_dump_charset($!cs, $a_fp, $a);
  }

  method dump_font_face_rule (gpointer $a_fp, Int() $a_indent)
    is also<dump-font-face-rule>
  {
    my glong $a = $a_indent;

    cr_statement_dump_font_face_rule($!cs, $a_fp, $a);
  }

  method dump_import_rule (gpointer $a_fp, Int() $a_indent)
    is also<dump-import-rule>
  {
    my gulong $a = $a_indent;

    cr_statement_dump_import_rule($!cs, $a_fp, $a);
  }

  method dump_media_rule (gpointer $a_fp, Int() $a_indent)
    is also<dump-media-rule>
  {
    my gulong $a = $a_indent;

    cr_statement_dump_media_rule($!cs, $a_fp, $a);
  }

  method dump_page (gpointer $a_fp, Int() $a_indent) is also<dump-page> {
    my gulong $a = $a_indent;

    cr_statement_dump_page($!cs, $a_fp, $a);
  }

  method dump_ruleset (gpointer $a_fp, Int() $a_indent) is also<dump-ruleset> {
    my glong $a = $a_indent;

    cr_statement_dump_ruleset($!cs, $a_fp, $a);
  }

  method font_face_rule_parse_from_buf (
    Str()  $a_buf,
    Int()  $a_encoding,
          :$raw         = False
  )
    is also<font-face-rule-parse-from-buf>
  {
    my CREncoding $a = $a_encoding;

    propReturnObject(
      cr_statement_font_face_rule_parse_from_buf($!cs, $a_buf, $a),
      $raw,
      |self.getTypePair
    );
  }

  method get_from_list (Int() $itemnr, :$raw = False)
    is also<get-from-list>
  {
    my gint $i = $itemnr;

    propReturnObject(
      cr_statement_get_from_list($!cs, $itemnr),
      $raw,
      |self.getTypePair
    );
  }

  proto method get_parent_sheet (|)
    is also<get-parent-sheet>
  { * }

  multi method get_parent_sheet ( :$raw = False ) {
    samewith( newCArray(CRStyleSheet), :$raw );
  }
  multi method get_parent_sheet (
    CArray[CRStyleSheet]  $a_sheet,
                         :$raw      = False
  ) {
    cr_statement_get_parent_sheet($!cs, $a_sheet);
    propReturnObject($a_sheet[0], $raw, |Croco::StyleSheet.getTypePair);
  }

  method list_to_string (Int() $a_indent) is also<list-to-string> {
    my gulong $a = $a_indent;

    cr_statement_list_to_string($!cs, $a_indent);
  }

  method nr_rules is also<elems> is also<nr-rules> {
    cr_statement_nr_rules($!cs);
  }

  method AT-POS (Int() $k) is also<AT_POS> {
    return Nil unless $k ~~ 0 .. $.nr_rules;
    $.get_from_list($k);
  }

  method parse_from_buf (Str() $a_buf, Int() $a_encoding, :$raw = False)
    is also<parse-from-buf>
  {
    my CREncoding $a = =$a_encoding;

    propReturnObject(
      cr_statement_parse_from_buf($!cs, $a),
      $raw,
      |self.getTypePair
    );
  }

  method prepend (CRStatement() $a_new) {
    cr_statement_prepend($!cs, $a_new);
  }

  method ruleset_append_decl (CRDeclaration() $a_decl)
    is also<ruleset-append-decl>
  {
    cr_statement_ruleset_append_decl($!cs, $a_decl);
  }

  method ruleset_append_decl2 (CRString() $a_prop, CRTerm() $a_value)
    is also<ruleset-append-decl2>
  {
    cr_statement_ruleset_append_decl2($!cs, $a_prop, $a_value);
  }

  proto method ruleset_get_declarations (|)
    is also<ruleset-get-declarations>
  { * }

  multi method ruleset_get_declarations ( :$raw = False ) {
    samewith( newCArray(CRDeclaration), :$raw );
  }
  multi method ruleset_get_declarations (
    CArray[CRDeclaration]  $a_decl_list,
                          :$raw          = False
  ) {
    cr_statement_ruleset_get_declarations($!cs, $a_decl_list),
    propReturnObject($a_decl_list[0] $raw, |Croco::Declaration.getTypePair);
  }

  proto method ruleset_get_sel_list (|)
    is also<ruleset-get-sel-list>
  { * }

  multi method ruleset_get_sel_list ( :$raw = False ) {
    samewith( newCArray(CRSelector), :$raw );

  multi method ruleset_get_sel_list (
    CArray[CRSelector]  $a_list,
                       :$raw      = False
  ) {
    cr_statement_ruleset_get_sel_list($!cs, $a_list);
    propReturnObject($a_list[0], $raw, |Croco::Selector.getTypePair);
  }

  method ruleset_parse_from_buf (Str() $a_buf, Int() $a_enc)
    is also<ruleset-parse-from-buf>
  {
    my CREncoding $a = $a_enc;

    propReturnObject(
      cr_statement_ruleset_parse_from_buf($!cs, $a_enc),
      $raw,
      |self.getTypePair
    );
  }

  method ruleset_set_decl_list (CRDeclaration() $a_list)
    is also<ruleset-set-decl-list>
  {
    cr_statement_ruleset_set_decl_list($!cs, $a_list);
  }

  method ruleset_set_sel_list (CRSelector() $a_sel_list)
    is also<ruleset-set-sel-list>
  {
    cr_statement_ruleset_set_sel_list($!cs, $a_sel_list);
  }

  method set_parent_sheet (CRStyleSheet() $a_sheet)
    is also<set-parent-sheet>
  {
    cr_statement_set_parent_sheet($!cs, $a_sheet);
  }

  method to_string (Int() $a_indent)
    is also<
      to-string
      Str
    >
  {
    my gulong $a = $a_indent;

    cr_statement_to_string($!cs, $a);
  }

  method unlink {
    cr_statement_unlink($!cs);
  }

}
