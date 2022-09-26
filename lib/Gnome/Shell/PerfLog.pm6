use v6.c;

use Method::Also;
use NativeCall;

use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::PerfLog;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

our subset ShellPerfLogAncestry is export of Mu
  where ShellPerfLog | GObject;

class Gnome::Shell::PerfLog {
  also does GLib::Roles::Object;

  has ShellPerfLog $!spl is implementor;

  submethod BUILD ( :$shell-perf-log ) {
    self.setShellPerfLog($shell-perf-log) if $shell-perf-log;
  }

  method setShellPerfLog (ShellPerfLogAncestry $_) {
    my $to-parent;

    $!spl = do {
      when ShellPerfLog {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellPerfLog, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Mutter::Cogl::Raw::Definitions::ShellPerfLog
    is also<ShellPerfLog>
  { $!spl }

  multi method new (ShellPerfLogAncestry $shell-perf-log, :$ref = True) {
    return unless $shell-perf-log;

    my $o = self.bless( :$shell-perf-log );
    $o.ref if $ref;
    $o;
  }
  multi method new {
    self.get_default;
  }

  method get_default is also<get-default> {
    my $shell-perf-log = shell_perf_log_get_default();

    $shell-perf-log ?? self.bless( :$shell-perf-log ) !! Nil;
  }

  method add_statistics_callback (
             &callback,
    gpointer $user_data = gpointer,
             &notify    = %DEFAULT-CALLBACKS<GDestroyNotify>
  )
    is also<add-statistics-callback>
  {
    shell_perf_log_add_statistics_callback(
      $!spl,
      &callback,
      $user_data,
      &notify
    );
  }

  method collect_statistics is also<collect-statistics> {
    shell_perf_log_collect_statistics($!spl);
  }

  method define_event (Str() $name, Str() $description, Str() $signature)
    is also<define-event>
  {
    shell_perf_log_define_event($!spl, $name, $description, $signature);
  }

  method define_statistic (Str() $name, Str() $description, Str() $signature)
    is also<define-statistic>
  {
    shell_perf_log_define_statistic($!spl, $name, $description, $signature);
  }

  method dump_events (
    GOutputStream()         $out,
    CArray[Pointer[GError]] $error = gerror
  )
    is also<dump-events>
  {
    clear_error;
    my $mrv = shell_perf_log_dump_events($!spl, $out, $error);
    set_error($error);
    $mrv;
  }

  method dump_log (
    GOutputStream()         $out,
    CArray[Pointer[GError]] $error = gerror
  )
    is also<dump-log>
  {
    clear_error;
    my $mrv = shell_perf_log_dump_log($!spl, $out, $error);
    set_error($error);
    $mrv;
  }

  method event (Str() $name) {
    shell_perf_log_event($!spl, $name);
  }

  method event_i (Str() $name, Int() $arg) is also<event-i> {
    my gint32 $a = $arg;

    shell_perf_log_event_i($!spl, $name, $a);
  }

  method event_s (Str() $name, Str() $arg) is also<event-s> {
    shell_perf_log_event_s($!spl, $name, $arg);
  }

  method event_x (Str $name, Int() $arg) is also<event-x> {
    my gint64 $a = $arg;

    shell_perf_log_event_x($!spl, $name, $a);
  }

  method replay (&replay_function, gpointer $user_data = gpointer) {
    shell_perf_log_replay($!spl, &replay_function, $user_data);
  }

  method set_enabled (Int() $enabled) is also<set-enabled> {
    my gboolean $e = $enabled.so.Int;

    shell_perf_log_set_enabled($!spl, $e);
  }

  method update_statistic_i (Str() $name, Int() $value)
    is also<update-statistic-i>
  {
    my gint $v = $value;

    shell_perf_log_update_statistic_i($!spl, $name, $v);
  }

  method update_statistic_x (Str() $name, Int() $value)
    is also<update-statistic-x>
  {
    my gint64 $v = $value;

    shell_perf_log_update_statistic_x($!spl, $name, $v);
  }

}
