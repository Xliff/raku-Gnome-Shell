use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use GLib::Raw::Structs;
use GIO::Raw::Definitions;
use Mutter::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;
use Gnome::Shell::Raw::Enums;

unit package Gnome::Shell::Raw::App;

### /home/cbwood/Projects/gnome-shell/src/shell-app.h

sub shell_app_activate (ShellApp $app)
  is native(gnome-shell)
  is export
{ * }

sub shell_app_activate_full (
  ShellApp $app,
  gint     $workspace,
  guint32  $timestamp
)
  is native(gnome-shell)
  is export
{ * }

sub shell_app_activate_window (
  ShellApp         $app,
  MutterMetaWindow $window,
  guint32          $timestamp
)
  is native(gnome-shell)
  is export
{ * }

sub shell_app_can_open_new_window (ShellApp $app)
  returns uint32
  is native(gnome-shell)
  is export
{ * }

sub shell_app_compare (ShellApp $app, ShellApp $other)
  returns gint
  is native(gnome-shell)
  is export
{ * }

sub shell_app_compare_by_name (ShellApp $app, ShellApp $other)
  returns gint
  is native(gnome-shell)
  is export
{ * }

sub shell_app_create_icon_texture (ShellApp $app, gint $size)
  returns MutterClutterActor
  is native(gnome-shell)
  is export
{ * }

sub shell_app_get_app_info (ShellApp $app)
  returns GDesktopAppInfo
  is native(gnome-shell)
  is export
{ * }

sub shell_app_get_busy (ShellApp $app)
  returns uint32
  is native(gnome-shell)
  is export
{ * }

sub shell_app_get_description (ShellApp $app)
  returns Str
  is native(gnome-shell)
  is export
{ * }

sub shell_app_get_icon (ShellApp $app)
  returns GIcon
  is native(gnome-shell)
  is export
{ * }

sub shell_app_get_id (ShellApp $app)
  returns Str
  is native(gnome-shell)
  is export
{ * }

sub shell_app_get_n_windows (ShellApp $app)
  returns guint
  is native(gnome-shell)
  is export
{ * }

sub shell_app_get_name (ShellApp $app)
  returns Str
  is native(gnome-shell)
  is export
{ * }

sub shell_app_get_pids (ShellApp $app)
  returns GSList
  is native(gnome-shell)
  is export
{ * }

sub shell_app_get_state (ShellApp $app)
  returns ShellAppState
  is native(gnome-shell)
  is export
{ * }

sub shell_app_get_windows (ShellApp $app)
  returns GSList
  is native(gnome-shell)
  is export
{ * }

sub shell_app_is_on_workspace (ShellApp $app, MutterMetaWorkspace $workspace)
  returns uint32
  is native(gnome-shell)
  is export
{ * }

sub shell_app_is_window_backed (ShellApp $app)
  returns uint32
  is native(gnome-shell)
  is export
{ * }

sub shell_app_launch (
  ShellApp                $app,
  guint                   $timestamp,
  gint                    $workspace,
  ShellAppLaunchGpu       $gpu_pref,
  CArray[Pointer[GError]] $error
)
  returns uint32
  is native(gnome-shell)
  is export
{ * }

sub shell_app_launch_action (
  ShellApp $app,
  Str      $action_name,
  guint    $timestamp,
  gint     $workspace
)
  is native(gnome-shell)
  is export
{ * }

sub shell_app_open_new_window (ShellApp $app, gint $workspace)
  is native(gnome-shell)
  is export
{ * }

sub shell_app_request_quit (ShellApp $app)
  returns uint32
  is native(gnome-shell)
  is export
{ * }

sub shell_app_update_app_actions (ShellApp $app, MutterMetaWindow $window)
  is native(gnome-shell)
  is export
{ * }

sub shell_app_update_window_actions (ShellApp $app, MutterMetaWindow $window)
  is native(gnome-shell)
  is export
{ * }
