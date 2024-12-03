use v6.c;

use Method::Also;

use Gnome::Shell::Raw::Types;

use GLib::Roles::Object;
use GLib::Roles::Implementor;

our subset ShellCameraMonitorAncestry is export of Mu
  where ShellCameraMonitor | GObject;

class Gnome::Shell::CameraMonitor {
  also does GLib::Roles::Object;

  has ShellCameraMonitor $!scm is implementor;

  submethod BUILD ( :$shell-cam-mon ) {
    self.setShellCameraMonitor($shell-cam-mon) if $shell-cam-mon
  }

  method setShellCameraMonitor (ShellCameraMonitorAncestry $_) {
    my $to-parent;

    $!scm = do {
      when ShellCameraMonitor {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellCameraMonitor, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::ShellCameraMonitor
    is also<ShellCameraMonitor>
  { $!scm }

  multi method new (
    $shell-cam-mon where * ~~ ShellCameraMonitorAncestry,
    :$ref                                                 = True
  ) {
    return unless $shell-cam-mon;

    my $o = self.bless( :$shell-cam-mon );
    $o.ref if $ref;
    $o;
  }

  # Type: boolean
  method cameras-in-use is rw  is g-property is also<cameras_in_use> {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('cameras-in-use', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        warn 'cameras-in-use does not allow writing'
      }
    );
  }

  method get_type is also<get-type> {
    state ($n, $t);

    unstable_get_type( self.^name, &shell_camera_monitor_get_type, $n, $t );
  }

}

sub shell_camera_monitor_get_type
  returns GType
  is      native(gnome-shell)
  is      export
{ * }
