use v6;

use Gnome::Shell::Raw::Types;

use Gnome::Shell::UI::PopMenu;
use Gnome::Shell::UI::QuickSettings;
use Gnome::Shell::UI::Slider;

constant BUS_NAME            = 'org.gnome.SettingsDaemon.Power';
constant OBJECT_PATH         = '/org/gnome/SettingsDaemon/Power';

constant BrightnessInterface = loadInterfaceXML(
  'org.gnome.SettingsDaemon.Power.Keyboard'
);

constant BrightnessProxy = GIO::DBus::Proxy.makeProxyWrapper(
  BrightnessInterface
);

class Gnome::Shell::UI::Status::Backlight::SliderItem
  is Gnome::Shell::UI::PopupMenu::Item::Base
{
  has $!slider;
  has $!sliderChangedId;

  has Int $!value is default(0) is ranged(0..100) is g-property(RW);

  submethod BUILD {
    self.setAttributes(
      activate        => False,
      style-class     => 'keyboard-brightness-item',
      accessible-name => 'Keyboard Brightness'
    );

    $!slider          = Gnome::Shell::UI::Slider.new;
    $!sliderChangedId = $!slider.notify('value').tap: SUB {
      self.notify('value');
    }
  }

  method value is rw {
    Proxy.new:
      FETCH => -> $ { $!value * 100 },

      STORE => -> $, sub( \v ) {
        return if $!value == v;

        $!sliderChangedId.enabled = False;
        $!slider.value = v / 100;
        $!sliderChangedId.enabled = True;
        self.notify('value');
      }
  }

}

class Gnome::Shell::UI::Status::Backlight::DiscreteItem
  does GLib::Roles::Object
{
  has Int $!value    is default(0) is ranged(0..100) is g-property(RW);
  has Int $!n-levels is default(1) is ranged(1..3)   is g-property(RW);

  has %!levelBox;
  has %!levelButtons;

  submethod BUILD  {
    self.setAttributes(
      style-class => 'popup-menu-item',
      reactive    => True
    );

    self.addLevelButton('off',  'keyboard-brightness-off-symbolic');
    self.addLevelButton('low',  'keyboard-brightness-medium-symbolic');
    self.addLevelButton('high', 'keyboard-brightness-high-symbolic');

    self.notify('value').tap:    SUB { self.syncChecked }
    self.notify('n-levels').tap: SUB { self.syncLevels  }

    self.syncLevels;
  }

  enum Levels <off low high>;

  method valueToLevel ($v is copy) {
    state %ll = Levels.enums.antipairs.Hash;
    $ll{ ($v * $!n-levels.pred / 100).Int }
  }

  method levelToValue ($l) {
    state @lk = Levels.enums.keys;
    @lk.first( * eq $ll, :k ) / @lk.elems.pred * 100;
  }

  multi method addLevelButton ($key, $iconName) {
    samewith($key, $key.tc, $iconName);
  }
  multi method addLevelButton ($key, $label, $iconName) {
    my $box = Gnome::Shell::St::BoxLayout.new(
      style-class => 'keyboard-brightness-level',
      vertical    => True,
      x-expand    => True
    );

    my $bb;
    $box.add-child(
      $bb := %!levelButton{ $key } = Gnome::Shell::St::Button.new(
        $iconName,
        style-class => 'icon-button',
        can-focus   => True
      )
    );

    $bb.Clicked.tap: SUB { $!value self.levelToValue($key) }

    my $box-label = Gnome::Shell::St::Label.new(
      text    => $label,
      x-align => CLUTTER_ACTOR_ALIGN_CENTER
    );

    $box.add-child($box-label);
    self.add-child($box);
    %!levelBox{ $key } = $box;
  }

  method syncLevels {
    %!levelButtons<off>.visible  = $!n-levels > 0;
    %!levelButtons<high>.visible = $!n-levels > 1;
    %!levelButtons<low>.visible  = $!n-levels > 2;
    $.syncChecked;
  }

  method syncChecked {
    my $ck = $.valueToLevel($!value);

    .value.checked = $ck eq .key for %!levelButtons.pairs[];
  }

}

class Gnome::Shell::UI::Status::Backlight::Toggle::Keyboard
  is Gnome::Shell::UI::QuickSettings::Toggle
{
  has $!proxy;
  has $!sliderItem;
  has $!discreteItem;

  submethod BUILD {
    self.setAttributes(
      title    => 'Keyboard',
      iconName => 'display-brightness-symbolic'
    );

    my $s = self;
    $!proxy = BrightnessProxy.new(
      GIO::DBus.session,
      BUS_NAME,
      OBJECT_PATH,
      sub ($p, $e) {
        if $e {
          $*ERR.say: $e.message
        } else {
          $!proxy.g-properties-changed.tap: SUB { $s.sync };
          $s.sync
        }
      }
    );

    self.Clicked.tap: SUB { $!proxy.Brightness = self.checked ?? 0 !! 100; }

    $!sliderItem   = Gnome::Shell::UI::Status::Backlight::SliderItem.new;
    $!discreteItem = Gnome::Shell::UI::Status::Backlight::DiscreteItem.new;
    self.menu.box.add-child($_) for $!sliderItem, $!discreteItem;

    $!sliderItem.bind('visible', $!discreteItem, :invert);
    $!sliderItem.bind('value',   $!discreteItem);

    $!sliderItem.notify('value').tap: SUB {
      $!proxy.Brightness = $!sliderItem.value
    });

    $!discreteItem.notify('value').tap: SUB {
      $!proxy.Brightness = $!discreteItem.value
    });
  }

  method sync {
    my $b = $!proxy.Brightness;
    my $v = $b.Int ~~ Int && $b > 0;
    $.visible = $v;
    return unless $v;

    $.checked = $b > 0;

    my $us = $!proxy.Steps >= 4;
    $!sliderItem.setAttributes( visible => $us, value => $b );
    $!discreteItem.n-levels = $!proxy.Steps if $us;
  }
}

class Gnome::Shell::UI::Status::Backlight
  is Gnome::Shell::UI::SystemIndicator
{
  submethod BUILD {
    self.quickSettingsItems.push(
      Gnome::Shell::UI::Status::Backlight::Toggle::Keyboard.new
    );
  }
}
