use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Mutter::Raw::Definitions;
use Mutter::Raw::Structs;
use Gnome::Shell::Raw::Definitions;

unit package Gnome::Shell::Raw::Wm;

### /home/cbwood/Projects/gnome-shell/src/shell-wm.h

sub shell_wm_complete_display_change (ShellWM $wm, gboolean $ok)
  is native(gnome-shell-st)
  is export
{ * }

sub shell_wm_completed_destroy (ShellWM $wm, MutterMetaWindowActor $actor)
  is native(gnome-shell-st)
  is export
{ * }

sub shell_wm_completed_map (ShellWM $wm, MutterMetaWindowActor $actor)
  is native(gnome-shell-st)
  is export
{ * }

sub shell_wm_completed_minimize (ShellWM $wm, MutterMetaWindowActor $actor)
  is native(gnome-shell-st)
  is export
{ * }

sub shell_wm_completed_size_change (ShellWM $wm, MutterMetaWindowActor $actor)
  is native(gnome-shell-st)
  is export
{ * }

sub shell_wm_completed_switch_workspace (ShellWM $wm)
  is native(gnome-shell-st)
  is export
{ * }

sub shell_wm_completed_unminimize (ShellWM $wm, MutterMetaWindowActor $actor)
  is native(gnome-shell-st)
  is export
{ * }

sub shell_wm_new (MutterMetaPlugin $plugin)
  returns ShellWM
  is native(gnome-shell-st)
  is export
{ * }
