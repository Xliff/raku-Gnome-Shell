use v6.c;

use Method::Also;

use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::Global;

use GLib::Raw::Traits;
use GIO::LaunchContext;
use GIO::Settings;
use Mutter::Clutter::Stage;
use Mutter::Meta::Display;
use Mutter::Meta::Workspace::Manager;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

our subset ShellGlobalAncestry is export of Mu
  where ShellGlobal | GObject;

class Gnome::Shell::Global {
  also does GLib::Roles::Object;

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

  # Type: string
  method session-mode is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_STRING );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('session-mode', $gv);
        $gv.string;
      },
      STORE => -> $, Str() $val is copy {
        $gv.string = $val;
        self.prop_set('session-mode', $gv);
      }
    );
  }

  # Type: int
  method screen-width is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_INT );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('screen-width', $gv);
        $gv.int;
      },
      STORE => -> $, Int() $val is copy {
        warn 'screen-width does not allow writing'
      }
    );
  }

  # Type: int
  method screen-height is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_INT );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('screen-height', $gv);
        $gv.int;
      },
      STORE => -> $, Int() $val is copy {
        warn 'screen-height does not allow writing'
      }
    );
  }

  # Type: MutterMetaBackend
  method backend ( :$raw = False ) is rw  is g-property {
    my $gv = GLib::Value.new( Mutter::Meta::Backend.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('backend', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Mutter::Meta::Backend.getTypePair
        )
      },
      STORE => -> $,  $val is copy {
        warn 'backend does not allow writing'
      }
    );
  }

  # Type: MutterMetaContext
  method context ( :$raw = False ) is rw  is g-property {
    my $gv = GLib::Value.new( Mutter::Meta::Context.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('context', $gv);
        propReturnObject(
          $gv.StContext,
          $raw,
          |Mutter::Meta::Context.getTypePair
        );
      },
      STORE => -> $,  $val is copy {
        warn 'context does not allow writing'
      }
    );
  }

  # Type: MutterMetaDisplay
  method display ( :$raw = False ) is rw  is g-property {
    my $gv = GLib::Value.new( Mutter::Meta::Display.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('display', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Mutter::Meta::Display.getTypePair
        );
      },
      STORE => -> $,  $val is copy {
        warn 'display does not allow writing'
      }
    );
  }

  # Type: MutterMetaWorkspaceManager
  method workspace-manager ( :$raw = False ) is rw  is g-property {
    my $gv = GLib::Value.new( Mutter::Meta::WorkspaceManager.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('workspace-manager', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Mutter::Meta::WorkspaceManager.getTypePair
        );
      },
      STORE => -> $,  $val is copy {
        warn 'workspace-manager does not allow writing'
      }
    );
  }

  # Type: MutterClutterActor
  method stage ( :$raw = False ) is rw  is g-property {
    my $gv = GLib::Value.new( Mutter::Clutter::Actor.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('stage', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Mutter::Clutter::Actor.getTypePair
        );
      },
      STORE => -> $,  $val is copy {
        warn 'stage does not allow writing'
      }
    );
  }

  # Type: MutterClutterActor
  method window-group ( :$raw = False ) is rw  is g-property {
    my $gv = GLib::Value.new( Mutter::Clutter::Actor.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('window-group', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Mutter::Clutter::Actor.getTypePair
        );
      },
      STORE => -> $,  $val is copy {
        warn 'window-group does not allow writing'
      }
    );
  }

  # Type: MutterClutterActor
  method top-window-group ( :$raw = False ) is rw  is g-property {
    my $gv = GLib::Value.new( Mutter::Clutter::Actor.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('top-window-group', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Mutter::Clutter::Actor.getTypePair
        )
      },
      STORE => -> $,  $val is copy {
        warn 'top-window-group does not allow writing'
      }
    );
  }

  # Type: ShellWm
  method window-manager ( :$raw = False ) is rw  is g-property {
    my $gv = GLib::Value.new( Gnome::Shell::Wm.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('window-manager', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Gnome::Shell::Wm.getTypePair
        );
      },
      STORE => -> $,  $val is copy {
        warn 'window-manager does not allow writing'
      }
    );
  }

  # Type: GSettings
  method settings ( :$raw = False ) is rw  is g-property {
    my $gv = GLib::Value.new( GIO::Settings.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('settings', $gv);
        propReturnObject(
          $gv.StSettings,
          $raw,
          |GIO::Settings.getTypePair
        );
      },
      STORE => -> $,  $val is copy {
        warn 'settings does not allow writing'
      }
    );
  }

  # Type: string
  method datadir is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_STRING );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('datadir', $gv);
        $gv.string;
      },
      STORE => -> $, Str() $val is copy {
        warn 'datadir does not allow writing'
      }
    );
  }

  # Type: string
  method imagedir is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_STRING );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('imagedir', $gv);
        $gv.string;
      },
      STORE => -> $, Str() $val is copy {
        warn 'imagedir does not allow writing'
      }
    );
  }

  # Type: string
  method userdatadir is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_STRING );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('userdatadir', $gv);
        $gv.string;
      },
      STORE => -> $, Str() $val is copy {
        warn 'userdatadir does not allow writing'
      }
    );
  }

  # Type: StFocusManager
  method focus-manager ( :$raw = False ) is rw  is g-property {
    my $gv = GLib::Value.new( Gnome::Shell::St::FocusManager.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('focus-manager', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Gnome::Shell::St::FocusManager.getTypePair
        );
      },
      STORE => -> $,  $val is copy {
        warn 'focus-manager does not allow writing'
      }
    );
  }

  # Type: boolean
  method frame-timestamps is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('frame-timestamps', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        $gv.boolean = $val;
        self.prop_set('frame-timestamps', $gv);
      }
    );
  }

  # Type: boolean
  method frame-finish-timestamp is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('frame-finish-timestamp', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        $gv.boolean = $val;
        self.prop_set('frame-finish-timestamp', $gv);
      }
    );
  }

  # Type: GDbusProxy
  method switcheroo-control ( :$raw = False ) is rw  is g-property {
    my $gv = GLib::Value.new( GIO::DBus::Proxy.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('switcheroo-control', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |GIO::DBus::Proxy.getTypePair
        );
      },
      STORE => -> $,  $val is copy {
        warn 'switcheroo-control does not allow writing'
      }
    );
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

  method get_current_time
    is also<
      get-current-time
      current-time
      current_time
    >
  {
    shell_global_get_current_time($!sg);
  }

  method get_display ( :$raw = False )
    is also<
      get-display
      display
    >
  {
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

  multi method get_pointer is also<pointer> {
    samewith($, $, $);
  }
  multi method get_pointer ($x is rw, $y is rw, $mods is rw) {
    my gint                      ($xx, $yy) = 0 xx 2;
    my MutterClutterModifierType  $m        = 0;

    shell_global_get_pointer($!sg, $xx, $yy, $m);
    ($x, $y, $mods) = ($xx, $yy, $m);
  }

  method get_runtime_state (Str() $property_type, Str() $property_name)
    is also<get-runtime-state>
  {
    shell_global_get_runtime_state($!sg, $property_type, $property_name);
  }

  method get_session_mode
    is also<
      get-session-mode
      session-mode
      session_mode
    >
  {
    shell_global_get_session_mode($!sg);
  }

  method get_settings ( :$raw = False )
    is also<
      get-settings
      settings
    >
  {
    propReturnObject(
      shell_global_get_settings($!sg),
      $raw,
      |GIO::Settings.getTypePair
    );
  }

  method get_stage ( :$raw = False )
    is also<
      get-stage
      stage
    >
  {
    propReturnObject(
      shell_global_get_stage($!sg),
      $raw,
      |Mutter::Clutter::Stage.getTypePair
    );
  }

  method get_switcheroo_control
    is also<
      get-switcheroo-control
      switcheroo-control
      switcheroo_control
    >
  {
    shell_global_get_switcheroo_control($!sg);
  }

  method get_window_actors
    is also<
      get-window-actors
      window-actors
      window_actors
    >
  {
    shell_global_get_window_actors($!sg);
  }

  method get_workspace_manager ( :$raw = False )
    is also<
      get-workspace-manager
      workspace-manager
      workspace_manager
    >
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
             &notify     = %DEFAULT-CALLBACKS<GDestroyNotify>
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

  method scale-factor is also<scale_factor> {
    Gnome::Shell::St::ThemeContext.get_for_stage($.stage).scale_factor;
  }
  
}
