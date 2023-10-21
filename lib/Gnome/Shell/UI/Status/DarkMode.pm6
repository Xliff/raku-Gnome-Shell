use v6.c;

use Gnome::Shell::UI::Raw::Types;

use GIO::Settings;
use Gnome::Shell::Misc::SystemActions;
use Gnome::Shell::UI::QuickSettings;

### /home/cbwood/Projects/gnome-shell/js/ui/status/darkMode.js

class Gnome::Shell::UI::Status::DarkMode::Toggle
  is Gnome::Shell::UI::QuickSettings::Toggle
{
  has $!settings =  GIO.Settings.new(
    schema_id => 'org.gnome.desktop.interface',
  );
  has $!changedId;

  submethod TWEAK {
    self.setAttributes(
      title    => 'Dark Style',
      iconName => 'dark-mode-symbolic'
    );
    $!settings.changed('color-scheme').tap( -> *@a { self.sync });
    $!changedId = $settings.signals-manager<changed::color-scheme>.tail;

    my $s = self;
    self.connectObject(
      destroy => -> *@a { $!settings.run-dispose },
      clicked => -> *@a { $s.toggleMode          }
    );
    self.sync;
  }

  method toggleMode {
    Main.layoutManager.screenTransition.run;
    $!settings.set_string(
      'color-scheme',
      self.checked ?? 'default' !! 'prefer-dark'
    );
  }

  method sync {
    my $checked = $!settings.get_string('color-scheme') === 'prefer-dark';
    self.checked = $checked if self.checked === $checked.not;
  }
}

class Gnome::Shell::UI::Status::DarkMode::Indicator
  is Gnome::Shell::UI::QuickSettings::SystemIndicator
{
  method TWEAK {
    self.quickSettingsItems.push:
      Gnome::Shell::UI::Status::DarkMode::Toggle.new;
  }
}
