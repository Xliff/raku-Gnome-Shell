use v6.c;

use GLib::Raw::Exports;
use ATK::Raw::Exports;
use GDK::Raw::Exports:ver<4>;
use GDK::Pixbuf::Raw::Exports;
use GIO::Raw::Exports;
use Graphene::Raw::Exports;
use GSK::Raw::Exports:ver<4>;
use GTK::Raw::Exports:ver<4>;
use JSON::GLib::Raw::Exports;
use Mutter::Raw::Exports;
use NetworkManager::Raw::Exports;
use Pango::Raw::Exports;

unit package Gnome::Shell::Raw::Exports;

our @gnome-shell-exports is export = <
  Gnome::Shell::Raw::Definitions
  Gnome::Shell::Raw::Enums
  Gnome::Shell::Raw::Structs
>;


our @gnome-shell-compunits is export = |@glib-exports,
                                       |@atk-exports,
                                       |@jg-exports,
                                       |@gio-exports,
                                       |@pango-exports,
                                       |@graphene-exports,
                                       |@mutter-exports,
                                       |@nm-exports,
                                       |@gsk4-exports,
                                       |@gdk4-exports,
                                       |@gtk4-exports,
                                       |@gnome-shell-exports;
