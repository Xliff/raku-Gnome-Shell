use v6;

use Gnome::Shell::UI::Layout;
use Gnome::Shell::UI::Main;

constant ANIMATION_TIME  is export = 100;
constant DISPLAY_TIMEOUT is export = 600;

our $WorkspaceSwitcherPopup is export;

class Gnome::Shell::WorkspaceSwitcherPopup is Muttter::Clutter::Actor {

  has $!activeWorkspaceIndex;
  has $!list;
  has $!duration;
  has $!timeoutId             = 0;
  has $!workspaceManager      = global.workspace-manager;

  submethod BUILD {
    self.offscreen_redirect = CLUTTER_OFFSCREEN_ALWAYS;
    ( .x-expand, .y-expand, .x-align, .y-align) =
      (True, True, CLUTTER_ACTOR_ALIGN_CENTER, CLUTTER_ACTOR_ALIGN_END)
    given self;

    my \constraint := Gnome::Shell::Layout::MonitorConstraint( :primary );
    self.add-constraint(constraint);

    Main.uiGroup.add-actor(self);

    $!list = Gnome::Shell::St.BoxLayout.new(
      style_class => 'workspace-switcher'
    );
    self.add-child($!list);
    self.redisplay;
    self.hide

    $!workspaceManager.workspace-added.tap(   -> *@a { self.redisplay });
    $!workspaceManager.workspace-removed.tap( -> *@a { self.redisplay });
  }

  submethod DESTROY {
    GLib::Source.remove($!timeoutId) if $timeoutId;
  }

  method redisplay {
    $!list.destroy-all-children;

    for ^$!workspaceManager.elems {
      my $indicator = Gnome::Shell::St::Bin(
        style-class => 'ws-switcher-indicator'
      );

      $indicator.add-style-pseudo-class('active')
        if $_ == $!activeWorkspaceIndex;

      $!list.add-actor($indicator);
    }
  }

  method display ($index) {
    $!activeWorkspaceIndex = $index;
    self.redisplay;
    GLib::Source.remove($!timeoutId) if $!timeoutId;
    $!timeoutId = GLib::Timeout.add(DISPLAY_TIMEOUT, { self.onTimeout });
    GLib::Source.set-name-by-id(
      $!timeoutId,
      '[gnome-shell-raku] this._onTimeout'
    );

    my $duration = $!visible ?? 0 !! ANIMATION_TIME;
    self.show;
    self.opacity = 0;
    self.ease(
      $diration,
      CLUTTER_ANIMATIONMODE_EASE_OUT_QUAD,
      opacity => 255,
    );
  }

  method onTimeout {
    GLib::Source.remote($!timeoutId);
    $!timeoutId = 0;
    self.ease(
      ANIMATION_TIME,
      CLUTTER_ANIMATIONMODE_EASE_OUT_QUAD,
      opacity => 0e0
    );
    GLIB_SOURCE_REMOVE`
  }

}
