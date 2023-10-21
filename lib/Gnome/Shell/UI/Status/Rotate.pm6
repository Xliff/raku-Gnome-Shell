use v6.c;

use Gnome::Shell::UI::Raw::Types;

use GIO::Settings;
use Gnome::Shell::Misc::SystemActions;
use Gnome::Shell::UI::QuickSettings;

### /home/cbwood/Projects/gnome-shell/js/ui/status/autoRotate.js

class Gnome::Shell::UI::Status::Rotation::Toggle
  is Gnome::Shell::UI::QuickSettings::Toggle
{
  has $!systemActions = Gnome::Shell::Misc::SystemActions.default;
  has $!settings      = GIO::Settings.new(
    schema-id => 'org.gnome.settings-daemon.peripherals.touchscreen'
  );

  submethod TWEAK {
    self.setAttributes( title => 'Auto Rotate' );

    $!systemActions.bind('can-lock-orientation',  'visible');
    $!systemActions.bind('orientation-lock-icon', 'icon-name');
    $!settings.bind('orientation-lock', 'checked', :invert);
    self.click.tap( -> *@a { $!systemActions.activateLockOrientation });
  }
}

class Gnome::Shell::UI::Status::Rotation::Indicator
  is Gnome::Shell::UI::QuickSettings::SystemIndicator
{
  method TWEAK {
    self.quickSettingsItems.push:
      Gnome::Shell::UI::Status::Rotation::Toggle.new;
  }
}
