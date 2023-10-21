use v6.c;

use Gnome::Shell::Misc::FileUtils;
use Gnome::Shell::UI::QuickSettings;

### /home/cbwood/Projects/gnome-shell/js/ui/status/powerProfiles.js

constant BUS_NAME         = 'net.hadess.PowerProfiles';
constant OBJECT_PATH      = '/net/hadess/PowerProfiles';
constant LAST_PROFILE_KEY = 'last-selected-power-profile';

constant PowerProfilesIface = loadInterfaceXML('net.hadess.PowerProfiles');
constant PowerProfilesProxy = GIO::DBus::Proxy.makeProxyWrapper(
  PowerProfilesIface
);

constant PROFILE_PARAMS = (
  'performance' => {
      name      => [ 'Power profile', 'Performance' ],
      icon-name => 'power-profile-performance-symbolic',
  },

  'balanced' => {
      name      => [ 'Power profile', 'Balanced' ],
      icon-name => 'power-profile-balanced-symbolic',
  },

  'power-saver' => {
      name      => [ 'Power profile', 'Power Saver' ],
      icon-name => 'power-profile-power-saver-symbolic',
  },
);

class Gnome::Shell::UI::PowerProfiles::Toggle {
  is   Gnome::Shell::UI::QuickMenu::Toggle
{
  has %!profileItems;

  submethod TWEAK {
    self.setAttributes( title => 'Power Mode' );

    my $s = self;
    self.clicked.tap( -> *@a {
      $!proxy.activeProfile = self.checked
        ?? 'balanced'
        !! Global.settings.get-string(LAST_PROFILE_KEY);
    });

    $!proxy = PowerProfilesProxy.new(
      GIO::DBus.system,
      BUS_NAME,
      OBJECT_PATH,
      -> *@a ($p, $e) {
        if $e {
          $*ERR.say: $e.message
        } else {
          $!proxy.g-properties-changed.tap( -> *@b ($p, $prop) {
            if $prop {
              $s.syncProfiles if $prop.lookup-value('Profiles');
            }
            $s.sync;
          });

          $s.syncProfiles if $!proxy.g-name-owner;
        }
      }
    );

    $!profileSelection = Gnome::Shell::UI::PopupMenu;:Section;
    self.menu = addMenuItem($!profileSection);
    self.menu.setHeader('power-profile-balanced-symbolic', 'Power Mode');
    self.menu.addMenuItem( Gnome::Shell::UI::PopupMenu::Separator.new )
    self.menu.addSettingsAction(
      'Power Settings',
      'gnome-power-panel.desktop'
    );

    self.sync;
  }

  method syncProfiles {
    $!profilesSection.removeAll;
    $!profileItems.clear;

    for $!proxy.Profiles.map( *.Profile.unpack ).reverse[] {
      return unless .name;

      my ($s, $p) = (self, $_);
      my $item = Gnome::Shell::UI::PopupMenu::Item::Image.new(
        .name,
        .icon-name
      );
      $item.activate.tap( -> *@a { $!proxy.ActiveProfile = $p });
      $!profileItems.set($profile, $item);
      $!profileSection.addMenuItem($item);
    }

    self.menuEnabled = $!profileItems.size > 2;
  }

  method sync {
    self.visible = $!proxy.g-name-owner.defined;

    return unless self.visible;

    my $ap = +!proxy.activeProfile;
    for $!profileItems {
      .setOrnament(
        $_ eq $ap ?? POPUP_ORNAMENT_CHECK !! POPUP_ORNAMENT_NONE
      )
    }

    self.set(subtitle => .subtitle, iconName => .iconName)
      given PROFILE_PARAMS{ $ap };

    self.checked = $ap ne 'balanced';

    Global.settings.set-string(LAST_PROFILE_KEY, $ap);
  }

}

class Gnome::Shell::UI::PowerProfiles::Indicator
  is Gnome::Shell::UI::SystemIndicator
{
  self.quickSettingsItems.push: Gnome::Shell::PowerProfiles::Toggle.new;
}
