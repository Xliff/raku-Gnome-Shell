use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use GLib::Raw::Structs;
use GIO::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;

unit package Gnome::Shell::Raw::PerfLog;

### /home/cbwood/Projects/gnome-shell/src/shell-perf-log.h

sub shell_perf_log_add_statistics_callback (
  ShellPerfLog $perf_log,
               &callback (ShellPerfLog, gpointer),
  gpointer     $user_data,
               &notify (gpointer)
)
  is native(gnome-shell)
  is export
{ * }

sub shell_perf_log_collect_statistics (ShellPerfLog $perf_log)
  is native(gnome-shell)
  is export
{ * }

sub shell_perf_log_define_event (
  ShellPerfLog $perf_log,
  Str          $name,
  Str          $description,
  Str          $signature
)
  is native(gnome-shell)
  is export
{ * }

sub shell_perf_log_define_statistic (
  ShellPerfLog $perf_log,
  Str          $name,
  Str          $description,
  Str          $signature
)
  is native(gnome-shell)
  is export
{ * }

sub shell_perf_log_dump_events (
  ShellPerfLog            $perf_log,
  GOutputStream           $out,
  CArray[Pointer[GError]] $error
)
  returns uint32
  is native(gnome-shell)
  is export
{ * }

sub shell_perf_log_dump_log (
  ShellPerfLog            $perf_log,
  GOutputStream           $out,
  CArray[Pointer[GError]] $error
)
  returns uint32
  is native(gnome-shell)
  is export
{ * }

sub shell_perf_log_event (ShellPerfLog $perf_log, Str $name)
  is native(gnome-shell)
  is export
{ * }

sub shell_perf_log_event_i (ShellPerfLog $perf_log, Str $name, gint32 $arg)
  is native(gnome-shell)
  is export
{ * }

sub shell_perf_log_event_s (ShellPerfLog $perf_log, Str $name, Str $arg)
  is native(gnome-shell)
  is export
{ * }

sub shell_perf_log_event_x (ShellPerfLog $perf_log, Str $name, gint64 $arg)
  is native(gnome-shell)
  is export
{ * }

sub shell_perf_log_get_default ()
  returns ShellPerfLog
  is native(gnome-shell)
  is export
{ * }

sub shell_perf_log_replay (
  ShellPerfLog $perf_log,
  &replay_function (
    gint64,
    Str,
    Str,
    GValue,
    gpointer
  ),
  gpointer $user_data
)
  is native(gnome-shell)
  is export
{ * }

sub shell_perf_log_set_enabled (ShellPerfLog $perf_log, gboolean $enabled)
  is native(gnome-shell)
  is export
{ * }

sub shell_perf_log_update_statistic_i (
  ShellPerfLog $perf_log,
  Str          $name,
  gint         $value
)
  is native(gnome-shell)
  is export
{ * }

sub shell_perf_log_update_statistic_x (
  ShellPerfLog $perf_log,
  Str          $name,
  gint64       $value
)
  is native(gnome-shell)
  is export
{ * }
