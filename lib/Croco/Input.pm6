use v6.c;

use Gnome::Shell::Raw::Types;
use Croco::Raw::Input;

use GLib::Roles::Inplementor;

class Croco::Input {
  also does GLib::Roles::Implementor;

  has CRInput $!ci is implementor;

  submethod BUILD ( :cr-input ( :$!ci ) )
  { }

  method Croco::Raw::Structs::CRInput
  { $!ci }

  method new_from_buf (
    Str   $buf
    Int() $a_len,
    Int() $a_enc,
    Int() $a_free_buf
  ) {
    my gulong     $l = $a_len;
    my CREncoding $e = $a_enc;
    my gboolean   $f = $a_free_buf;

    my $cr-input = cr_input_new_from_buf($a_buf, $l, $e, $f);

    $cr-input ?? self.bless( :$cr-input ) !! Nil;
  }

  method new_from_uri (Str() $a_file_uri, Int() $a_enc) {
    my CREncoding $e = $a_enc;
    my            $cr-input    = cr_input_new_from_uri($!ci, $a_file_uri, $e);

    $cr-input ?? self.bless( :$cr-input ) !! Nil;
  }

  method consume_char (Int() $a_char) {
    my guint32 $c = $a_char;

    cr_input_consume_char($!ci, $c);
  }

  method consume_chars (Int() $a_char, Int() $a_nb_char) {
    my guint32 $c = $a_char;
    my gulong  $n = $a_nb_char;

    cr_input_consume_chars($!ci, $c, $n);
  }

  method consume_white_spaces (Int() $a_nb_chars) {
    my gulong $nb = $a_nb_chars;

    cr_input_consume_white_spaces($!ci, $nb);
  }

  method destroy {
    cr_input_destroy($!ci);
  }

  proto method end_of_input (|)
  { * }

  multi method end_of_input {
    my $b;
    samewith($b);
    $b;
  }
  multi method end_of_input ($a_end_of_input is rw) {
    my gboolean $e   = 0;
    my CRStatus $crs = cr_input_end_of_input($!ci, $e);
    $a_end_of_input = $e.so.Int;
    setCrocoStatus($crs);
  }

  proto method get_byte_addr (|)
  { * }

  multi method get_byte_addr {
    my $b;
    samewith($b);
    $b;
  }
  multi method get_byte_addr ($a_offset is rw) {
    my gulong    $o  = 0;
    my CRStatus $crs = cr_input_get_byte_addr($!ci, $o);
    $a_offset = $o;
    setCrocoStatus($crs);
  }

  proto method get_column_num (|)
  { * }

  multi method get_column_num {
    my $b;
    samewith($b);
    $b;
  }
  multi method get_column_num ($a_col is rw) {
    my glong $c = 0;
    my CRStatus $crs = cr_input_get_column_num($!ci, $c);
    $a_col = $c;
    setCrocoStatus($crs);
  }

  method get_cur_byte_addr (CArray[Str] $a_offset) {
    cr_input_get_cur_byte_addr($!ci, $a_offset);
  }

  proto method get_cur_index (|)
  { * }

  multi method get_cur_index {
    my $b;
    samewith($b);
    $b;
  }
  multi method get_cur_index ($a_index is rw) {
    my glong    $i   = 0;
    my CRStatus $crs = cr_input_get_cur_index($!ci, $i);
    $a_index = $i;
    setCrocoStatus($crs);
  }

  method get_cur_pos (CRInputPos $a_pos) {
    cr_input_get_cur_pos($!ci, $a_pos);
  }

  proto method get_end_of_file (|)
  { * }

  multi method get_end_of_file {
    my $b;
    samewith($b);
    $b;
  }
  multi method get_end_of_file ($a_eof is rw) {
    my gboolean $e   = 0;
    my CRStatus $crs = cr_input_get_end_of_file($!ci, $e);
    $a_eof = $e;
    setCrocoStatus($crs);
  }

  proto method get_end_of_line (|)
  { * }

  multi method get_end_of_line {
    my $b;
    samewith($b);
    $b;
  }
  multi method get_end_of_line ($a_eol is rw) {
    my gboolean $e   = 0;
    my CRStatus $crs = cr_input_get_end_of_line($!ci, $e);
    $a_eol = $e;
    setCrocoStatus($crs);
  }

  proto method get_line_num (|)
  { * }

  multi method get_line_num {
    my $b;
    samewith($b);
    $b;
  }
  multi method get_line_num ($a_line_num is rw) {
    my glong    $l   = 0;
    my CRStatus $crs = cr_input_get_line_num($!ci, $l);
    $a_line_num = $l;
    setCrocoStatus($crs);
  }

  method get_nb_bytes_left {
    cr_input_get_nb_bytes_left($!ci);
  }

  method get_parsing_location (CRParsingLocation() $a_loc) {
    cr_input_get_parsing_location($!ci, $a_loc);
  }

  method increment_col_num (Int() $a_increment) {
    my glong    $i   = $a_increment;
    my CRStatus $crs = cr_input_increment_col_num($!ci, $i);
    setCrocoStatus($crs);
  }

  method increment_line_num (Int() $a_increment) {
    my glong    $i   = $a_increment;
    my CRStatus $crs = cr_input_increment_line_num($!ci, $i);
    setCrocoStatus($crs);
  }

  proto method peek_byte (|)
  { * }

  multi method peek_byte (Int() $a_origin, Int() $a_offset) {
    my $b;
    samewith($b);
    $b;
  }
  multi method peek_byte (Int() $a_origin, Int() $a_offset, $a_byte is rw) {
    my CRSeekPos $r = $a_origin;
    my gulong    $o = $a_offset;
    my guint8    $b = 0;

    my $crs = cr_input_peek_byte($!ci, $r, $o, $b);
    $a_byte = $b;
    setCrocoStatus($crs);
  }

  method peek_byte2 (Int() $a_offset, Int() $a_eof) {
    my gulong   $o = $a_offset;
    my gboolean $e = $a_eof.so.Int;

    cr_input_peek_byte2($!ci, $o, $e);
  }

  proto method peek_char (|)
  { * }

  multi method peek_char {
    my $b;
    samewith($b);
    $b;
  }
  multi method peek_char ($a_char is rw) {
    my guint32  $c   = 0;
    my CRStatus $crs = cr_input_peek_char($!ci, $c);
    $a_char = $c;
    setCrocoStatus($crs);
  }

  proto method read_byte (|)
  { * }

  multi method read_byte {
    my $b;
    samewith($b);
    $b;
  }
  multi method read_byte ($a_byte is rw) {
    my uint8    $b   = 0;
    my CRStatus $crs = cr_input_read_byte($!ci, $b);
    $a_byte = $b;
    setCrocoStatus($crs);
  }

  proto method read_char (|)
  { * }

  multi method read_char {
    my $b;
    samewith($b);
    $b;
  }
  multi method read_char ($a_char is rw) {
    my guint32  $c   = 0;
    my CRStatus $crs = cr_input_read_char($!ci, $c);
    $a_char = $c;
    setCrocoStatus($crs);
  }

  method ref {
    cr_input_ref($!ci);
    self;
  }

  method seek_index (Int() $a_origin, Int() $a_pos) {
    my CRSeekPos $o = $a_origin;
    my gint      $p = $a_pos;

    cr_input_seek_index($!ci, $o, $p);
  }

  method set_column_num (Int() $a_col) {
    my glong $c = $a_col;

    cr_input_set_column_num($!ci, $c);
  }

  method set_cur_index (Int() $a_index) {
    my glong $i = $a_index;

    cr_input_set_cur_index($!ci, $i);
  }

  method set_cur_pos (CRInputPos() $a_pos) {
    cr_input_set_cur_pos($!ci, $a_pos);
  }

  method set_end_of_file (Int() $a_eof) {
    my gboolean $e = $a_eof;

    cr_input_set_end_of_file($!ci, $e);
  }

  method set_end_of_line (Int() $a_eol) {
    my gboolean $e = $a_eol;

    cr_input_set_end_of_line($!ci, $e);
  }

  method set_line_num (Int() $a_line_num) {
    my glong $l = $a_line_num;

    cr_input_set_line_num($!ci, $l);
  }

  method unref {
    cr_input_unref($!ci);
  }

}
