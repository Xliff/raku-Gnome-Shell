use v6.c;

use Gnome::Shell::UI::Raw::Types;

use GIO::Settings;
use GIO::DBus::Proxy;
use Gnome::Shell::Misc::SystemActions;
use Gnome::Shell::UI::QuickSettings;

constant POWER_SETTING_BUS_NAME    = 'org.gnome.SettingsDaemon.Power';
constant POWER_SETTING_OBJECT_PATH = '/org/gnome/SettingsDaemon/Power';

constant BrightnessInterface = loadInterfaceXML(
  "{ POWER_SETTING_BUS_NAME }.Screen"
);
constant BrightnessProxy = GIO::DBus::Proxy.makeProxyWrapper(
  BrightnessInterface
);

### /home/cbwood/Projects/gnome-shell/js/ui/status/brightness.js

class Gnome::Shell::UI::Status::Brightness::Item
  is Gnome::Shell::UI::QuickSettings::Slider
{
  has $!proxy;
  has $!sliderChangedId;
  has $!active;
  has $!sliderChangedId

  submethod TWEAK {
    self.setAttributes(
      iconName => 'display-brightness-symbolic'
    );

    $!active = True;

    my $s = self;
    $!proxy = BrightnessProxy.new(
      GIO::DBus.session,
      POWER_SETTING_BUS_NAME,
      POWER_SETTING_OBJECT_PATH,
      -> *@a ($p, $e) {
        $e ?? $*ERR.say: "Error in brightness slider init: { $e.message }"
           !! $!proxy.g-properties-changed.tap( -> *@a { $s.sync });
        $s.sync;
      }
    );
    self.slider.notify('value').tap( -> *@a {
      $s.sliderchanged( |@a ) if $!active;
    });
    # cw: Assigned for future use potential.
    $!sliderChangedId = self.signal-manager<notify::value>.tail;
    self.slider.accessible-name = 'Brightness';
  }

  method sliderChanged {
    $!proxy.Brightness = self.slider.value * 100;
  }

  method changeSlider ($v) {
    $!active = False;
    self.slider.value = $v;
    $!active = True;
  }

  method sync {
    my $b = $!proxy.Brightness;
    if $b ~~ Int && $b > 0 {
      self.visible = True;
      self.changeSlider($b / 100.0);
    }
  }
}

class Gnome::Shell::UI::Status::Brightness::Indicator
  is Gnome::Shell::UI::QuickSettings::SystemIndicator
{
  method TWEAK {
    self.quickSettingsItems.push:
      Gnome::Shell::UI::Status::Brightness::Slider.new;
  }
}
