use v6.c;

use NativeCall;

use GLib::Roles::Pointers;

unit package Gnome::Shell::Raw::Compat;

class PolkitListener is repr<CPointer> does GLib::Roles::Pointers is export { }
