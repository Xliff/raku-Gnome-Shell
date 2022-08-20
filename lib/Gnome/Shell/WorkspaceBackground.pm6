use v6.c;

use Method::Also;
use NativeCall;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;
use Gnome::Shell::St::Widget;

use GLib::Roles::Implementor;

our subset ShellWorkspaceBackgroundAncestry is export of Mu
  where ShellWorkspaceBackground | StWidgetAncestry;

class Gnome::Shell::WorkspaceBackground {
  has ShellWorkspaceBackground $!swb is implementor;

  submethod BUILD ( :$shell-workspace-background ) {
    self.setShellWorkspaceBackground($shell-workspace-background)
      if $shell-workspace-background
  }

  method setShellWorkspaceBackground (ShellWorkspaceBackgroundAncestry $_) {
    my $to-parent;

    $!swb = do {
      when ShellWorkspaceBackground {
        $to-parent = cast(StWidget, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellWorkspaceBackground, $_);
      }
    }
    self.setStWidget($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::ShellWorkspaceBackground
    is also<ShellWorkspaceBackground>
  { $!swb }

  multi method new (
    ShellWorkspaceBackgroundAncestry  $shell-workspace-background,
                                     :$ref                         = True
  ) {
    return unless $shell-workspace-background;

    my $o = self.bless( :$shell-workspace-background );
    $o.ref if $ref;
    $o;
  }

  # Type: int
  method monitor-index is rw  is g-property is also<monitor_index> {
    my $gv = GLib::Value.new( G_TYPE_INT );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('monitor-index', $gv);
        $gv.int;
      },
      STORE => -> $, Int() $val is copy {
        $gv.int = $val;
        self.prop_set('monitor-index', $gv);
      }
    );
  }

  # Type: double
  method state-adjustment-value
    is rw
    is g-property
    is also<state_adjustment_value>
  {
    my $gv = GLib::Value.new( G_TYPE_DOUBLE );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('state-adjustment-value', $gv);
        $gv.double;
      },
      STORE => -> $, Num() $val is copy {
        $gv.double = $val;
        self.prop_set('state-adjustment-value', $gv);
      }
    );
  }

  method get_type is static is also<get-type> {
    state ($n, $t);

    unstable_get_type(
      self.^name,
      &shell_workspace_background_get_type,
      $n,
      $t
    )
  }

}

### /home/cbwood/Projects/gnome-shell/src/shell-workspace-background.h
sub shell_workspace_background_get_type
  returns GType
  is export
  is native(gnome-shell)
{ * }
