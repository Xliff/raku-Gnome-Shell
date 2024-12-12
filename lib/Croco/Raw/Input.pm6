use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;
use Croco::Raw::Definitions;
use Croco::Raw::Enums;
use Croco::Raw::Structs;

unit package Croco::Raw::Input;

### /home/cbwood/Projects/gnome-shell/src/st/croco/cr-input.h

sub cr_input_consume_char (CRInput $a_this, guint32 $a_char)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_consume_chars (
  CRInput $a_this,
  guint32 $a_char,
  gulong  $a_nb_char
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_consume_white_spaces (CRInput $a_this, gulong $a_nb_chars)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_destroy (CRInput $a_this)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_end_of_input (CRInput $a_this, gboolean $a_end_of_input is rw)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_get_byte_addr (CRInput $a_this, gulong $a_offset)
  returns Str
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_get_column_num (CRInput $a_this, glong $a_col is rw)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_get_cur_byte_addr (CRInput $a_this, CArray[Str] $a_offset)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_get_cur_index (CRInput $a_this, glong $a_index is rw)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_get_cur_pos (CRInput $a_this, CRInputPos $a_pos)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_get_end_of_file (CRInput $a_this, gboolean $a_eof is rw)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_get_end_of_line (CRInput $a_this, gboolean $a_eol is rw)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_get_line_num (\CRInput $a_this, glong $a_line_num is rw)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_get_nb_bytes_left (CRInput $a_this)
  returns glong
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_get_parsing_location (
  CRInput           $a_this,
  CRParsingLocation $a_loc
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_increment_col_num (CRInput $a_this, glong $a_increment)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_increment_line_num (CRInput $a_this, glong $a_increment)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_new_from_buf (
  Str        $a_buf,
  gulong     $a_len,
  CREncoding $a_enc,
  gboolean   $a_free_buf
)
  returns CRInput
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_new_from_uri (Str $a_file_uri, CREncoding $a_enc)
  returns CRInput
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_peek_byte (
  CRInput   $a_this,
  CRSeekPos $a_origin,
  gulong    $a_offset,
  Str       $a_byte
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_peek_byte2 (
  CRInput  $a_this,
  gulong   $a_offset,
  gboolean $a_eof
)
  returns uint8
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_peek_char (CRInput $a_this, guint32 $a_char is rw)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_read_byte (CRInput $a_this, uint8 $a_byte)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_read_char (CRInput $a_this, guint32 $a_char is rw)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_ref (CRInput $a_this)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_seek_index (
  CRInput   $a_this,
  CRSeekPos $a_origin,
  gint      $a_pos
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_set_column_num (CRInput $a_this, glong $a_col)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_set_cur_index (CRInput $a_this, glong $a_index)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_set_cur_pos (CRInput $a_this, CRInputPos $a_pos)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_set_end_of_file (CRInput $a_this, gboolean $a_eof)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_set_end_of_line (CRInput $a_this, gboolean $a_eol)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_set_line_num (CRInput $a_this, glong $a_line_num)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_input_unref (CRInput $a_this)
  returns uint32
  is      native(gnome-shell-st)
  is      export
{ * }
