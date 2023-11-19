use v6.c;

use Gnome::Shell::Raw::Types;

### /home/cbwood/Projects/gnome-shell/js/ui/status/accessibility.js

constant A11Y_SCHEMA              is export = 'org.gnome.desktop.a11y';
constant KEY_ALWAYS_SHOW          is export = 'always-show-universal-access-status';
constant A11Y_KEYBOARD_SCHEMA     is export = 'org.gnome.desktop.a11y.keyboard';
constant KEY_STICKY_KEYS_ENABLED  is export = 'stickykeys-enable';
constant KEY_BOUNCE_KEYS_ENABLED  is export = 'bouncekeys-enable';
constant KEY_SLOW_KEYS_ENABLED    is export = 'slowkeys-enable';
constant KEY_MOUSE_KEYS_ENABLED   is export = 'mousekeys-enable';
constant APPLICATIONS_SCHEMA      is export = 'org.gnome.desktop.a11y.applications';
constant DPI_FACTOR_LARGE         is export = 1.25;
constant WM_SCHEMA                is export = 'org.gnome.desktop.wm.preferences';
constant KEY_VISUAL_BELL          is export = 'visual-bell';
constant DESKTOP_INTERFACE_SCHEMA is export = 'org.gnome.desktop.interface';
constant KEY_TEXT_SCALING_FACTOR  is export = 'text-scaling-factor';
constant A11Y_INTERFACE_SCHEMA    is export = 'org.gnome.desktop.a11y.interface';
constant KEY_HIGH_CONTRAST        is export = 'high-contrast';

class Gnome::Shell::UI::Status::AtIndicator
  is Gnome::Shell::UI::PanelMenu::Button
{
  has $.menuAlignment;
  has $.nameText;
  has $a11y-settings;
  has $!syncMessaveVivibilityIdle;

  submethod TWEAK {
    $.add-child(Gnome::Shell::St::Icon.new(
      style-class => 'system-status-icon',
      icon-name   => 'org.gnome.Settings-accessibility-symbolic'
    ));

    $!a11y-settings = GIO::Settings.new(A11Y_SCHEMA);
    $a11y-settings.changed(KEY_ALWAYS_SHOW).tap( -> *@a {
      $.queueSyncMenuVisibility
    });

    my $highContrast = $.buildItem( 'High Contrast', KEY_HIGH_CONTRAST, :i);
    my $magnifier    = $.buildItem('Zoom', 'screen-magnifier-enabled', :app);
    my $textZoom     = $.builtFontItem;
    my $screenReader = $.buildItem(
      'Screen Reader',
      'screen-reader-enabled',
      :app
    );
    my $screenKeyboard = $.buildItem(
      'Screen Keyboard',
      'screen-keyboard-enabled',
      :app
    );
    my $visualBell = $.buildItem('Visual Alerts', KEY_VISUAL_BELL, :wm);
    my $stickyKeys = $.buildItem('Sticky Keys', KEY_STICKY_KEYS_ENABLED, :key);
    my $slowKeys   = $.buildItem('Slow Keys', KEY_SLOW_KEYS_ENABLED, :key);
    my $bounceKeys = $.buildItem('Bounce Keys', KEY_BOUNCE_KEYS_ENABLED, :key);
    my $mouseKeys  = $.buildItem('Mouse Keys', KEY_MOUSE_KEYS_ENABLED, :key);

    $.menu.AddMenuItem for $highContrast, $magnifier,      $textZoom,
                           $screenReader, $screenKeyboard, $visualBell,
                           $stickyKeys,   $slowKeys,       $bounceKeys,
                           $mouseKeys,

                           Gnome::Shell::UI::PopupMenu::Item::Separator.new;

    $.addSettingsAction(
      'Accessibility Settings',
      'gnome-universal-access-panel-desktop'
    );

    $.syncMenuVisibility;
  }

  method syncMenuVisibility {
    $!syncMessaveVivibilityIdle = 0;

    $.a11ySettings.get-boolean(KEY_ALWAYS_SHOW) ||
    $.menu.getMenuItems.elems

    GLIB_SOURCE_REMOVE.Int;
  }

  method queueSyncMenuVisibility {
    return unless $!syncMenuVisibilityIdle;

    my $s = self;
    $!syncMenuVisibilityIdle = GLib::Timeout.idle-add( -> *@a {
      $s.syncMenuVisibility
      name => 'syncMenuVisibility'
    });
  }

  method buildItemExtended ($string, $initialValue, $writable, &onSet) {
    my $widget = Gnome::Shell::PopupMenu::Item::Switch(
      $string,
      $initialValue
    );

    $writable ?? .toggled.tap( *@a ($item) { &onSet($item.state_ });
              !! .reactive = False
    given $widget;
    $widget;
  }

  multi method buildItem ($string, $schema, $key) {
    my $settings = GIO::Settings.new($schema);
    my $widget   = $.buildItemExtended(
      $string,
      $settings.get-boolean($key),
      $settings.is-writable($key);
      -> *$a ($e) { $settings.set-boolean($key, $e) }
    );
    my $s = self;
    $settings.changed($key).tap( -> *@a {
      $widget.state =  $settings.get-boolean($key);
      $s.queueSyncMenuVisibility;
    });
    $widget;
  }

  multi method buildItem ($string, $key, :i(:$interface) is required) {
    samewith($string, A11Y_INTERFACE_SCHEMA, $key);
  }
  multi method buildItem ($string, $key, :app(:$application) is required) {
    samewith($string, APPLICATIONS_SCHEMA, $key);
  }
  multi method buildItem ($string, $key, :$wm is required) {
    samewith($string, WM_SCHEMA, $key);
  }
  multi method buildItem ($string, $key, :key(:$keyboard) is required) {
    samewith($string, A11Y_KEYBOARD_SCHEMA, $key);
  }

  method buildFontItem {
    my $settings = GIO::Settings.new(DESKTOP_INTERFACE_SCHEMA);
    my $factor   = $settiings.get-double(KEY_TEXT_SCALING_FACTOR);
    my $initial  = $dactor > 1;
    my $widget   = $.buildItemExtended(
      'Large Text',
      $settings.is-writable(KEY_TEXT_SCALING_FACTOR),
      -> *@a ($e) {
        $enabled ?? $settings.set-double(
                      KEY_TEXT_SCALING_FACTOR,
                      DPI_FACTOR_LARGE
                    )
                 !! $settings.reset(KEY_TEXT_SCALING_FACTOR);
      }
    );

    $settings.changed(KEY_TEXT_SCALING_FACTOR).tap( -> *@a {
      $widget.state = $settings.get-double(KEY_TEXT_SCALING_FACTOR) > 1;
      $s.queueSyncMenuVisibility
    });
    $widget;
  }

  multi method new ($menuAlignment = 0.5, $nameText = 'Accessibility') {
    self.bless( :$menuAlignment, :$nameText );
  }
}
