use v6.c;

use Method::Also;

use NativeCall;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;

use GLib::GList;
use Mutter::Meta::Startup;
use Gnome::Shell::App;

use GLib::Roles::Object;
use GLib::Roles::Implementor;

our subset ShellWindowTrackerAncestry is export of Mu
  where ShellWindowTracker | GObject;

class Gnome::Shell::WindowTracker {
  also does GLib::Roles::Object;

  has ShellWindowTracker $!swt is implementor;

  submethod BUILD ( :$shell-window-tracker ) {
    self.setShellWindowTracker($shell-window-tracker)
      if $shell-window-tracker
  }

  method setShellWindowTracker (ShellWindowTrackerAncestry $_) {
    my $to-parent;

    $!swt = do {
      when ShellWindowTracker {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellWindowTracker, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::ShellWindowTracker
    is also<ShellWindowTracker>
  { $!swt }

  method new (
    ShellWindowTrackerAncestry  $shell-window-tracker,
                               :$ref                   = True
  ) {
    return unless $shell-window-tracker;

    my $o = self.bless( :$shell-window-tracker );
    $o.ref if $ref;
    $o;
  }

  # Type: ShellApp
  method focus-app ( :$raw = False ) is rw  is g-property is also<focus_app> {
    my $gv = GLib::Value.new( Gnome::Shell:: );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('focus-app', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Gnome::Shell::App.getTypePair
        );
      },
      STORE => -> $,  $val is copy {
        warn 'focus-app does not allow writing'
      }
    );
  }

  method startup-sequence-changed is also<startup_sequence_changed> {
    self.connect-startup-sequence-changed($!swt);
  }

  method tracked-windows-changed is also<tracked_windows_changed> {
    self.connect($!swt, 'tracked-windows-changed');
  }

  method get_app_from_pid (Int() $pid, :$raw = False)
    is also<get-app-from-pid>
  {
    my gint $p = $pid;

    propReturnObject(
      shell_window_tracker_get_app_from_pid($!swt, $p),
      $raw,
      |Gnome::Shell::App.getTypePair
    );
  }

  method get_default is also<get-default> {
    my $shell-window-tracker = shell_window_tracker_get_default();

    $shell-window-tracker ?? self.bless( :$shell-window-tracker ) !! Nil;
  }

  method get_startup_sequences ( :$raw = False, :$glist = False )
    is also<get-startup-sequences>
  {
    returnGList(
      shell_window_tracker_get_startup_sequences($!swt),
      $raw,
      $glist,
      |Mutter::Meta::StartupSequences.getTypePair
    );
  }

  method get_window_app (MutterMetaWindow() $metawin, :$raw = False)
    is also<get-window-app>
  {
    propReturnObject(
      shell_window_tracker_get_window_app($!swt, $metawin),
      $raw,
      |Gnome::Shell::App.getTypePair
    );
  }

  method get_type is also<get-type> {
    state ($n, $t);

    unstable_get_type( self.^name, &shell_window_tracker_get_type, $n, $t );
  }

}


### /home/cbwood/Projects/gnome-shell/src/shell-window-tracker.h

sub shell_window_tracker_get_app_from_pid (
  ShellWindowTracker $tracker,
  gint               $pid
)
  returns ShellApp
  is native(gnome-shell)
  is export
{ * }

sub shell_window_tracker_get_default ()
  returns ShellWindowTracker
  is native(gnome-shell)
  is export
{ * }

sub shell_window_tracker_get_type
  returns GType
  is native(gnome-shell)
  is export
{ * }

sub shell_window_tracker_get_startup_sequences (ShellWindowTracker $tracker)
  returns GSList
  is native(gnome-shell)
  is export
{ * }

sub shell_window_tracker_get_window_app (
  ShellWindowTracker $tracker,
  MutterMetaWindow   $metawin
)
  returns ShellApp
  is native(gnome-shell)
  is export
{ * }
