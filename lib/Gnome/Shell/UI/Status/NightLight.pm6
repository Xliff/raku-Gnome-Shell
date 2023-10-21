use v6.c;

use Gnome::Shell::UI::Raw::Types;

use GIO::DBus::InterfaceInfo;
use Gnome::Shell::Misc::SystemActions;
use Gnome::Shell::UI::QuickSettings;

constant COLOR_SETTING_BUS_NAME    = 'org.gnome.SettingsDaemon.Color';
constant COLOR_SETTING_OBJECT_PATH = '/org/gnome/SettingsDaemon/Color';

constant ColorInterface = loadInterfaceXML(COLOR_SETTING_BUS_NAME);
constant ColorInfo = GIO::DBus::InterfaceInfo.new-for-xml(ColorInterface);

### /home/cbwood/Projects/gnome-shell/js/ui/status/nightLight.js

class Gnome::Shell::UI::Status::NightLight::Toggle
  is Gnome::Shell::UI::QuickSettings::Toggle
{
  has $!settings = GIO::Settings.new(
    'org.gnome.settings-daemon.plugins.color'
  );

  submethod TWEAK {
    self.setAttributes(
      title      => 'Night Light'
      iconName   => 'night-light-symbolic',
      toggleMode => True
    );

    Global.backend.monitor-manager.bind('night-light-supported', 'visible');

    $!settings.bind('night-light-enabled', 'checked');

  }
}

class Gnome::Shell::UI::Status::NightLight::Indicator
  is Gnome::Shell::UI::QuickSettings::SystemIndicator
{
  has $!indicator;
  has $!proxy;

  method TWEAK {
    $!indicator = self.addIndicator;
    $!indicator.icon-name = 'night-light-symbolic';

    self.quickSettingsItems.push:
      Gnome::Shell::UI::Status::NightLight::Toggle.new;

    $!proxy = GIO:::DBus::Proxy.new(
      g-connection     => GIO::DBus.session,
      g-name           => COLOR_SETTING_BUS_NAME,
      g-object-path    => COLOR_SETTING_OBJECT_PATH,
      g-interface-name => colorInfo.name,
      g-inferface-info => ColorInfo
    );

    my $s = self;
    $!proxy.g-properties-changed.tap( -> *@a ($p, $prop) {
      $s.sync if $prop && $prop.lookup-value('NightLightActive');
    });
    # cw: Somehow they are attaching an exception handler on an
    #     empty callback!
    # JAVASCRIPT
    # $!proxy.init_async(null)
    #        .catch(e => console.error(e.message));

    self.sync;
  }

  method sync {
    $!indicator.visible = $!proxy.NightLiteActive
  }
}
