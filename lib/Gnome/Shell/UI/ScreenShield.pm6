use v6.c;

use Graphene::Point;
use Accounts::UserManager;
use Gnome::Shell::Misc::Signals;
use Gnome::Shell::UI::MessageTray;
use Gnome::Shell::UI::Overview;

### /home/cbwood/Projects/gnome-shell/js/ui/screenShield.js

constant SCREENSAVER_SCHEMA = 'org.gnome.desktop.screensaver';
constant LOCK_ENABLED_KEY   = 'lock-enabled';
constant LOCK_DELAY_KEY     = 'lock-delay';
constant LOCKDOWN_SCHEMA    = 'org.gnome.desktop.lockdown';
constant DISABLE_LOCK_KEY   = 'disable-lock-screen';
constant LOCKED_STATE_STR   = 'screenShield.locked';
constant STANDARD_FADE_TIME = 10000;
constant MANUAL_FADE_TIME   = 300;
constant CURTAIN_SLIDE_TIME = 300;

class Gnome::Shell::UI::ScreenShield
  is Gnome::Shell::Misc::Signals::EventEmitter
{
  has $!cursorTracker;
  has $!lockDialogGroup;
  has $!lockScreenGroup;
  has $!lockScreenState;
  has $!lockSettings;
  has $!loginManager;
  has $!loginSession;
  has $!longLightbox;
  has $!presence;
  has $!screenSaverDBus;
  has $!settings;
  has $!shortLightbox;
  has $!smartcardManager;

  has $.actor;

  has $!isModal           = False;
  has $!isGreeter         = False;
  has $!inUnlockAnimation = False;
  has $!inhibited         = False;
  has $!becameActiveId    = 0;
  has $!lockTimeoutId     = 0;
  has $!credentialMaagers = %{ };

  has $.isActive          = False;
  has $.isLocked          = False;
  has $.activationTime    = 0;

  submethod BUILD {
    $!actor           = Main.layoutManager.screenShieldGroup.new;
    $!lockScreenState = MessageTray.State.HIDDEN;
    $!lockScreenGroup = Gnome::Shell::St.Widget.new(
      x-expand  => True,
      y-expand  => True,
      reactive  => True,
      can-focus => True,
      name      => 'lockScreenGroup',
      visible   => False,
    }

    $!lockDialogGroup = Gnome::Shell::St::Widget.new(
      x-expand    => True,
      y-expand    => True,
      reactive    => True,
      can-focus   => True,
      pivot-point => Graphene::Point.new(x => 0.5, y => 0.5),
      name        => 'lockDialogGroup'
    );

    $.actor.add_child($_) for $!lockScreenGroup, $!lockDialogGroup;

    $!presence = Gnome::Shell::Misc::Session::Presence(
      sub ($p, $e) {
        if $e {
            $*ERR.say: "Error while reading gnome-session presence: {
                        $e.message }";
            return;
        }

        self.onStatusChanged($p.status);
    });
    $!presence.StatusChanged.tap: sub ($, $, $S) {
        $!onStatusChanged($s.status);
    });

    constant SCM = Gnome::Shell::Misc::Smartcard::Manager;

    $!screenSaverDBus  = Gnome::Shell::UI::DBus::ScreenSaver.new(self);
    $!smartcardManager = SCM.getSmartcardManager();
    $!smartcardManager.Smartcard-Inserted.tap: sub ($m, $t) {
      self.activateDialog if $!isLocked && $t.UsedToLogin;
    });

    self.addCredentialManager(
      OVirt.SERVICE_NAME,
      OVirt.getOVirtCredentialsManager()
    );

    $!loginManager = Gnome::Shell::Misc::LoginManager.getLoginManager();
    $!loginManager.Prepare-For-Sleep.tap: SUB {
      self.prepareForSleep
    }

    self.getLoginSession;

    $!settings = GIO::Settings.new(SCREENSAVER_SCHEMA);
    $!settings.changed(LOCK_ENABLED_KEY).tap: SUB { self.syncInhibitor }

    $!lockSettings = GIO::Settings.new(LOCKDOWN_SCHEMA);
    $!lockSettings.changed(DISABLE_LOCK_KEY).tap: SUB { self. syncInhibitor }

    $!longLightbox = Gnome::Shell::UI::Lightbox.new(
      Main.uiGroup,
      inhibitEvents => True,
      fadeFactor    => 1,
    );
    $!longLightbox.notify('active').tap: SUB { self.onLongLightbox }
    $!shortLightbox = Gnome::Shell::UI::Lightbox.new(
      Main.uiGroup,
      inhibitEvents => True,
      fadeFactor    => 1
    }
    $!shortLightbox.notify('active').tap: sub { self.onShortLightbox }
    $!idleMonitor   = Global.backend.core-idle-monitor;
    $!cursorTracker = Mutter::Meta::CursorTracker.get-for-display(
      Global.display
    );

    self.syncInhibitor;
  }

  method getLoginSession is asynchronous {
    start {
      $!loginSession = await $!loginManager.getGurrentSessionProxy;
      $loginSession.Lock.tap:                 SUB { self.lock }
      $loginSession.Unlock.tap:               SUB { self.deactivate }
      $loginSession.g-properties-changed.tap: SUB { self.syncInhibitor }

      self.syncInhibitor;
    }
  }

  method setActive ($active = False) {
    my $p = $!isActive;
    $!isActive = $active;
    $.emit('active-changed') unless $p == $!isActive;
    $.syncInhibitor;
  }

  method setLocked ($locked = False) {
    my $p = $!isLocked;
    $!isLocked = $locked;
    $.emit('locked-changed') unless $p == $!isLocked;

    with $!loginSession {
      CATCH { default { $*ERR.say: .message } }

      .SetLockedHintAsync($locked)
    }
  }

  method activateDialog {
    if $!isLocked {
      $.ensureUnlockDialog( :canCancel );
      $!dialog.activate;
    } else {
      $.deactiate( :animate );
    }
  }

  method maybeCancelDialog {
    return unless $!dialog;
    $!dialog.cancel;
    $!dialog.grab-key-focus if $!isGreeter;
  }

  method becomeModal {
    return True if $!isModal;

    my $g = Main.pushModal(
      Main.uiGroup,
      actionMode => GNOME_SHELL_ACTION_MODE_LOCK_SCREEN
    )

    ( $!isModal = $g.seat-state +& CLUTTER_GRAB_KEYBOARD )
      ?? $!grab = $g
      !! Main.popModal($g);

    $!isModal;
  }

  method syncInhibitor is asynchronous {
    start {
      my $i = [&&](
        $!loginSession,
        $!loginSession.Active,
        $!isActive,
        $!settings{LOCK_ENABLED_KEY},
        $!lockSettings{DISABLE_LOCK_KEY}.not,
        Main.sessionMode.unlockDialog.not
      )

      return if $i == $!inhibited;

      $!inhibited = $i;
      $!inhibitCancellable?.cancel;
      $!inhibitCancellble = GIO::Cancellable.new;

      if $i {
        CATCH {
          default {
            #...
          }
        }

        $!inhibitor = await $!loginManager.inhibit(
          'Gnome needs to lock the screen',
          $inhibitCancellable
        );
      } else {
        $!inhibitor?.close;
        $!inhibitor = Nil;
      }
    }
  }

  method prepareForSleep ($l, $a) {
    $a ?? ( $.lock( :animate ) if $!settings{LOCK_ENABLED_KEY} )
        !!  $.wakeUpScreen;
  }

  method onStatusChanged ($s) {
    return unless $s != GNOME_SESSION_PRESENCE_IDLE;

    $.maybeCancelDialog;

    return if $!longLightbox.visible;

    unless $.becomeModal {
      Main.notifyError(
        'Unable to lock',
        'Lock was blocked by an app'
      );
      return;
    }

    $!activationTime ||= GLib::timeout.monotonic-time;

    if $!settings{LOCK_ENABLED_KEY} && $!isLocked.not {
      my $lt = max(
        adjustAnimationTime(STANDARD_FADE_TIME),
        $!settings{LOCK_DELAY_KEY} * 1000
      );
      $!lockTimeoutId = GLib::Timeout.add(
        $lt,
        sub {
          $!lockTimeoutId.clear;
          self.lock;
          G_SOURCE_REMOVE
        },
        name => '[raku-gnome-shell] self.lock'
      );
    }

    $.activateFade($!longLightBox, STANDARD_FADE_TIME);
  }

  method activateFade($l, $t) {
    Main.uiGroup.set-child-above-sibling($l);
    $l.lightOn($t);
    $!becameActiveId ||= $!idleMonitor.add-user-active-watch(
      SUB { self.onUserBecameActive }
    );
  }

  method onUserBecameActive {
    $!idleMonitor.?clear;

    if $!isLocked {
      .lightOff for $!longLightBox, $!shortLightBox
    } else {
      $.deactivate( :animate );
    }
  }

  method onLongLightbox ($l) {
    $.activate if $l.active;
  }

  method onShortLightBox ($l) {
    $.completeLockScreenShown if $lo.active;
  }

  method showDialog {
    unless $.becomeModal {
      Global.context.terminate-with-error(
        GError.new(
          domain => GIO::Error.quark,
          code   => G_IO_ERROR_FAILED
        )
      );
    }

    $!actor.show;
    ($!isGreeter, $!isLocked) = (Main.sessionMode.isGreeter, True);
    $.ensureUnlockDialog( :canCancel );
  }

  method hideLockScreenComplete {
    $!lockScreenState = GNOME_MESSAGE_TRAY_HIDDEN;
    $!lockScreenGroup.hide;
    if $!dialog {
      $!dialog.grab-key-focus;
      $!dialog.navigate-focus(ST_DIR_TAB_FORWARD);
    }
  }

  method showPointer {
    $!cursorTracker.pointer-visible = True;
    $!motionId.?clear;
  }

  method hidePointerUntilMotion {
    $!motioinId = Global.stage.Captured-Event.tap: SUB {
      self.showPointer if $*A[1].type == CLUTTER_EVENT_MOTION;
      CLUTTER_EVENT_PROPAGATE;
    }
    $!cursorTracker.pointer-visible = True;
  }

  method hideLockScreen ( :$animate = False ) {
    return if $!lockScreenState == MESSAGE_TRAY_STATE_HIDDEN;
    $!lockScreenState = MESSAGE_TRAY_STATE_HIDING;
    $!lockDialogGroup.remove-all-transitions;

    my \h = Global.state.height;
    my \d = h + $!lockDialogGroup.translation-y;
    my \v = h / CURTAIN_SLIDE_TIME;
    my $d = $animate ?? d / v !! 0;

    $!lockDialogGroup.ease(
      translation-y => -h
      duration      => $d,
      mode          => CLUTTER_EASE_OUT_QUAD,
      onComplete    => SUB { self.hideLockScreenComplete }
    );

    $.showPointer;
  }

  method ensureUnlockDialog ( :canCancel(:$allowCancel) = False ) {
    unless $!dialog {
      my c = Main.sessionMode<unlockDialog>;
      if c === Any {
        $.deactivate( :animate );
        return False
      }

      $!dialog = c.new($!lockDialogGroup);

      unless $!dialog.open {
        $*ERR.say: 'Could not open login dialog: failed to acquire grab';
        $.deactivate( :animate );
        return False;
      }

      $!dialog.Failed.tap: SUB { self.onUnlockFailed }
      $!wakeUpScreenId = $!dialog.Wake-Up-Screen.tap: SUB {
        self.wakeUpScreen
      }
    }

    $!dialog.allowCancel = $allowCancel;
    $!dialog.grab-key-focus;
    True;
  }

  method onUnlockFailed {
    $.resetLockScreen(
      animateLockScreen => True,
      fadeToBlack       => False
    );
  }

  method resetLockScreen (
    :animate(:$animateLockScreen),
    :fade($fadeToBlack)
  ) {
    return unless $!lockScreenState == MESSAGE_TRAY_STATE_HIDDEN;

    $!lockScreenGroup.show;
    $!lockScreenState = MESSAGE_TRAY_STATE_SHOWING;

    if $animateLockScreen {
      $!lockDialogGroup.translation-y = -Global.screen-height;
      $!lockDialogGroup.remove-all-transitions;
      $!lockDialogGroup.ease(
        translation-y => 0,
        duration      => OVERVIEW_ANIMATION_TIME,
        mode          => CLUTTER_EASE_OUT_QUAD,
        onComplete    => SUB {
          self.lockScreenShown(
            :$fadeToBlack,
            :!animate
          );
        }
      );
    } else {
      $!lockDiualogGroup.translation-y = 0;
      $.lockScreenShown( :$fadeToBlack, :!animate );
    }

    $!dialog.grab-key-focus;
  }

  method lockScreenShow (
    :animate(:$animateLockScreen),
    :fade(:$fadeToBlack)
  ) {
    $.hidePointerUntilMotion;
    $!lockScreenState = MESSAGE_TRAY_STATE_SHOWNL

    if $fadeToBlack && $animateLockScreen {
      GLib::Timeout.add(
        name => '[raku-gnome-shell self.activateFade',
        MANUAL_FADE_TIME,
        SUB {
          self.activateFade($!shortLightbox, MANUAL_FADE_TIME);
          G_SOURCE_REMOVE
        }
      );
    } else {
      $.activateFade($!shortLightbox, 0);
      $.completeLockScreenShown
    }
  }

  method completeLockScreenShown {
    $.setActive(True);
    $.emit('lock-screen-shown');
  }

  method wakeUpScreen {
    return unless $!active;
    $.onUserBecameActive;
    $.emit('wake-up-screen');
  }

  method deactivate ( :$animate = False ) {
    $!dialog
      ??  $!dialog.finish(
            SUB { self.continueDeactivate( :$animate ) }
          )
      !!  $.continueDeactivate( :$animate )
  }

  method continueDeactivate ( :$animate = False ) {
    $.hideLockScreen( :$animate );
    Main.sessionModfe.popMode('unlock-dialog')
      if Main.sessionMode<currentMode> eq 'unlock-dialog';

    $.emit('wake-up-screen');

    if $!isGreeter {
      $!activationTime = 0;
      $.setActive(False);
      return;
    }

    $!popModal if $!dialog && $!isGreeter.not;

    if $!isModal {
      Main.popModal($!grab);
      ($!grab, $!isModal) = (Nil, False);
    }

    .lightOff for $!longLightbox, $!shortLightbox;

    $!lockDialogGroup.ease(
      translation-y => -Global.screen-height,
      duration      => OVERVIEW_ANIMATION_TIME,
      mode          => CLUTTER_EASE_OUT_QUAD,
      onComplete    => SUB { self.completeDeactivate }
    );
  }

  method completeDeactivate {
    if $!dialog {
      $!dialog.destroy;
      $!dialog = Nil;
    }

    $!actor.hide;

    .?clear for $!becameActiveId, $!lockoutTimeoutId;

    $!activationTime = 0;
    $.setActive(False);
    $.setLocked(False);
    Global.set-pruntime-state(LOCKED_STATE_STR);
  }

  multi activate ( :$animate = False ) {
    $!activationTime ||= GLib::Timeout.monotonic-time;

    return unless $.ensureUnlockDialog;

    $!actor.show;

    if Main.sessionMode<currentMode> ne 'unlock-dialog' {
      Main.sessionMode.pushMode('unlock-dialog')
        unless ( $!isGreeter = Main.sessionMode<isGreeter> );
    }

    $.resetLockScreen( :$animate, :fadeToBlack );

    Global.set-runtime-state(
      LOCKED_STATE_STR,
      GLib::Variant.new(True, :b)
    ) if Meta::Util.is-wayland-compositor;
  }

  method addCredentialManager ($sn, $cm) {
    return unless $!credentialManager{$sn};

    $!credentialManager{$sn} = $cm;
    $cm.connectObject(
      User-Authenticated => SUB {
        self.activateDialog if $!isLocked;
      }
    );
  }

  method removeCredentialManager ($sn) {
    return unless ( my $cm = $!credentialManager{$sn} );

    $!cedentialManager.disconnectObject(self);
    $!credentialManager{$sn}:delete;
  }

  method lock ( :$animate = False ) {
    if $!lockSettings{DISABLE_LOCK_LEY} {
      $*ERR.say: "Screenlock is logned down, not locking";
      return;
    }

    unless $.becomeModal {
      Main.notifyError(
        'Unable to lock',
        'Lock was blocked by an app'
      );
      return;
    }

    Gnome::Shell::St::Clipboard.default.set_text($_, '')
      for ST_CLIPBOARD_TYPE_CLIPBOARD,
          ST_CLIPBOARD_TYPE_PRIMARY;

    my $um = AccountsService::UserManager.default;
    my $u  = $um.get-user(GLib::Utils.user-name);

    $.activate( :$animate );

    $.setLocked(
      $!isGreeter
        ?? True
        !! ($u.password-mode != ACT_USER_PASSWORD_MODE_NONE)
    )
  }

  method lockIfWasLocked {
    return unless $!settings{LOCK_ENABLED_KEY};
    return without Global.get-runtime-state('b', LOCKED_STATE_STR);
    Global.compositor.laters.add(
      META_LATER_BEFORE_REDRAW,
      SUB {
        self.lock;
        G_SOURCE_REMOVE
      }
    );
  }

}
