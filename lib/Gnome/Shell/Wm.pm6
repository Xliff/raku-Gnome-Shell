use v6.c;

use Method::Also;

use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::Wm;

use GLib::Roles::Implementor;
use GLib::Roles::Object;
use Gnome::Shell::Roles::Signals::Wm;

our subset ShellWmAncestry is export of Mu
  where ShellWM | GObject;

class Gnome::Shell::Wm {
  also does GLib::Roles::Object;
  also does Gnome::Shell::Roles::Signals::Wm;

  has ShellWM $!swm is implementor;

  submethod BUILD ( :$shell-wm ) {
    self.setShellWm($shell-wm) if $shell-wm;
  }

  method setShellWm (ShellWmAncestry $_) {
    my $to-parent;

    $!swm = do {
      when ShellWM {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellWM, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Mutter::Cogl::Raw::Definitions::ShellWm
    is also<ShellWm>
  { $!swm }

  multi method new (ShellWmAncestry $shell-wm, :$ref = True) {
    return unless $shell-wm;

    my $o = self.bless( :$shell-wm );
    $o.ref if $ref;
    $o;
  }
  multi method new (MutterMetaPlugin() $plugin) {
    my $shell-wm = shell_wm_new($plugin);

    $shell-wm ?? self.bless( :$shell-wm ) !! Nil;
  }

  # Is originally:
  # ShellWM *wm,  MutterMetaWindow *window --> MutterMetaInhibitShortcutsDialog *
  method create-inhibit-shortcuts-dialog
    is also<create_inhibit_shortcuts_dialog>
  {
    self.connect-create-inhibit-shortcuts-dialog($!swm);
  }

  # Is originally:
  # ShellWM *wm --> void
  method kill-switch-workspace is also<kill_switch_workspace> {
    self.connect($!swm, 'kill-switch-workspace');
  }

  # Is originally:
  # ShellWM *wm,  MutterMetaWindowActor *actor --> void
  method size-changed is also<size_changed> {
    self.connect-window-actor($!swm, 'size-changed');
  }

  # Is originally:
  # ShellWM *wm,  MutterMetaWindowActor *actor --> void
  method minimize {
    self.connect-window-actor($!swm, 'minimize');
  }

  # Is originally:
  # ShellWM *wm,  MutterMetaWindowActor *actor --> void
  method destroy {
    self.connect-window-actor($!swm, 'destroy');
  }

  # Is originally:
  # ShellWM *wm,  MutterMetaWindow *window,  MutterMetaRectangle *tile_rect,  int tile_monitor --> void
  method show-tile-preview is also<show_tile_preview> {
    self.connect-show-tile-preview($!swm);
  }

  # Is originally:
  # ShellWM *wm,  MutterMetaWindowActor *actor --> void
  method kill-window-effects is also<kill_window_effects> {
    self.connect-window-actor($!swm, 'method');
  }

  # Is originally:
  # ShellWM *wm --> void
  method hide-tile-preview is also<hide_tile_preview> {
    self.connect($!swm, 'hide-tile-preview');
  }

  # Is originally:
  # ShellWM *wm,  MutterMetaWindowActor *actor,  MutterMetaSizeChange which_change,  MutterMetaRectangle *old_frame_rect,  MutterMetaRectangle *old_buffer_rect --> void
  method size-change is also<size_change> {
    self.connect-size-change($!swm);
  }

  # Is originally:
  # ShellWM *wm,  MutterMetaWindow *window,  MutterMetaWindowMenuType menu,  int x,  int y --> void
  method show-window-menu is also<show_window_menu> {
    self.connect-show-window-menu($!swm);
  }

  # Is originally:
  # ShellWM *wm,  gint from,  gint to,  MutterMetaMotionDirection direction --> void
  method switch-workspace is also<switch_workspace> {
    self.connect-switch-workspace($!swm);
  }

  # Is originally:
  # ShellWM *wm --> void
  method confirm-display-change is also<confirm_display_change> {
    self.connect($!swm, 'confirm-display-change');
  }

  # Is originally:
  # ShellWM *wm,  MutterMetaWindowActor *actor --> void
  method map {
    self.connect-window-actor($!swm, 'map');
  }

  # Is originally:
  # ShellWM *wm,  MutterMetaKeyBinding *binding --> gboolean
  method filter-keybinding is also<filter_keybinding> {
    self.connect-keybinding($!swm, 'filter-keybinding');
  }

  # Is originally:
  # ShellWM *wm,  MutterMetaWindowActor *actor --> void
  method unminimize {
    self.connect-window-actor($!swm, 'unminimize');
  }

  # Is originally:
  # ShellWM *wm,  MutterMetaWindow *window --> MutterMetaCloseDialog *
  method create-close-dialog is also<create_close_dialog> {
    self.connect-create-close-dialog($!swm);
  }

  method emit_complete_display_change (Int() $ok)
    is also<emit-complete-display-change>
  {
    my gboolean $o = $ok.so.Int;

    shell_wm_complete_display_change($!swm, $o);
  }

  method emit_completed_destroy (MutterMetaWindowActor() $actor)
    is also<emit-completed-destroy>
  {
    shell_wm_completed_destroy($!swm, $actor);
  }

  method emit_completed_map (MutterMetaWindowActor() $actor)
    is also<emit-completed-map>
  {
    shell_wm_completed_map($!swm, $actor);
  }

  method emit_completed_minimize (MutterMetaWindowActor() $actor)
    is also<emit-completed-minimize>
  {
    shell_wm_completed_minimize($!swm, $actor);
  }

  method emit_completed_size_change (MutterMetaWindowActor() $actor)
    is also<emit-completed-size-change>
  {
    shell_wm_completed_size_change($!swm, $actor);
  }

  method emit_completed_switch_workspace
    is also<emit-completed-switch-workspace>
  {
    shell_wm_completed_switch_workspace($!swm);
  }

  method emit_completed_unminimize (MutterMetaWindowActor() $actor)
    is also<emit-completed-unminimize>
  {
    shell_wm_completed_unminimize($!swm, $actor);
  }

}
