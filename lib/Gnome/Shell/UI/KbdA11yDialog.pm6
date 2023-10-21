use v6.c;

use GIO::Settings;
use Mutter::Clutter::Backend;
use Gnome::Shell::UI::Dialog;
use Gnome::Shell::UI::ModalDialog;

use GLib::Roles::Object;

constant KEYBOARD_A11Y_SCHEMA    is export = 'org.gnome.desktop.a11y.keyboard';
constant KEY_STICKY_KEYS_ENABLED is export = 'stickykeys-enable';
constant KEY_SLOW_KEYS_ENABLED   is export = 'slowkeys-enable';

### /home/cbwood/Projects/gnome-shell/js/ui/kbdA11yDialog.js

class Gnome::Shell::UI::KbdA11yDialog {
  also does GLib::Roles::Object;

  has $!a11ySettings;

  submethod BUILD {
    $!a11ySettings = GIO::Settings.new( schema-id => KEYBOARD_A11Y_SCHEMA );

    my $seat = Mutter::Clutter::Backend.get-default-backend
                                       .get-default-seat;

    $seat.kbd-a11y-flags-changed( -> *@a {
       self.showKbdA11yDialog( $seat, |@a.skip(1) );
    });
  }

  method showKbdA11yDialog ($seat, $newFlags, $whatChanged) {
    my $dialog = Gnome::Shell::UI::ModelDialog.new;

    my ($key, $title, $enabled, $desc);
    if $whatChanged +& META_KEYBOARD_A11Y_FLAGS_SLOW_KEYS_ENABLED {
      $key     = KEY_SLOW_KEYS_ENABLED;
      $enabled = $newFlags +& META_KEYBOARD_A11Y_FLAGS_SLOW_KEYS_ENABLED;
      $title   = 'Slow Keys Turned ' ~~ $enabled ?? 'On' !! 'Off';
      $desc    = q:to/DESC/;
        You just held down the Shift key for 8 seconds. This is the shortcut
        for the Slow Keys feature, which affects the way your keyboard works.
        DESC
    } elsif $whatChanged +& META_KEYBOARD_A11Y_FLAGS_STICKY_KEYS_ENABLED {
      $key     = KEY_STICKY_KEYS_ENABLED;
      $enabled = $newFlags +& META_KEYBOARD_A11Y_FLAGS_STICKY_KEYS_ENABLED;
      $title   = 'Sticky Keys Turned ' ~~ $enabled ?? 'On' !! 'Off';
      if $enabled {
        $desc = q:to/DESC/;
          You just pressed the Shift key 5 times in a row. This is the shortcut
          for the Sticky Keys feature, which affects the way your keyboard
          works.
          DESC
      } else {
        $desc = q:to/DESC/;
          You just pressed two keys at once, or pressed the Shift key 5 times
          in a row. This turns off the Sticky Keys feature, which affects the
          way your keyboard works.
          DESC;
      }
    } else {
      return
    }

    my $content = Dialog::MessageDialogContent( :$title, :$desc );
    $dialog.contentLayout.add-child($content);

    $dialog.addButton(
      label  => $enabled ?? 'Leave On' !! 'Leave Off',
      action => -> *@a {
        $!a11ySettings.set_boolean($key, True);
        $dialog.close
      },
      default => $enabled,
      key = $enabled.not ?? MUTTER_CLUTTER_KEY_ESC !! Nil
    );

    $dialog.addButton(
      label  => $enabled ?? 'Turn On' !! 'Turn Off',
      action => -> *@a {
        $!a11ySettings.set_boolean($key, False);
        $dialog.close
      },
      default => $enabled.not,
      key = $enabled.not ?? MUTTER_CLUTTER_KEY_ESC !! Nil
    );

    $dialog.open
  }

}
