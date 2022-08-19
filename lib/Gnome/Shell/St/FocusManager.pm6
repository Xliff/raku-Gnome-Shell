use v6.c;

use Method::Also;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::St::FocusManager;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

our subset StFocusManagerAncestry is export of Mu
  where StFocusManager | GObject;

class Gnome::Shell::St::FocusManager {
  also does GLib::Roles::Object;

  has StFocusManager $!stfm is implementor;

  submethod BUILD ( :$st-focus-manager ) {
    self.setStFocusManager($st-focus-manager) if $st-focus-manager
  }

  method setStFocusManager (StFocusManagerAncestry $_) {
    my $to-parent;

    $!stfm = do {
      when StFocusManager {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StFocusManager, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Gnome::Shell::Raw::Structs::StFocusManager
    is also<StFocusManager>
  { $!stfm }

  multi method new (StFocusManagerAncestry $st-focus-manager, :$ref = True) {
    return unless $st-focus-manager;

    my $o = self.bless( :$st-focus-manager );
    $o.ref if $ref;
    $o;
  }

  method get_for_stage (MutterClutterStage() $stage)
    is static
    is also<get-for-stage>
  {
    my $st-focus-manager = st_focus_manager_get_for_stage($stage);

    $st-focus-manager ?? self.bless( :$st-focus-manager ) !! Nil;
  }

  method add_group (StWidget() $root) is also<add-group> {
    st_focus_manager_add_group($!stfm, $root);
  }

  method get_group (StWidget() $widget, :$raw = False) is also<get-group> {
    propReturnObject(
      st_focus_manager_get_group($!stfm, $widget),
      $raw,
      |Gnome::Shell::St::Widget.getTypePair
    )
  }

  method navigate_from_event (MutterClutterEvent() $event)
    is also<navigate-from-event>
  {
    so st_focus_manager_navigate_from_event($!stfm, $event);
  }

  method remove_group (StWidget() $root) is also<remove-group> {
    st_focus_manager_remove_group($!stfm, $root);
  }

}
