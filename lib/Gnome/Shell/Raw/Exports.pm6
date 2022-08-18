use v6.c;

use GLib::Raw::Exports;

unit package Gnome::Shell::Raw::Exports;

our @gnome-shell-exports is export = <
  Gnome::Shell::Raw::Definitions
  Gnome::Shell::Raw::Enums
  Gnome::Shell::Raw::Structs
>;
