use v6;

use GLib::Raw::Exports;
use Gnome::Shell::Raw::Exports;

unit package Gnome::Shell::Raw::Types;

need GLib::Raw::Debug;
need GLib::Raw::Definitions;
need GLib::Raw::Enums;
need GLib::Raw::Exceptions;
need GLib::Raw::Object;
need GLib::Raw::Structs;
need GLib::Raw::Subs;
need GLib::Raw::Traits;
need GLib::Raw::Struct_Subs;
need GLib::Roles::Pointers;
need GLib::Roles::Implementor;
need ATK::Raw::Definitions;
need ATK::Raw::Enums;
need ATK::Raw::Structs;
need JSON::GLib::Raw::Definitions;
need GIO::Raw::Definitions;
need GIO::Raw::Enums;
need GIO::Raw::Quarks;
need GIO::Raw::Structs;
need GIO::Raw::Subs;
need GIO::DBus::Raw::Types;
need GIO::Raw::Exports;
need Graphene::Raw::Exports;
need Cairo;
need Pango::Raw::Definitions;
need Pango::Raw::Enums;
need Pango::Raw::Structs;
need Pango::Raw::Subs;
need Graphene::Raw::Definitions;
need Graphene::Raw::Enums;
need GSK::Raw::Definitions:ver<4>;
need GSK::Raw::Enums:ver<4>;
need GSK::Raw::Structs:ver<4>;
need GDK::Raw::Compat:ver<4>;
need GDK::Pixbuf::Raw::Definitions;
need GDK::Pixbuf::Raw::Enums;
need GDK::Pixbuf::Raw::Structs;
need GDK::Raw::Definitions:ver<4>;
need GDK::Raw::Enums:ver<4>;
need GDK::Raw::Structs:ver<4>;
need GDK::Raw::Subs:ver<4>;
need GTK::Raw::Definitions:ver<4>;
need GTK::Raw::Enums:ver<4>;
need GTK::Raw::Structs:ver<4>;
need GTK::Raw::Subs:ver<4>;
need Mutter::Raw::Definitions;
need Mutter::Raw::Enums;
need Mutter::Raw::GSettingsEnums;
need Mutter::Raw::Subs;
need Mutter::Raw::Structs;
need NetworkManager::Raw::Definitions;
need NetworkManager::Raw::Enums;
need NetworkManager::Raw::Structs;
need Gnome::Shell::Raw::Definitions;
need Gnome::Shell::Raw::Enums;
need Gnome::Shell::Raw::Structs;

BEGIN {
  glib-re-export($_) for @gnome-shell-compunits;
}
