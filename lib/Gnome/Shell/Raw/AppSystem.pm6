use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;

unit package Gnome::Shell::Raw::AppSystem;


### /home/cbwood/Projects/gnome-shell/src/shell-app-system.h

sub shell_app_system_get_default () 
  returns ShellAppSystem
  is      native(gnome-shell)
  is      export
{ * }

sub shell_app_system_get_installed (ShellAppSystem $self) 
  returns GList
  is      native(gnome-shell)
  is      export
{ * }

sub shell_app_system_get_running (ShellAppSystem $self) 
  returns GSList
  is      native(gnome-shell)
  is      export
{ * }

sub shell_app_system_lookup_app (ShellAppSystem $system, Str $id) 
  returns ShellApp
  is      native(gnome-shell)
  is      export
{ * }

sub shell_app_system_lookup_desktop_wmclass (ShellAppSystem $system, Str $wmclass) 
  returns ShellApp
  is      native(gnome-shell)
  is      export
{ * }

sub shell_app_system_lookup_heuristic_basename (ShellAppSystem $system, Str $id) 
  returns ShellApp
  is      native(gnome-shell)
  is      export
{ * }

sub shell_app_system_lookup_startup_wmclass (ShellAppSystem $system, Str $wmclass) 
  returns ShellApp
  is      native(gnome-shell)
  is      export
{ * }

# cw: Array of GStrV
sub shell_app_system_search (Str $search_string) 
  returns CArray[CArray[Str]]
  is      native(gnome-shell)
  is      export
{ * }