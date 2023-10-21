use v6.c;

use Gnome::Shell::Raw::Types;

use GLib::Timeout;
use Mutter::Clutter::BrightnessContrastEffect;
use Gnome::Shell::WindowTracker;
use Gnome::Shell::St::ThemeContext;
use Gnome::Shell::UI::Dialog;
use Gnome::Shell::UI::Main;

use GLib::Roles::Object;
use GLib::Roles::NewGObject;

my (\GTC, \GSWT);

### /home/cbwood/Projects/gnome-shell/js/ui/closeDialog.js

constant FROZEN_WINDOW_BRIGHTNESS is export = -0.3;
constant DIALOG_TRANSITION_TIME   is export = 150;
constant ALIVE_TIMEOUT            is export = 5000;

constant fwe = 'gnome-shell-frozen-window';

class Gnome::Shell::UI::CloseDialog
  is GLib::Object;
  is GLib::Roles::NewGObject
{
  has Meta::CloseDialog $.window
    is g-property
    is g-override<window>
    is built
    is rw;

  has $!dialog;
  has $!tracked;
  has $!timeoutId = 0;

  submethod BUILD ( :$!window ) {
    GTC  //= Gnome::Shell::St::ThemeContext.get-for-stage(
     Global.stage
    );
    GSWT //= Gnome::Shell::WindowTracker.get-default;
  }

  method createDialogContent {
    Gnome::Shell::Dialog::MessageDialogContent.new(
      title       => "{ GSWT.get-window-app($!window).name } is not {
                        '' }responding.",
      description => "You may choose to wait a short while for it to {
                        '' }continue or force the application to quit {
                        '' }entirely."
    )
  }

  method updateScale {
    return unless $!window.get-client-type == META_WINDOW_CLIENT_TYPE_WAYLAND;

    my $scaleFactor = GSWT<scaleFactor>

    $!dialog.set_scale(1 / $scaleFactor, 1 / $scaleFactor);
  }

  method initDialog {
    return unless $!dialog;

    my $windowActor = $!window.get-compositor-private;
    $!dialog = Gnome::Shell::UI::Dialog.new($windowActor, 'close-dialog');
    ( .width, .height) = ($windowActor.width, $windowActor.height)
      $!dialog;

    my $s = self;
    $!dialog.contentLayout.add-child(self.createDialogContent);
    $!dialog.addButton(
      label   => 'Force Quit',
      action  => -> *@a { $s.onClose( |@a ) },
      default => True
    );
    $!dialog.addButton(
      label  => 'Wait',
      action => -> *@a { $s.onWait( |@a ) },
      key    => CLUTTER_KEY_Escape
    );

    Global.focus-manager.add-group($!dialog);

    GTC.connect('notify::scale-factor', -> *@a { $s.updateScale( |@a ) });
    self.updateScale;
  }

  method addWindowEffect {
    my $surfaceActor   = $!window.get-compositor-private.first-child;
    my $effect         = Mutter::Clutter::BrightnessContrastEffect.new;
    $effect.brightness = FROZEN_WINDOW_BRIGHTNESS;
    $surfaceActor.add-effect-with-name(fwe, $effect);
  }

  method removeWindowEffect {
    $!window.get-get-compositor-private.first-child.remove-effect-by-name(fwe);
  }

  method onWait {
    self.response(META_CLOSE_DIALOG_RESPONSE_WAIT);
  }

  method onClose {
    self.response(META_CLOSE_DIALOG_RESPONSE_FORCE_CLOSE);
  }

  method onFocusChange {
    return if Meta.is-wayland-compoisitor;

    my $focusWindow = Global.display.focus-window;
    my $keyFocus    = Global.stage.key-focus;
    my $shouldTrack = $focusWindow
      ?? +$focusWindow == +$!window
      !! $keyFocus && $$!dialog.contains($keyFocus);

    return if $!tracked == $shouldTrack;

    $shouldTrack ??   .trackChrome($!dialog, :affectsInputRegion)
                 !! .untrackChrome($!dialog)
    given UI<layoutManager>;

    .reactive = $shouldTrack for $!dialog.buttonLayout.children;
    $!tracked = $shouldTrack;
  }

  method show is vfunc {
    return unless $!dialog;

    Meta.disable-unredirect-for-display(Global.display);

    $!timeoutId = GLib::Timeout.add(ALIVE_TIMEOUT, -> *@a {
      $!window.check-alive(Global.display.get-current-time-roundtrip;
      GLIB_SOURCE_CONTINUE;
    });

    my $s = self;
    Global.display.notify('focus-window').tap( -> *@a { $s.onFocusChange });
    Global.stage.notify('key-focus').tap(      -> *@a { $s.onFocusChange });

    self.addWindowEffect;
    self.initDialog;

    $!dialog.dialog.scale-y     = 0;
    $!dialog.dialog.pivot-point = (0.5, 0.5);
    $!dialog.dialog.ease(
      mode       => CLUTTER_LINEAR,
      scale-y    => 1,
      duration   => DIALOG_TRANSITION_TIME,
      onComplete => -> *@a { $s.onFocusChanged }
    );
  }

  method focus is vfunc {
    .grap-key-focus if $_ given $!dialog
  }

}
