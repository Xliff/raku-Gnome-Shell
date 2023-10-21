use v6;

use Muttter::Clutter::ClickAction;
use Gnome::Shell::UI::BoxPointer;
use Gnome::Shell::UI::Main;
#use Gnome::Shell::UI::PopupMenu;

### /home/cbwood/Projects/gnome-shell/js/ui/backgroundMenu.js

class Gnome::Shell:UI::BackgroundMenu is Gnome::Shell::UI::PopupMenu {

  submethod BUILD {
    //super(layoutManger.dummyCursor, 0, ST_SIDE_TOP)

    self.addSettingsAction(
      'Change Background...',
      'gnome-background-panel.desktop'
    );
    self.addMenuItem( PopupSeparatorMenuItem.new );
    self.addSettingsAction('Display Settings', 'gnome-display-panel.desktop');
    self.addSettingsAction('Settings', 'org.gnome.Settings.desktop');
    self.actor.add-style-class-name('background-menu');
    layoutManager.uiGroup.add-actor(self.actor);
    self.actor.hide;
  }

  method addBackgroundMenu ($actor, $layoutManager) {
    $actor.reactive = True;
    $actor.backgroundMenu = BackgroundMenu.new($layoutManager);
    $actor.backgroundManager = PopupMenuManager.new($actor);
    $actor.backgroundManager.addMenu($actor.backgroundMenu);

    sub openMenu($x, $y) {
      UI<layoutManager>.setDummyCursorGeometry($x, $y, 0, 0);
      $actor.backgroundMenu.open(POPUP_ANIMATION_FULL);
    }

    ( my $clickAction = Mutter::Clutter::ClickAction.new ).long-press.tap(
      -> *@a ($action, $actor-in, $state) {
        if $state == CLUTTER_LONG_PRESS_STATE_QUERY {
          return if $action.get-button eq (0, 1).any &&
                    $actor-in.backgroundMenu.isOpen;
        }
        if $state == CLUTTER_LONG_PRESS_STATE_ACTIVATE {
          openMenu( | $action.get-coords );
          $actor-in.backgroundManager.ignoreRelease
        }
        True
      }
    );

    $clickAction.clicked.tap( -> *@a {
      openMenu( |$action.get-coords ) if $action.get-button == 3;
    });

    $actor.add-action($clickAction);

    global.display.grab-op-begin.tap( -> *@a { $clickAction.release($actor) });

    $actor.destroy.tap( -> *@a {
      $actor.backgroundMenu.destroy;
      $actor.backgroundMenu = $actor.backgroundManager = Nil;
    });
  }

}

constant BackgroundMenu is export := Gnome::Shell::UI::BackgroundMenu;
