use v6.c;

use NativeCall;

use GLib::Raw::Definitions;

use GLib::Roles::Pointers;

unit package Croro::Raw::Definitions;

class CRDocHandler is repr<CPointer> does GLib::Roles::Pointers is export { }
