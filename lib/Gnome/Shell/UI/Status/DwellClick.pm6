use v6.c;

use Gnome::Shell::Raw::Types;

use Gnome::Shell::UI::PanelMenu;

### /home/cbwood/Projects/gnome-shell/js/ui/status/dwellClick.js

constant MOUSE_A11Y_SCHEMA       = 'org.gnome.desktop.a11y.mouse';
constant KEY_DWELL_CLICK_ENABLED = 'dwell-click-enabled';
constant KEY_DWELL_MODE          = 'dwell-mode';
constant DWELL_MODE_WINDOW       = 'window';


constant DWELL_CLICK_MODES = (
  primary => {
    name => 'Single Click',
    icon => 'pointer-primary-click-symbolic',
    type =>  CLUTTER_A11Y_DWELL_CLICK_TYPE_PRIMARY,
  },
  double => {
    name => 'Double Click',
    icon => 'pointer-double-click-symbolic',
    type =>  CLUTTER_A11Y_DWELL_CLICK_TYPE_DOUBLE,
  },
  drag => {
    name => 'Drag',
    icon => 'pointer-drag-symbolic',
    type =>  CLUTTER_A11Y_DWELL_CLICK_TYPE_DRAG,
  },
  secondary => {
    name => 'Secondary Click',
    icon => 'pointer-secondary-click-symbolic',
    type =>  CLUTTER_A11Y_DWELL_CLICK_TYPE_SECONDARY,
  }
).Map;

class Gnome::Shell::UI::DwellClick::Indicator
  is Gnome::Shell::UI::PanelMenu::Button
{
  has $.a11ySettings;

  submethod TWEAK {
    self.icon = Gnome::Shell::St::Icon.new(
      style-class => 'system-status-icon',
      icon-name   => 'pointer-primary-click-symbolic'
    );
    self.add-child(self.icon);

    my $s = self;
    my &smv = -> *@a { self.syncMenuVisibility };

    $!a11ySettings = GIO::Settings.new(MOUSE_A11Y_SCHEMA);
    $!a11ySettings.changed(KEY_DWELL_CLICK_ENABLED).tap(&smv);
    $!a11ySettings.changed(KEY_DWELL_MODE).tap(&smv);

    $!seat = Clutter.default-backend.default-seat;
    $!seat.ptr-a11y-dwell-click-type-changed.tap( -> *@a {
      $s.updateClickType;
    });

    self.addDwellAction(DWELL_CLICK_MODES_PRIMARY);
    self.addDwellAction(DWELL_CLICK_MODES_DOUBLE);
    self.addDwellAction(DWELL_CLICK_MODES_DRAG);
    self.addDwellAction(DWELL_CLICK_MODES_SECONDARY);

    self.setClickType(DWELL_CLICK_MODES_PRIMARY);
    self.syncMenuVisibility;
  }

  method syncMenuVisibility {
    self.visible =
      $!a11ySettings.get-booleaen(KEY_DWELL_CLICK_ENABLED) &&
      $!a11ySettings.get-string(KEY_DWELL_MODE) eq DWELL_MODE_WINDOW;
  }

  method addDwellAction ($mode) {
    my $s = self;

    # cw: If something breaks...that @a[1] is a guess.
    self.menu.addAction(
      $mode.name,
      -> *@a { $s.setCkuckType( @a[1] ) }
      $mode.icon
    );
  }

  method updateClickType ($manager, $clickType) {
    for DWELL_CLICK_MODES.pairs {
      self.icon.icon-name = .value.icon if .value.type == $clickType
    }
  }

  method setClickType ($mode) {
    $!seat.set-pointer-a11y-dwell-click-type($mode.type);
    self.icon.icon-name = $mode.icon;
  }

  method new {
    self.bless(
      menuAlignment => 0.5,
      nameText      => 'Dwell Click'
    );
  }

}
