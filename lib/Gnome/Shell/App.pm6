use v6.c;

use Method::Also;
use NativeCall;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::App;

use GLib::GSList;

use GIO::Roles::ActionGroup;
use GIO::Roles::Icon;
use GLib::Roles::Implementor;
use GLib::Roles::Object;

our subset ShellAppAncestry is export of Mu
  where ShellApp | GObject;

class Gnome::Shell::App {
  also does GLib::Roles::Object;

  has ShellApp $!sa is implementor;

  submethod BUILD ( :$shell-app ) {
    self.setShellApp($shell-app) if $shell-app;
  }

  method setShellApp (ShellAppAncestry $_) {
    my $to-parent;

    $!sa = do {
      when ShellApp {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellApp, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::ShellApp
    is also<ShellApp>
  { $!sa }

  multi method new (ShellAppAncestry $shell-app, :$ref = True) {
    return unless $shell-app;

    my $o = self.bless( :$shell-app );
    $o.ref if $ref;
    $o;
  }

  # Type: ShellAppState
  method state is rw  is g-property {
    my $gv = GLib::Value.new( GLib::Value.typeFromEnum(ShellAppState) );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('state', $gv);
        ShellAppStateEnum( $gv.valueFromEnum(ShellAppState) );
      },
      STORE => -> $,  $val is copy {
        warn 'state does not allow writing'
      }
    );
  }

  # Type: boolean
  method busy is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('busy', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        warn 'busy does not allow writing'
      }
    );
  }

  # Type: string
  method id is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_STRING );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('id', $gv);
        $gv.string;
      },
      STORE => -> $, Str() $val is copy {
        warn 'id does not allow writing'
      }
    );
  }

  # Type: GIcon
  method icon ( :$raw = False ) is rw  is g-property {
    my $gv = GLib::Value.new( GIO::Icon.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('icon', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |GIO::Icon.getTypePair
        );
      },
      STORE => -> $,  $val is copy {
        warn 'icon does not allow writing'
      }
    );
  }

  # Type: GActionGroup
  method action-group ( :$raw = False )
    is rw
    is g-property
    is also<action_group>
  {
    my $gv = GLib::Value.new( GIO::ActionGroup.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('action-group', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |GIO::ActionGroup.getTypePair
        );
      },
      STORE => -> $,  $val is copy {
        warn 'action-group does not allow writing'
      }
    );
  }

  # Type: GDesktopAppInfo
  method app-info ( :$raw = False ) is rw  is g-property is also<app_info> {
    my $gv = GLib::Value.new( GIO::DesktopAppInfo.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('app-info', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |GIO::DesktopAppInfo.getTypePair
        );
      },
      STORE => -> $, GDesktopAppInfo() $val is copy {
        $gv.StDesktopAppInfo = $val;
        self.prop_set('app-info', $gv);
      }
    );
  }

  method windows-changed is also<windows_changed> {
    self.connect($!sa, 'windows-changed');
  }

  method activate {
    shell_app_activate($!sa);
  }

  method activate_full (Int() $workspace, Int() $timestamp) is also<activate-full> {
    my gint    $w = $workspace;
    my guint32 $t = $timestamp;

    shell_app_activate_full($!sa, $w, $t);
  }

  method activate_window (MutterMetaWindow() $window, Int() $timestamp) is also<activate-window> {
    my guint32 $t = $timestamp;

    shell_app_activate_window($!sa, $window, $timestamp);
  }

  method can_open_new_window is also<can-open-new-window> {
    shell_app_can_open_new_window($!sa);
  }

  method compare (ShellApp() $other) {
    shell_app_compare($!sa, $other);
  }

  method compare_by_name (ShellApp() $other) is also<compare-by-name> {
    shell_app_compare_by_name($!sa, $other);
  }

  method create_icon_texture (Int() $size, :$raw = False) is also<create-icon-texture> {
    my gint $s = $size;

    propReturnObject(
      shell_app_create_icon_texture($!sa, $s),
      $raw,
      |Mutter::Clutter::Actor.getTypePair
    );
  }

  method get_app_info ( :$raw = False ) is also<get-app-info> {
    propReturnObject(
      shell_app_get_app_info($!sa),
      $raw,
      |GIO::DesktopAppInfo.getTypePair
    );
  }

  method get_busy is also<get-busy> {
    shell_app_get_busy($!sa);
  }

  method get_description is also<get-description> {
    shell_app_get_description($!sa);
  }

  method get_icon ( :$raw = False ) is also<get-icon> {
    propReturnObject(
      shell_app_get_icon($!sa),
      $raw,
      |GIO::Icon.getTypePair
    );
  }

  method get_id is also<get-id> {
    shell_app_get_id($!sa);
  }

  method get_n_windows is also<get-n-windows> {
    shell_app_get_n_windows($!sa);
  }

  method get_name is also<get-name> {
    shell_app_get_name($!sa);
  }

  method get_pids ( :$raw = False, :$glist = False ) is also<get-pids> {
    returnGSList(
      shell_app_get_pids($!sa),
      False,
      $glist,
      Int
    );
  }

  method get_state is also<get-state> {
    shell_app_get_state($!sa);
  }

  method get_windows ( :$raw = False, :$glist = False ) is also<get-windows> {
    returnGSList(
      shell_app_get_windows($!sa),
      $raw,
      $glist,
      |Mutter::Meta::Window.getTypePair
    );
  }

  method is_on_workspace (MutterMetaWorkspace() $workspace) is also<is-on-workspace> {
    so shell_app_is_on_workspace($!sa, $workspace);
  }

  method is_window_backed is also<is-window-backed> {
    so shell_app_is_window_backed($!sa);
  }

  method launch (
    Int()                   $timestamp,
    Int()                   $workspace,
    Int()                   $gpu_pref,
    CArray[Pointer[GError]] $error      = gerror
  ) {
    my ShellAppLaunchGpu $g = $gpu_pref;
    my gint              $w = $workspace;
    my guint             $t = $timestamp;

    clear_error;
    my $lrv = shell_app_launch($!sa, $t, $w, $g, $error);
    set_error($error);
  }

  method launch_action (
    Str() $action_name,
    Int() $timestamp,
    Int() $workspace
  )
    is also<launch-action>
  {
    my gint  $w = $workspace;
    my guint $t = $timestamp;

    shell_app_launch_action($!sa, $action_name, $t, $w);
  }

  method open_new_window (Int() $workspace) is also<open-new-window> {
    my gint $w = $workspace;

    shell_app_open_new_window($!sa, $workspace);
  }

  method request_quit is also<request-quit> {
    shell_app_request_quit($!sa);
  }

  method update_app_actions (MutterMetaWindow() $window) is also<update-app-actions> {
    shell_app_update_app_actions($!sa, $window);
  }

  method update_window_actions (MutterMetaWindow() $window) is also<update-window-actions> {
    shell_app_update_window_actions($!sa, $window);
  }

}
