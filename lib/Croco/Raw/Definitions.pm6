use v6.c;

use NativeCall;

use GLib::Raw::Definitions;

use GLib::Roles::Pointers;

unit package Croro::Raw::Definitions;

our $LAST-STATUS is export;

sub setCrocoStatus ($s) is export {
  $LAST-STATUS = CRStatusEnum($s);
}

class CRDocHandler is repr<CPointer> does GLib::Roles::Pointers is export { }
