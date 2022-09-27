use v6.c;

use GLib::Raw::Exports;
use ATK::Raw::Exports;
use GIO::Raw::Exports;
use JSON::GLib::Raw::Exports;
use Pango::Raw::Exports;
use Graphene::Raw::Exports;
use Mutter::Raw::Exports;
use NetworkManager::Raw::Exports;

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
                                       |@gnome-shell-exports;
