use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use GLib::Raw::Structs;
use GIO::Raw::Definitions;
use Mutter::Raw::Definitions;
use Mutter::Raw::Enums;
use Gnome::Shell::Raw::Definitions;

unit package Gnome::Shell::Raw::Global;

### /home/cbwood/Projects/gnome-shell/src/shell-global.h

sub shell_global_begin_work (ShellGlobal $global)
  is native(gnome-shell)
  is export
{ * }

sub shell_global_create_app_launch_context (
  ShellGlobal $global,
  guint32     $timestamp,
  gint        $workspace
)
  returns GAppLaunchContext
  is native(gnome-shell)
  is export
{ * }

sub shell_global_end_work (ShellGlobal $global)
  is native(gnome-shell)
  is export
{ * }

sub shell_global_get ()
  returns ShellGlobal
  is native(gnome-shell)
  is export
{ * }

sub shell_global_get_current_time (ShellGlobal $global)
  returns guint32
  is native(gnome-shell)
  is export
{ * }

sub shell_global_get_display (ShellGlobal $global)
  returns MutterMetaDisplay
  is native(gnome-shell)
  is export
{ * }

sub shell_global_get_persistent_state (
  ShellGlobal $global,
  Str         $property_type,
  Str         $property_name
)
  returns GVariant
  is native(gnome-shell)
  is export
{ * }

sub shell_global_get_pointer (
  ShellGlobal               $global,
  gint                      $x       is rw,
  gint                      $y       is rw,
  MutterClutterModifierType $mods
)
  is native(gnome-shell)
  is export
{ * }

sub shell_global_get_runtime_state (
  ShellGlobal $global,
  Str         $property_type,
  Str         $property_name
)
  returns GVariant
  is native(gnome-shell)
  is export
{ * }

sub shell_global_get_session_mode (ShellGlobal $global)
  returns Str
  is native(gnome-shell)
  is export
{ * }

sub shell_global_get_settings (ShellGlobal $global)
  returns GSettings
  is native(gnome-shell)
  is export
{ * }

sub shell_global_get_stage (ShellGlobal $global)
  returns MutterClutterStage
  is native(gnome-shell)
  is export
{ * }

sub shell_global_get_switcheroo_control (ShellGlobal $global)
  returns GDBusProxy
  is native(gnome-shell)
  is export
{ * }

sub shell_global_get_window_actors (ShellGlobal $global)
  returns GList
  is native(gnome-shell)
  is export
{ * }

sub shell_global_get_workspace_manager (ShellGlobal $global)
  returns MutterMetaWorkspaceManager
  is native(gnome-shell)
  is export
{ * }

sub shell_global_notify_error (ShellGlobal $global, Str $msg, Str $details)
  is native(gnome-shell)
  is export
{ * }

sub shell_global_reexec_self (ShellGlobal $global)
  is native(gnome-shell)
  is export
{ * }

sub shell_global_run_at_leisure (
  ShellGlobal $global,
              &func   (gpointer),
  gpointer    $user_data,
              &notify (gpointer)
)
  is native(gnome-shell)
  is export
{ * }

sub shell_global_set_persistent_state (
  ShellGlobal $global,
  Str         $property_name,
  GVariant    $variant
)
  is native(gnome-shell)
  is export
{ * }

sub shell_global_set_runtime_state (
  ShellGlobal $global,
  Str         $property_name,
  GVariant    $variant
)
  is native(gnome-shell)
  is export
{ * }

sub shell_global_set_stage_input_region (
  ShellGlobal $global,
  GSList      $rectangles
)
  is native(gnome-shell)
  is export
{ * }
