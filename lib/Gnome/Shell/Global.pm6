use v6.c;

use Method::Also;

use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::Global;

use GIO::LaunchContext;
use GIO::Settings;
use Mutter::Clutter::Stage;
use Mutter::Meta::Display;
use Mutter::Meta::WorkspaceManager;

use GLib::Roles::Implementor;

our subset ShellGlobalAncestry is export of Mu
  where ShellGlobal | GObject;

class Gnome::Shell::Global {
  has ShellGlobal $!sg is implementor;

  submethod BUILD ( :$shell-global ) {
    self.setShellGlobal($shell-global) if $shell-global
  }

  method setShellGlobal (ShellGlobalAncestry $_) {
    my $to-parent;

    $!sg = do {
      when ShellGlobal {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellGlobal, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::ShellGlobal
    is also<ShellGlobal>
  { $!sg }

  multi method new (ShellGlobalAncestry $shell-global, :$ref = True) {
    return unless $shell-global;

    my $o = self.bless( :$shell-global );
    $o.ref if $ref;
    $o;
  }

  method get {
    my $shell-global = shell_global_get();

    $shell-global ?? self.bless( :$shell-global ) !! Nil
  }

  method begin_work is also<begin-work> {
    shell_global_begin_work($!sg);
  }

  method create_app_launch_context (
    Int()  $timestamp,
    Int()  $workspace,
          :$raw        = False
  )
    is also<create-app-launch-context>
  {
    my guint32 $t = $timestamp;
    my gint    $w = $workspace;

    propReturnObject(
      shell_global_create_app_launch_context($!sg, $t, $w),
      $raw,
      |GIO::LaunchContext.getTypePair
    );
  }

  method end_work is also<end-work> {
    shell_global_end_work($!sg);
  }

  method get_current_time is also<get-current-time> {
    shell_global_get_current_time($!sg);
  }

  method get_display ( :$raw = False ) is also<get-display> {
    propReturnObject(
      shell_global_get_display($!sg),
      $raw,
      |Mutter::Meta::Display.getTypePair
    );
  }

  method get_persistent_state (Str() $property_type, Str() $property_name)
    is also<get-persistent-state>
  {
    shell_global_get_persistent_state($!sg, $property_type, $property_name);
  }

  proto method get_pointer (|)
    is also<get-pointer>
  { * }

  multi method get_pointer {
    samewith($, $, $);
  }
  multi method get_pointer ($x is rw, $y is rw, $mods is rw) {
    my gint                ($xx, $yu) = 0 xx 2;
    my ClutterModifierType  $m        = 0;

    shell_global_get_pointer($!sg, $xx, $yy, $m);
    ($x, $y, $mods) = ($xx, $yy, $m);
  }

  method get_runtime_state (Str() $property_type, Str() $property_name)
    is also<get-runtime-state>
  {
    shell_global_get_runtime_state($!sg, $property_type, $property_name);
  }

  method get_session_mode is also<get-session-mode> {
    shell_global_get_session_mode($!sg);
  }

  method get_settings ( :$raw = False ) is also<get-settings> {
    propReturnObject(
      shell_global_get_settings($!sg),
      $raw,
      |GIO::Settings.getTypePair
    );
  }

  method get_stage ( :$raw = False )  is also<get-stage> {
    propReturnObject(
      shell_global_get_stage($!sg),
      $raw,
      |Mutter::Clutter::Stage.getTypePair
    );
  }

  method get_switcheroo_control is also<get-switcheroo-control> {
    shell_global_get_switcheroo_control($!sg);
  }

  method get_window_actors is also<get-window-actors> {
    shell_global_get_window_actors($!sg);
  }

  method get_workspace_manager ( :$raw = False )
    is also<get-workspace-manager>
  {
    propReturnObject(
      shell_global_get_workspace_manager($!sg),
      $raw,
      |Mutter::Meta::WorkspaceManager.getTypePair
    );
  }

  method notify_error (Str() $msg, Str() $details) is also<notify-error> {
    shell_global_notify_error($!sg, $msg, $details);
  }

  method reexec_self is also<reexec-self> {
    shell_global_reexec_self($!sg);
  }

  method run_at_leisure (
             &func,
    gpointer $user_data  = gpointer,
             &notify     = %DEFAULT-HANDLERS<GDestroyNotify>
  )
    is also<run-at-leisure>
  {
    shell_global_run_at_leisure($!sg, &func, $user_data, &notify);
  }

  method set_persistent_state (Str() $property_name, GVariant() $variant)
    is also<set-persistent-state>
  {
    shell_global_set_persistent_state($!sg, $property_name, $variant);
  }

  method set_runtime_state (Str() $property_name, GVariant() $variant)
    is also<set-runtime-state>
  {
    shell_global_set_runtime_state($!sg, $property_name, $variant);
  }

  method set_stage_input_region (GSList() $rectangles)
    is also<set-stage-input-region>
  {
    shell_global_set_stage_input_region($!sg, $rectangles);
  }

}
