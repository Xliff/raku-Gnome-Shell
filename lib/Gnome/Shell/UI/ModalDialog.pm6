use v6.c;

use Gnome::Shell::Raw::Types;
use Gnome::Shell::St::Widget;
use Gnome::Shell::UI::Dialog;
#use Gnome::Shell::UI::Layout;
#use Gnome::Shell::UI::Lightbox;
use Gnome::Shell::UI::Main;


constant OPEN_AND_CLOSE_TIME  is export = 100;
constant FADE_OUT_DIALOG_TIME is export = 1000;

enum State is export <
  OPENED
  CLOSED
  OPENING
  CLOSING
  FADED_OUT
>;

class Gnome::Shell::UI::ModalDialog is Gnome::Shell::St::Widget {
  has State $!state;
  has       %!Signals;

  has $.backgroundStack;
  has $.dialogLayout;
  has $.contentLayout;
  has $.buttonLayout;

  has $!backgroundBin;
  has $!monitorConstraint;
  has $!hasModal;
  has $!actionMode;
  has $!shellReactive;
  has $!shouldFadeIn;
  has $!shouldFadeOut;
  has $!destroyOnClose;
  has $!lightbox;
  has $!eventBlocker;

  has $!initialKeyFocus;
  has $!initialKeyFocusDestroyId;
  has $!savedKeyFocus;

  submethod BUILD ( :%params ) {
    %!Signals<opened closed> = Signals::Preserving.new xx 2;

    self.visible = False;
    self.reactive = True;
    (self.x, self.y) = 0 xx 2;
    self.accessible-role = ATK_ROLE_DIALOG;

    # params = Params.parse(params, {
    #     shellReactive: false,
    #     styleClass: null,
    #     actionMode: Shell.ActionMode.SYSTEM_MODAL,
    #     shouldFadeIn: true,
    #     shouldFadeOut: true,
    #     destroyOnClose: true,
    # });

    $!state          = CLOSED;
    $!hasModal       = false;
    $!actionMode     = %params<actionMode>;
    $!shellReactive  = %params<shellReactive>;
    $!shouldFadeIn   = %params<shouldFadeIn>;
    $!shouldFadeOut  = %params<shouldFadeOut>;
    $!destroyOnClose = %params<destroyOnClose>;

    Main.layoutManager.modalDialogGroup.add-actor(self);

    my $constraint = Mutter::Clutter::BindConstraint(
      source     => global.stage,
      coordinate => CLUTTER_BIND_COORDINATE_ALL
    );
    self.add-constraint($constraint);

    $!backgroundStack = Gnome::Shell::St::Widget.new(
      layout-manager => Mutter::Clutter::BinLayout.new,
      x-expand       => True,
      y-expand       => True
    );

    $!backgroundBin = Gnome::Shell::St::Bin.new(
      child => $!backgroundStack
    );

    $!monitorConstraint = Gnome::Shell::UI::Layout::MonitorConstraint.new;
    $!backgroundBin.add-constraint($monitorConstraint);
    self.add-actor($!backgroundBin);

    $!dialogLayout = Gnome::Shell::UI::Dialog::Dialog.new(
      $!backgroundStack,
      %params<styleClass>
    );
    $!contentLayout := $!dialogLayout.contentLayout;
    $!buttonLayout  := $!dialogLayout.buttonLayout;

    if $!shellReactive {
      $!lightBox = Gnome::Shell::UI::Lightbox.new(
        self,
        inhibitEvents => True,
        radialEffect  => True`
      );
      $!lightBox.highlight($!backgroundBin);
      $!eventBlocker = Mutter::Clutter::Actor.new( reactive => True );
      $!backgroundStack.add-actor($!eventBlocker);
    }

    global.focus-manager.add-group($!dialogLayout);
    $!initialKeyFocus = 0;
    $!initialKeyFocusDestroyId = 0;
    $!savedKeyFocus = 0;
  }

  method state is rw {
    Proxy.new:
      FETCH => -> $ { $!state },

      STORE => -> $, \st {
        return unless $!state != st;

        self.notify( $!state = st );
      }
  }

  method key_press_event is vfunc {
    return CLUTTER_EVENT_STOP
      if global.focus-manager.navigate-from-event(
        Mutter::Clutter.get-current-event
      );

    return CLUTTER_EVENT_PROPAGATE
  }

  method captured_event ($event) is vfunc {
    return CLUTTER_EVENT_STOP if Main.keyboard.maybeHandleEvent($event);

    return CLUTTER_EVENT_PROPAGATE
  }

  method clearButtons {
    $!dialogLayout.clearButtons;
  }

  method setButtons (%buttons) {
    self.clearButtons;

    self.addButton($_) for %buttons.pairs;
  }

  method addButton (Pair $buttonInfo) {
    $!dialogLayout.addButton($buttonInfo);
  }

  method fadeOpen ($onPrimary) {
    if $onPrimary {
      $!monitorConstraint.primary = True;
    } else {
      $monitorConstraint.index = global.display.get-current-monitor();
    }

    self.state             = OPENING;
    $!dialogLayout.opacity = 255;
    $!lightbox.lightOn if $!lightbox;
    self.opacity = 0;
    self.show;
    self.ease(
      opacity => 255,
      $!shouldFadeIn ?? OPEN_AND_CLOSE_TIME !! 0,
      CLUTTER_ANIMATION_MODE_EASE_OUT_QUAD,
      onComplete => -> *@a {
        self.state = OPENED;
        %!Signals<opened>.emit;
      }
    );
  }

  method setInitialKeyFocus ($actor) {
    $!initialKeyFocus.disconnectObject(self) if $!initialKeyFocus;
    $!initialKeyFocus = $actor;

    my $ikf := $!initialKeyFocus;
    $actor.destroy.tap( -> {
      $ikf.disconnectObject(self);
      $ikf = Nil;
    });
  }

  method open ($timestamp, $onPrimary) {
    return True  if $!state == (OPEN, OPENING).any;
    return False if self.pushModal($timestamp);

    self.fadeOpen($onPrimary);
    True;
  }

  method closeComplete {
    self.state = CLOSED;
    self.hide;
    %!Signals<closed>.emit;
    self.destroy if $!destroyOnClose;
  }

  method close ($tikmestamp) {
    return if $!state == (CLOSED, CLOSING).any;
    self.state = CLOSING;
    self.popModal($timestamp);
    $!savedKeyFocus = Nil;

    if $!shouldFadeOut {
      self.ease(
        opacity => 0,
        OPEN_AND_CLOSE_TIME,
        CLUTTER_ANIMATION_MODE_EASE_OUT_QUAD,
        onComplete => -> *@a { self.closeComplete }
      );
    } else {
      self.closeComplete;
    }
  }

  method popModal ($timestamp) {
    return if self.hasModal;

    my $focus = global.stage.key-focus;
    if $focus && self.contains($focus) {
      $!savedKeyFocus = $focus;
    } else {
      $!savedKeyFocus = Nil;
    }
    Main.popModal($!grab, $timestamp);
    ($!grab, $!hasModal) = (Nil, False);

    $!backgroundStack.set-child-above-sibling($!evengBlocker)
      if $!shellReactive.not;
  }

  method pushModal ($timestamp?) {
    return if $!hasModal;

    my %params = (
      actionMode => $!actionMode
    );
    %params<timestamp> = $timestamp if $timestamp;
    my $grab = Main.pushModal(self, %params);
    if $grab.get-seat-state != CLUTTER_GRAB_STATE_ALL {
      Main.popModal($grab);
      return False;
    }

    $!grab = $grab;
    Main.layoutManager.emit('system-modal-opened');

    $!hasModal = True;
    if $!savedKeyFocus {
      $!savedKeyFocus.grab-key-focus;
      $!savedKeyFocus = Nil;
    } else {
      if $!initialKeyFocus // $!dialogLayout.initialKeyFocus -> $kf {
        $kf.grab-key-focus
      }
    }

    $!backgroundStack.set-child-below-sibling($!eventBlocker)
      if $!shellReactive;
    True;
  }

  method fadeOutDialog ($timestamp) {
    return if $!state eq (CLOSED, CLOSING, FADED_OUT).any;

    self.popModal($timestamp);

    my $s := $!state;
    $!dialogLayout.ease(
      opacity => 0,
      FADE_OUT_DIALOG_TIME,
      CLUTTER_ANIMATION_MODE_EASE_OUT_QUAD,
      onComplete => -> *@a { $s = FADED_OUT }
    );
  }

}
