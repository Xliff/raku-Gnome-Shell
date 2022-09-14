use v6.c;

use Method::Also;
use NativeCall;

use Gnome::Shell::Raw::Types;

use GLib::GList;
use Mutter::Clutter::Actor;
use Mutter::Clutter::LayoutManager;
use Mutter::Meta::Window;

use GLib::Roles::Implementor;

our subset ShellWindowPreviewLayoutAncestry is export of Mu
  where ShellWindowPreviewLayout | MutterClutterLayoutManagerAncestry;

class Gnome::Shell::WindowPreviewLayout is Mutter::Clutter::LayoutManager {
  has ShellWindowPreviewLayout $!swpl is implementor;

  submethod BUILD ( :$shell-window-preview-layout ) {
    self.setShellWindowPreviewLayout($shell-window-preview-layout)
      if $shell-window-preview-layout
  }

  method setShellWindowPreviewLayout (ShellWindowPreviewLayoutAncestry $_) {
    my $to-parent;

    $!swpl = do {
      when ShellWindowPreviewLayout {
        $to-parent = cast(MutterClutterLayoutManager, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellWindowPreviewLayout, $_);
      }
    }
    self.setMutterClutterLayoutManager($to-parent);
  }

  method Mutter::Cogl::Raw::Definitions::ShellWindowPreviewLayout
    is also<ShellWindowPreviewLayout>
  { $!swpl }

  multi method new (
    ShellWindowPreviewLayoutAncestry  $shell-window-preview-layout,
                                     :$ref                          = True
  ) {
    return unless $shell-window-preview-layout;

    my $o = self.bless( :$shell-window-preview-layout );
    $o.ref if $ref;
    $o;
  }

  method add_window (MutterMetaWindow() $window, :$raw = False)
    is also<add-window>
  {
    propReturnObject(
      shell_window_preview_layout_add_window($!swpl, $window),
      $raw,
      |Mutter::Clutter::Actor.getTypePair
    );
  }

  method get_windows ( :$raw = False, :$glist = False ) is also<get-windows> {
    returnGList(
      shell_window_preview_layout_get_windows($!swpl),
      $raw,
      $glist,
      |Mutter::Meta::Window.getTypePair
    )
  }

  method remove_window (MutterMetaWindow() $window) is also<remove-window> {
    shell_window_preview_layout_remove_window($!swpl, $window);
  }

}

### /home/cbwood/Projects/gnome-shell/src/shell-window-preview-layout.h

sub shell_window_preview_layout_add_window (
  ShellWindowPreviewLayout $self,
  MutterMetaWindow         $window
)
  returns MutterClutterActor
  is native(gnome-shell)
  is export
{ * }

sub shell_window_preview_layout_get_windows (ShellWindowPreviewLayout $self)
  returns GList
  is native(gnome-shell)
  is export
{ * }

sub shell_window_preview_layout_remove_window (
  ShellWindowPreviewLayout $self,
  MutterMetaWindow         $window
)
  is native(gnome-shell)
  is export
{ * }
