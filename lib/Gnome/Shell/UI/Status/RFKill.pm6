use v6.c;

use GIO::DBus::InterfaceInfo;
use Gnome::Shell:Raw::Types;

use Gnome::Shell::UI::QuickSettings;

constant RFKILL_BUS_NAME    = 'org.gnome.SettingsDaemon.Rfkill';
constant RFKILL_OBJECT_PATH = '/org/gnome/SettingsDaemon/Rfkill';

constant RfKillManagerInterface = loadInterfaceXML(RFKILL_BUS_NAME);

constant rfkillManagerInfo = Gio.DBusInterfaceInfo.new_for_xml(
  RfKillManagerInterface
);

### /home/cbwood/Projects/gnome-shell/js/ui/status/rfkill.js

class Gnome::Shell::Ui::Status::RFKill
  does GLib::Roles::Object::Registration<Gnome-Shell>
{
  also does GLib::Roles::Object;

  has Bool $!airplane-mode      is rw is g-property;
  has Bool $!hw-airplane-mode   is rw is g-property;
  has Bool $!show-airplane-mode is rw is g-property;

  has $!proxy = GIO::DBus::Proxy.new(
    g-connection     => GIO::DBus.session,
    g-name           => RFKILL_BUS_NAME,
    g-object-path    => RFKILL_OBJECT_PATH,
    g-interface-name => rfKillManagerInfo.name,
    g-interface-info => rfKillManagerInfo
  );

  submethod TWEAK {
    my $s = self;
    $!proxy.g-properties-changed.tap( -> *@a {
      $s.changed( |@a );
    });

    try {
      CATCH { default { $*ERR.say: .message } }
      $!proxy.init-async;
    }
  }

  method airplane-mode {
    Proxy.new:
      FETCH => -> $     { $!proxy.airplane-mode },
      STORE => -> $, \v { $!proxy.airplane-mode = v };
  }

  method changed ($p, $pr) {
    for $properties[] {
      given $p {
        when 'AirplaneMode'           { self.notify('airplane-mode') }
        when 'HardwareAirplaneMode'   { self.notify('hw-airplane-mode' }

        when 'HasAirplaneMode' |
             'ShouldShowAirplaneMode' { self.notify('show-airplane-mode') }
      }
    }
  }
}

my $manager;

sub getRFKillManager is export {
  return $manager if $manager;
  $manager = Gnome::Shell::UI::RFKillManager.new;
}

class Gnome::Shell::UI::Status::RFKill::Toggle
  is Gnome::Shell::UI::QuickSettings:::Toggle
{
  has $!manager;

  submethod TWEAK {
    self.setAttributes(
      title      => 'Airplane Mode',
      icon-name => 'airplane-mode-symbolic'
    );

    $!manager = getRFKillManager();
    $!manager.bind('show-airplane-mode', 'visible');
    $!manager.bind('airplane-mode',      'checked');

    self.clicked.tap( -> *@a {
      $!manager.airplane-mode = $!manager.airplane-mode.not;
    });
  }
}

class Gnome::Shell::UI::Status::RFKill::Indicator
  is Gnome::Shell::UI::SystemIndicator
{
  has $!rfKillToggle;

  submethod TWEAK {
    self.indicator = self.addIndicator;
    self.indicator.icon-name = 'airplane-mode-symbolic';

    $!rfKillToggle = Gnome::Shell::UI::Status::RFKill::Toggle.new;
    $!rfKillToggle.connectObject(
      'notify::visible', -> *@a { $s.sync },
      'notify::checked', -> *@a { $s.sync }
    );
    self.quickSettingsItems.push($!rfKillToggle);
    self.sync;
  }

  method sync {
    self.indicator.visible = .visible && .checked
      given $!rfKillToggle;
  }
}
