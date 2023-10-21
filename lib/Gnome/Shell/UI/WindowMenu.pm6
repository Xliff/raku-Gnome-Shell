use v6.c;

use Gnome::Shell::UI::BoxPointer;
use Gnome::Shell::UI::Main;
use Gnome::Shell::UI::PopupMenu;
#use Gnome::Shell::UI::Screenshot;

### /home/cbwood/Projects/gnome-shell/js/ui/windowMenu.js

class Gnome::Shell::UI::WindowMenu is Gnome::Shell::UI::PopupMenu {

  has $!actor;

  submethod BUILD ( :$window ) {
    self.actor.add-style-class-name('window-menu');
    Main.layoutManager.uiGroup.add-actor(self.actor);
    self.actor.hide;
    self.buildMenu($window);
  }

  method new ($sourceActor) {
    self.bless(
      :$sourceActor,

      arrowAlignment => 0,
      arrowSide      => ST_SIDE_TOP
    );
  }

  method buildMenu ($window) {
    my $type = $window.type;

    $ = self.addAction( 'Take Screenshot', -> *@a {
      CATCH {
        default {
          $*ERR.say: "Error capturing screenshot: { .message }";
        }
      }

      # cw: Actualy 4 arguments, but 2 of them are optional and
      #     should be omitted
      await Screenshot.captureScreenshot(
        $window.compositor-private.paint-to-content.texture,
        1
      );
    });

    my $item = self.addAction( 'Hide', -> *@a {
      $window.minimize;
    });

    $item.setSensitive(False) if $!window.can-minimize;

    $item = do if $window.maximized {
      self.addAction( 'Restore', -> *@a {
        $window.unmaximize(META_MAXIMIZE_BOTH);
      });
    } else {
      self.addAction( 'Maximize', -> *@a {
        $window.maximize(META_MAXIMIZE_BOTH);
      }
    }
    $item.sensitive = False;

    $item = self.addAction( 'Move', *@a ($event) {
      my $seat = event.device.seat;
      $pointer = event.device.seat.device-type == (
        CLUTTER_POINTER_DEVICE,
        CLUTTER_TABLET_DEVICE,
        CLUTTER_PEN_DEVICE,
        CLUTTER_ERASER_DEVICE
      ).any ?? $device !! $seat.pointer;

      $window.begin-grab-op(
        META_GRAB_OP_KEYBOARD_RESIZING_UNKNOWN,
        $pointer,
        $event.time
      );
    });
    $item.sensitive = False unless $windows.allows-resize();

    self.addAction( 'Move Titlebar Onscreen', -> *@a {
      $window.shove-titlebar-onscreen;
    }) unless [||](
      $window.titlebar-is-onscreen$type,
      $type = (META_WINDOW_DOCK, META_WINDOW_DESKTOP).any
    );

    $item = self.addAction( 'Always on Top', -> *@a {
      $window.is-above ?? $window.unmake-above !! $window.make-above;
    });
    $item.ornament = POPUPMENU_ORNAMENT_CHECK;
    $item.sensitive = False
      if  $window.maximized == META_MAXIMIZE_BOTH ||
          $type == (
            META_WINDOW_DOCK,
            META_WINDOW_DESKTOP,
            META_WINDOW_SPLASHSCREEN
          ).any;
    });

    if Main.sessionMode.hasWorkspaces {
      my $isSticky = $window.is-on-all-workspaces
        unless Meta.prefs-get-workspaces-only-on-primary &&
               $window.is-on-primary-monitor.not;

      $item = self.add-action( 'Always on Visible Workspace', -> *@a {
        $isSticky ?? $window.unstick !! $window.stick;
      });

      $item.ornament = POPUPMENU_ORNAMENT_CHECK if $isSticky;
      $item.sensitive = False if $window.is-on-all-workspaces;

      unless $isSticky {
        my $workspace = $window.workspace;

        my @d = (
          META_MOTION_LEFT,
          META_MOTION_RIGHT,
          META_MOTION_UP,
          META_MOTION_DOWN
        );
        for @d {
          if +$workspace !== $workspace.get-neighbor($_) {
            my ($d, $ds) = ( $_, .Str.split.tail.tc );
            self.add-action("Move to Workspace { $ds }") -> *@a {
              $window.change-workspace($workspace.get-neighbor($d);
            });
          }
        }
      }

      my $display                 = Global.display;
      my ($nMonitors, $monitoIdx) = ($display.elems, $window.monitor);

      if $nMonitors > 1 && $monitorIdx >= 0 {
        self.addMenuIndex(Gnome::Shell::UI::PopupMenu::Item::Separator.new);

        for MutterMetaDisplayDirectionEnum.enums.pairs {
          my $dir = .value;
          my $index = $display.get-monitor-neighbor-index($monitor, $dir);
          unless $index == -1 {
            self.addAction(
              "Move to Monitor { .key.split('_').tail.tc }",
              -> *@a { $window.move-to-monitor($index) }
            );
          }
        }
      }

      self.addMenuIndex(Gnome::Shell::UI::PopupMenu::Item::Separator.new);

      $item = self.addAction( 'Close', -> *@a ($e) {
        $window.delete( $e.time )
      });
      $item.sensitive = False unless $window.can-close;
    }
  }

  method addAction ($label, $callback) {
    my $item = nextsame;
    $item.ornament = POPUPMENU_ORNAMENT_NONE;
    $item;
  }
}

class Gnome::Shell::UI::WindowMenu::Manager {
  has $!manager = Gnome::Shell::UI::PopupMenu::Manager.new(
    Main.layoutManager.dummyCursor
  );
  has $!sourceActor = Gnome::Shell::St::Widget.new.setAttributes(
    :reactive,
    :!visible
  );

  submethod TWEAK {
    $!sourceActor.button-press-event.tap( -> *@a {
      self.manager.activeMenu.toggle;
    });

    Main.uiGroup.add-actor($!sourceActor);
  }

  method showWindowMenuForWindow ($window, $type, $rect) {
    return unless Main.sessionMode.hasWmMenus;

    X::Gnome::Shell::Error.new(
      "Unsupported window meu type { $type }"
    ).throw unless $type === META_WINDOW_MENU_WM;

    my $menu = Gnome::Shell::UI::WindowMenu.new($window, $!sourceActor);
    $!manager.addMenu($menu);

    $menu.activate.tap( -> *@a { $window.check-alive(Global.current-time) });
    $window.unmanaged.tap( -> *@a { $menu.close });

    $!sourceActor.set-size( (1, $rect.width).max, (1, $rect.height).max );
    $!sourceActor.set-position($rect.x, $rect.y);
    $!sourceActor.show;

    $menu.open(BOXPOINTER_ANIMATION_FADE);
    $menu.actor.navigate-focus(ST_DIRECTION_TAB_FORWARD);
    $menu.open-state-changed.tap( -> sub ( *@a ($, $isOpen) ) {
      return if $isOpen;

      $!sourceActor.hide;
      $menu.destroy;
      $window.disconnect( $window.signal-manager<unmanaged>.tail );
    });
  }
}
