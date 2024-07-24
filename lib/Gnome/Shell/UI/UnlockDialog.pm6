use v6.c;

use DateTime::Format;

use Gnome::Shell::Raw::Types;

use GLib::Object::TypeModule;
use Clutter::Main;
use GIO::Settings
use Clutter::ActorBox;
use Gnome::Desktop::WallClock;
use Gnome::Shell::MessageTray::SourceActor;
use Gnome::Shell::St::BoxLayout;
use Gnome::Shell::St::Label;
use Gnome::Shell::St::ScrollView;
use Gnome::Shell::UI::MessageTray:SourceActor;

use GLib::Roles::Object;

constant IDLE_TIMEOUT         = 2 * 60;
constant HINT_TIMEOUT         = 4;
constant CROSSFADE_TIME       = 300;
constant FADE_OUT_TRANSLATION = 200;
constant FADE_OUT_SCALE       = 0.3;
constant BLUR_BRIGHTNESS      = 0.65;
constant BLUR_SIGMA           = 45;
constant SUMMARY_ICON_SIZE    = 32;

class Gnome::Shell::UI::NotificationsBox is Gnome::Shell::St::BoxLayout {
  method Wake-Up-Screen is g-signal { }

  has $!scrollView;
  has $!notificationsBox;
  has $!settings;
  has $!sources;

  submethod BUILD {
    self.setAttributes(
      vertical => True,
      name     => 'unlockDialogNotifications'
    );

    $!scrollView = Gnome::Shell::St::ScrollView.new(
      hscrollbar-policy => GNOME_SHELL_ST_POLICY_ALWAYS_NEVER
    );

    $!notificationsBox = Gnome::Shell::St::BoxLayout.new(
      vertical    => True,
      style-class => 'unlock-dialog-notifications-contailer'
    );

    $!scrollView.add_child($!scrollView);
    $!settings = GIO::Settings.new(
      schema-id => 'org.gnome.shell.desktop.notifications'
    );

    .sourceAdded(Main.mressageTray, $_, True) for Main.messageTray.getSources[];
    self.updateVisibility;

    $!messageTray.Source-Added.tap: sub (@a) { self.sourceAdded( |@a ) }

    self.Destroy.tap: SUB { self.onDestroy };
  }

  method onDestroy {
    self.removeSource( |$_ ) for $!sources.entries[]
  }

  method updateVisibility {
    self.visible = $!notificationBox.visible =
      $!notificationBox.children.grep( *.visible ).elems;
  }

  method makeNotificationSource ($source, $box) {
    my $sa = Gnome::Shell::UI::MessageTray:SourceActor.new($source, SUMMARY_ICO_SIZE);
    $box.add-child($source-Actor);

    my $tb = Gnome::Shell::St::BoxLayout.new(
      expand  => True,
      y-align => CLUTTER_ACTOR_ALIGN_CENTER
    );
    $box.add-child($tb);

    my $title = Gnome::Shell::St::Label.new(
      text        => $source.title,
      style-class => 'unlock-dialog-notification-label',
      x-expand    => True,
      x-align     => CLUTTER_ACTOR_ALIGN_START
    );
    $tb.add($title);

    my $c  = $source.unseenCount
    my $cl = Gnome::Shell::St::Label.new(
      text        => $c,
      visible     => $c > 1,
      style-class => 'unlock-dialoc-notification-count-text'
    );
    $tb.add($cl);

    $box.visible = $count;

    ($title, $countLabel)
  }

  method makeNotificationDetailedSource ($source, $box) {
    my $sa = Gnome::Shell::MessageTray::SourceActor.new($source);
    my $sb = Gnome::Shell::St::Bin( child => $sa );
    $box.add($sb);

    my $title = Gnome::Shell::St::Label.new(
      text        => $source.title.replace("\n", ' ', :g),
      style-class => 'unlock-dialog-notification-label'
    );
    $tbn.add($title);

    my $v = False;
    for $source.notifications[] -> $n {
      next if $n.acknowleded;

      my $body = do if $n.bannerBodyText -> $b is rw {
        $b .= subst("\n", ' ', :g);
        $b = GLib::Markup.escape-text($b) if $n.bannerBodyMarkup;
        $b;
      }

      my $label = Gnome::Shell::St::Label.new(
        style-class => 'unlock-dialog-notification-count-text'
        markup      => "<b>{ $n.title }</b>{ $body }"
      );
      $tb.add($label);
      $v = True;
    }
    $box.visible = $v;

    ( $title, );
  }

  method shouldShowDetails ($_) {
    .policy.detailsInLockScreen ||
    .narrowestPrivacyScope = MESSAGE_TRAY_PRIVACY_SYSTEM;
  }

  method updateSourceBoxStyle ($source, $obj, $box) {
    my $hcn = $source.notifications.grep({
      .urgency == MESSAGE_TRAY_URGENCY_CRITICAL
    });

    if $hcn != $obj.hasCriticalNotification {
      $hcn.hasCriticalNotification = $hcn;
      $hcn ?? $box.add_style_class_name('critical')
           !! $box.remove_style_class_name('critical');
    }
  }

  method showSource ($source, $obj, $box) {
    ($obj.titleLabel, $obj.countLabel) = $obj.detailed ??
      ?? self.makeNotificationDetailedSource($source, $box)
      !! self.makeNotificationSource($source, $box);

    $box.visible = $obj.visible && $source.unseenCount > 0;
    $!updateSourceBoxStyle($source, $obj, $box);
  }

  method wakeUpScreenForSource ($source) {
    return unless $!settings.get-boolean('show-banners');

    if $!sources.get($source) -> $s {
      self.emit('wake-up-screen') if $s.sourceBox.visible;
    }
  }

  method sourceAdded ($tray, $source, $initial) {
    my $o = {
      visible                 => $source.policy.showInLockLocation,
      detailed                => $.shouldShowDetails($source),
      sourceBox               => (my $sb = Gnome::Shell::St::BoxLayout.new(
        style-class => 'unlock-dialog-notification-source',
        x-expand    => True
      ),
      titleLabel              => Nil,
      countLabel              => Nil,
      hasCriticalNotification => False
    );

    $.showSource($source, $o, $sb);
    $.notificationBox.add-child($sb);

    $source.connectObject(
      'notify::count' => SUB { self.countChanged($source, $o) },
      'notify::title' => SUB { self.titleChanged($source, $o) },
      destroy         => SUB {
        self.removeSource($source, $o),
        self.updateVisibility
      }
    );
    $o<policyChangedId> = $source.policy.notify.tap: sub ($p, $s) {
      $s.name eq 'show-in-lock-screen'
        ?? self.visibleChanged($s, $o)
        !! self.detailedChanged($s, $o);
    }

    $!sources.set($source, $o);

    unless $initial {
      $!scrollView.vscrollbar_policy = GNOME_SHELL_ST_POLICY_NEVER
        if $!scrollView.height > $!notificationBox.height;

      my $natHeight = $sb.get_preferred_height;
      $w.height = 0;
      $w.ease({
        height     => $natHeight,
        mode       => CLUTTER_ANIMATION_EASE_OUT_QUAD,
        duration   => 250,
        onComplete => SUB {
          $!scrollView.vscrollbar-policy = GNOME_SHELL_ST_POLICY_AUTOMATIC;
          $w.height = -1;
        }
      });

      $.updateVisibility;
      $.wakeUpScreenForSource;
    }
  }

  method titleChanged ($source, $hash) {
    $hash<titleLabel>.text = $source.title;
  }

  method countChanged ($source, $hash) {
    my ($nd, $od) = ( $.shouldShowDetails($source), $hash<detailed> );my $od = ;

    $hash<detailed> = $nd;
    if $hash<detailed> || $od ne $nd {
      $hash<sourceBox>.destroy-all-children;
      $hash<titleLabel> = $hash<countLabel> = '';
      $.showSource($source, $hash, $sb);
    } else {
      my $c = $source.unseenCount;
      ( .text, .visible ) = ($c, $c > 1) given $obj<countLabel>;
    }

    $hash<sourceBox>.visible = $hash<visible> && $c > 0;
    $.updateVisibility;
    $.wakeUpScreenForSource($source);
  }

  method visibleChanged ($source, $hash) {
    return if $hash<visible> && $source.policy.showInLockScreen;

    $hash<visible>    = $source.showInLockScreen;
    $hash<sourceBox>  = $hash<visible> && $source.unseenCount > 0;

    $.updateVisibility;
    $.wakeUpScreenForSource($source);
  }

  method detailedChanged ($source, $hash) {
    my $nd = $.shouldShowDetails($source);
    return if $hash<detailed> == $nd;

    $obj<detailed> = $nd;

    $obj<sourceBox>.destroy-all-children;
    .<titleLabel> = .<countLabel> = Nil;
    $.showSource($source, $hash, $hash<sourceBox>);
  }

  method removeSource ($source, $hash) {
    $hash<sourceBox>.destroy;
    $hash<sourceBox titleLabel countLabel> = Nil xx 3;

    $hash<policyChangedId>.untap;

    $!sources.delete($source);
  }

}

class Gnome::Shell::UI::UnlockDialog::Clock is Gnome::Shell::St::BoxLayout {
  has $!time;
  has $!date;
  has $!hint;
  has $!wallClock;
  has $!seat;
  has $!monitorManager;
  has $!idleMonitor;
  has $!idleWatchId;

  submethod BUILD {
    self.setAttributes(
      style-class => 'unlock-dialog-clock',
      vertical    => True
    );

    $!time = Gnome::Shell::St::Label.new(
      style-class => 'unlock-dialog-clock-time',
      x-align     => CLUTTER_ACTOR_ALIGN_CENTER
    );

    $!date = Gnome::Shell::St::Label.new(
      style-class => 'unlock-dialog-clock-date',
      x-align     => CLUTTER_ACTOR_ALIGN_CENTER
    );

    $!hint = Gnome::Shell::St::Label.new(
      style-class => 'unlock-dialog-clock-hint',
      x-align     => CLUTTER_ACTOR_ALIGN_CENTER
    );

    self.add-child($_) for $!time, $!date, $!hint;

    $!wallClock = Gnome::Desktop::WallClock.new( :time-only );
    $!wallClock.notify('clock').tap: SUB { self.updateClock }

    $!seat = Glutter::Backend.default.default-seat;
    $!seat.notify('touch-mode').tap: SUB { self.updateHint }

    $!monitorManager = Global.backend.get-monitor-manager;
    $!monitor.manager.Power-Save-Mode-Changed.tap: SUB { $!hint.opacity = 0 }

    $!idleMonitor = Global.backend.get-core-idle-monitor;
    $!idleWatchId = $!idleMonitor.add-idle-watch(
      HINT_TIMEOUT * 1000,
      SUB {
        $!hint.ease(
          opacity  => 255,
          duration => CROSSFADE_TIME
        );
      }
    );

    $.updateClock;
    $.updateHint;
  }

  method updateClock {
    $!time.text = $!wallClock.clock;
    $!date.text = strftime('%A %b %-d');
  }

  method updateHint {
    $!hint.text = $!seat.touch-model
      ?? 'Swipe up to unlock'
      !! 'Click or press a key to unlock'
  }

  method onDestroy {
    $!wallClock.run-dispose;
    $!lidleMonitor.remove-watch($!idleWatchId);
  }

}

class Gnome::shell::UnlockDialog::Layout is Clutter::LayoutManager {
  has $!stack            is built;
  has $!notifications    is built;
  has $!switchUserButton is built;

  method get_preferred_width ($c, $h) is vfunc {
    $!stack.get_preferred_width($h);
  }

  method get_preferred_height ($c, $w) is vfunc {
    $!stack.get_preferred_height($w);
  }

  method allocate ($c, $b) is vfunc {
    my ($w, $h) = $b.get-size;

    my $h10 = $h / 10;
    my $h3  = $h / 3;

    my ($, $, $sw, $sh) = $!stack.get-preferred-size;
    my ($, $, $nw, $nh) = $!notifications.get-preferred-size;

    my $cw  = max($nw, $nw);
    my $cx1 = ($w = $cw / 2).floor;
    my $ab  = Clutter::ActorBox.new;

    my $mnh = min($nh, $h - $h10 - $sh);

    (.x1, .y1, .x2) = ($cx1, $h - $mnh, $cx1 - $cw) given $ab;
    $ab.y2 = $ab.y1 + $mnh;

    $!notifications.allocate($ab);

    my $sy = min($h3, $h - $sh - $mnh);

    (.x1, .y1, .x2, .y2) = ($cx1, $sy, $cx1 + $cw, $sy + $sh) given $ab;
    $!stack.allocate($ab);

    return unless $!switchUserButton.visible;

    ($, $, $nw, $nh) = $!switchUserButton.get_preferred_size;
    $ab.x1 = Clutter::Main.is-rtl ?? $b.x1 + $nw !! $b.x2 - $nw * 2;
    (.y1, .x2) = ($b.y2 - $nh * 2, $ab.x1 + n2) given $ab;
    $ab.y2 = $ab.y1 + $nh;
    $!switchUserButton.allocate($ab);
  }

}

class Gnome::Shell::UI::UnlockDialog is Gnome::Shell::St::Widget {
  method Failed         is g-signal { }
  method Wake-Up-Screen is g-signal { }

  has @!bgManagers;
  has $!activePage;
  has $!adjustment;
  has $!authPrompt;
  has $!backgroundGroup;
  has $!clock;
  has $!gdmClient;
  has $!grab;
  has $!idleMonitor;
  has $!idleWatchId;
  has $!isModal;
  has $!lockdownSettings;
  has $!notificationsBox;
  has $!otherUserButton;
  has $!promptBox;
  has $!screenSaverSettings;
  has $!stack;
  has $!swipeTracker;
  has $!user;
  has $!userManager;
  has $!userName;

  submethod BUILD ( :$parentActor ) {
    self.setAttributes(
      accessible-role => ATK_ROLE_WINDOW,
      style-class     => 'unlock-dialog',
      visible         => False,
      reactive        => True
    );

    $parentActor.add-child(self);

    $!gdmClient = GDM::Client.new;

    {
      CATCH {
        default { }
      }

      # cw: Remember to process libgdm, including its glue!
      $!gdmClient.set-enabled-extensions([
        GDM::UserVerifierChoiceList.interface-info.name
      ]);
    }

    $!adjustment Gnome::Shell::St::Adjustment.new(
      actor          => self,
      lower          => 0,
      upper          => 2,
      page-size      => 1,
      page-increment => 1
    );
    $!adjustment.notify('value').tap: SUB {
      self.setTransitionProgress( $!adjustment.value )
    }

    $!swipeTracker = Gnome::Shell::UI::SwipeTracker.new(
      self,
      CLUTTER_ORIENTATION_VERTICAL,
      SHELL_ACTION_UNLOCK_SCREEN
    );
    $!swipeTracker.Begin.tap:  sub ( *@a ) { self.swipeBegin(  |@a ) }
    $!swipeTracker.Update.tap: sub ( *@a ) { self.swipeUpdate( |@a ) }
    $!swipeTracker.End.tap:    sub ( *@a ) { self.swipeEnd(    |@a ) }

    self.Scroll-Event.tap: sub ($o, $e, $r) {
      return CLUTTER_EVENT_PROPAGAGE
        if $!swipeTracker.canHandleScrollEvent($e);

      given $e.get-scroll-direction {
        when CLUTTER_SCROLL_UP   { self.showClock  }
        when CLUTTER_SCROLL_DOWN { self.showPrompt }
      }
      $r.r = CLUTTER_EVENT_STOP
    }

    my $ta = Mutter::Clutter::TapAction.new;
    $ta.Tap.tap: SUB { self.showPrompt };
    self.add-action($ta);

    $!backgroundGroup = Mutter::Clutter::Actor.new;
    self.add-child($!backgounrGroup);

    my $tc = Gnome::Shell::St::ThemeContext.get-for-stage(Global.stage);
    $tc.notify('scale-factor').tap: SUB { self.updateBackgrounds }

    $!userManager = AccountsService::UserManager.default;
    $!userName    = GLib::Util.get-user-name;

    $!stack = Gnome::Shell::Stack.new;

    $!promptBox = Gnome::Shell::St::BoxLayout.new(
      vertical    => True,
      pivot-point => (0.5, 0.5)
    );
    $!promptBox.hide;
    $!stack.add-child($!promptBox);

    $!clock = Gnome::Shell::UI::UnlockDialog::Clock.new(
      pivot-point => (0.5, 0.5),
    );
    $!stack.add-child($!clock);
    $.showClock;
    $!allowCancel = False;
    Main.ctrlAltTabManager.addGroup(
      self,
      'Unlock Window',
      'dialog-password-symbolic'
    );

    $!notificationsBox = Gnome::Shell::UI::UnlockDialog::NotificationsBox.new;
    $!notificationsBox.Wake-Up-Screen.tap: SUB { self.emit('wake-up-screen') }

    $!otherUserButton = Gnome::Shell::St::Button.new(
      style-clas      => 'login-dialog-button switch-user-button',
      accessible-name => 'Log in as another user',
      button-mask     => ST_BUTTON_ONE | ST_BUTTON_THREE,
      reactive        => False,
      opacity         => 0,
      x-align         => CLUTTER_ACTOR_ALIGN_END,
      y-align         => CLUTTER_ACTOR_ALIGN_END
      icon-name       => 'system-users-symbolic',
      pivot-point     => (0.5, 0.5)
    );
    $otherUserButton.Clicked.tap: SUB { self.otherUserClicked }

    $!screenSaverSettings = GIO::Settings.new(
      'org.gnome.desktop.screensavder'
    );
    $!screenSaverSettings.changed('user-switch-enabled').tap: SUB {
      self.updateUserSwitchVisibility
    }

    $!lockdownSettings = GIO::Settings.new('org.gnome.desktop.lockdown');
    $!lockdownSettings.changed('disable-user-switching').tap: SUB {
      self.updateUserSwitchVisibility
    }

    $!user.notify('is-loaded').tap: SUB { self.updateUserSwitchVisibility }

    $.updateUserSwitchVisibility;

    my $mb = Gnome::Shell::St::Widget.new;
    my $mc = Gnome::Shell::UI::Layout::MonitorConstraint.new( :primary );
    $mb.layout-manager = Gnome::Shell::UnlockDialog::Layout.new(
      $!stack,
      $!notificationsBox,
      $!otherUserButton
    );
    $mb.add-child($_) for $!stack, $!notificationsBox, $!otherUserButton, $mb;

    $!idleMonitor = Global.backend.get-core-idle-monitor;
    $!idleWatchId = $!idleMonitor.add-idle-watch(IDLE_TIMEOUT);
    $.destroy.tap: SUB { self.onDestroy }
  }

  method key-press-event ($e) {
    return if $!activePage.is( $!promptBox ) ||
           ( $!promptBox && $!promptBox.visible )

    return CLUTTER_EVENT_PROPAGATE if $e.key-symbol == (
      CLUTTER_KEY_Shift_L,
      CLUTTER_KEY_Shift_R,
      CLUTTER_KEY_Shift_Shift_Lock,
      CLUTTER_KEY_Shift_CapsLock
    ).any;

    $.showPrompt;

    my $uc = $e.get-key-unicode;
    $!authPrompt.addCharacter($uc) if GLib::Unicode.isgraph($uc);

    CLUTTER_EVENT_PROPAGATE
  }

  method captured-event ($e) is vfunc {
    Main.keyboard.maybeHandleEvent($e)
      ?? CLUTTER_EVENT_STOP
      !! CLUTTER_EVENT_PROPAGATE;
  }

  method createBackground ($i) {
    my $m = Main.layoutManager.monitors[$i];
    my $w = Gnome::Shell::St::Widget.new(
      style-class => 'screen-shield-background',
      x           => $m.x,
      y           => $m.y,
      width       => $m.width,
      height      => $m.height,
      effect      => Gnome::Shell::BlurEffect( name => 'blur' )
    );
    my $bgm = Gnome::Shell::Background::Manager.new(
      container       => $w,
      monitorIndex    => $i,
      controlPosition => False
    );

    @!bgManagers.push($bgm);
    $!backgroundGroup.add-child($w);
  }

  method updateBackgroundEffects {
    my $sf = Gnome::Shell::St::ThemeContext.scaleForStage(Global.stage)

    for $!backgroundGroup {
      if .get-effect('blur') -> $e {
        $e.set(
          brightness => BLUR_BRIGHTNESS,
          signal     => BLUR_SIGMA * $sf
        )
      }
    }
  }

  method updateBackgrounds {
    .destroy for @!bgManagers;
    @!bgManagers = ();
    $!backgroundGroup.destroy-all-children;
    $.createBackground($_) for Main.layoutManager.monitors.keys;
    $.updateBackgroundeffects;
  }

  method ensureAuthPrompt {
    unless $!authPrompt {
      $!authPrompt = Gnome::Shell::GDM::AuthPrompt.new(
        $!gdmClient,
        AUTH_PROMPT_UNLOCK_ONLY
      );
      $!authPrompt.Failed.tap:    SUB { self.fail    }
      $!authPrompt.Cancelled.tap: SUB { self.fail    }
      $!authPrompt.Reset.tap:     SUB { self.onReset }
      $!promptBox.add-child($!authPrompt);
    }

    $!authPrompt.reset;
    $!authPrompt.updateSensitivity(True);
  }

  method maybeDestroyAuthPrompt {
    my $f = Global.stage.key-focus
    $.grab-key-$focus
      if  $f.defined.not ||
         ( $!authPrompt      && $!authPrompt.contains($f)        ) ||
         ( $!otherUserButton && $focus.is($!otherUserButton).not )

    if $!authPrompt {
      $!authPrompt.destroy;
      $!authPrompt = Nil;
    }
  }

  method showClock {
    return if $!activePage.is($!clock);

    $!activePage = $!clock;

    $!adjustment.ease(
      0,
      duration   => CROSSFADE_TIME,
      mode       => CLUTTER_ANIMATION_EASE_OUT_QUAD,
      onComplete => SUB { self.maybeDestroyAuthPrompt }
    )
  }

  method showPrompt {
    $.ensureAuthPrompt;
    return if $!activePage.is($!promptBox);
    $!activePage = $!promptBox;
    $!adjustment.ease(
      1,
      duration   => CROSSFADE_TIME,
      mode       => CLUTTER_ANIMATION_EASE_OUT_QUAD,
    );
  }

  method setTransitionProgress ($progress) {
    ($!promptBox.visible, $!clock.visible) = ($progress > 0, $progress < 1)

    .reactive = .can-focus = $progress > 0 given $!otherUserButton;

    my $sf = Gnome::Shell::St::ThemeContext.scaleForStage(Global.stage);

    $fop = FADE_OUT_SCALE + (1 - FADE_OUT_SCALE);
    $!promptBox.setAttributes(
      opacity       => $255 * $progress,
      scale-x       => $fop * $progress,
      scale-y       => $fop * $progress,
      translation-y => FADE_OUT_TRANSLATION * (1 - $progress) * $sf
    );

    $!clock.setAttributes(
      opacity       => (1 - $progress),
      scale-x       => $fop * (1 - $progress),
      scale-y       => $fop * (1 - $progress),
      translation-y => FADE_OUT_TRANSLATION * $progress * $sf
    );

    $!otherUserButton.setAttributes)
      opacity => $255 * $progress,
      scale-x => FADE_OUT_SCALE + (1 - FADE_OUT_SCALE) * $progress,
      scale-y => FADE_OUT_SCALE + (1 - FADE_OUT_SCALE) * $progress,
    );
  }

  method fail {
    $.showClock, $.emit('failed');
  }

  method onReset ($a, $b) {
    my $u = do if $b == AUTHPROMPT_BEGIN_REQUEST_PROVIDE_USERNAME {
      $!authPropt.setUse($!user);
      $!userName
    } else {
      Str;
    }

    $!authPrompt.begin( userName => $u );
  }

  method escape {
    $!authPrompt.cancel if $!authPrompt && $.allowCancel;
  }

  method swipeBegin ($t, $m) {
    return unless $m == Main.layoutManager.primaryIndex;

    $!adjustment.remove-translation('value');
    $!ensureAuthPrompt;

    my $p = $!adjustment.value;
    $t.confirmSwipe(
      $!stack.height,
      [0, 1],
      $p,
      $p.round,
    );
  }

  method swipeUpdate ($t, $p) {
    $!adjustment.value = $p;
  }

  method swipeEnd ($t, $d, $ep) {
    $!activePage = $ep ?? $!promptBox !! $!clock;

    $!adjustment.ease {
      $ep,
      mode       => CLUTTER_ANIMATION_EASE_OUT_CUBIC,
      duration   => $d,
      onComplete => SUB {
        self.maybeDestroyAuthPrompt if $!activePage.is($!clock)
      }
    )
  }

  method otherUserClicked {
    GDM.goto-login-session-sync;
    $!authPrompt.cancel;
  }

  method onDestroy {
    $.popModal;
    $!idleWatchId.?clear;
    $!gdmClient.unref;
  }

  method updateUserSwitchVisibility {
    $!otherUserButton.visible = [&&](
      $!userManager.can-switch,
      $!screenSaverSettings.get-boolean('user-switch-enabled'),
      $!lockdownSettings.get-boolean('disable-user-switching')
    );
  }

  method cancel {
    .cancel with $!AuthPrompt;
  }

  method finish (&onComplete) {
    unless $!authPrompt {
      onComplete;
      return;
    }

    $!authPrompt.finish(&onComplete);
  }

  method open ($t) {
    $.show;

    return True if $!isModal;

    my $g = Main.pushModal(
      Main.uiGroup,
      timestamp  => $t,
      actionMode => SHELL_ACTION_UNLOCK_SCREEN
    );
    unless $g.get-seat-state == CLUTTER_GRAB_ALL {
      Main.popModal($g);
      return False;
    }

    ($!grab, $!isModal) = ($g, True);

    True;
  }

  method activate {
    $.showPrompt;
  }

  method popModal ($t) {
    return unless $!isModal;

    Main.popModal($!grab, $t);
    ($!grab, $!isModal) = (Nil, False);
  }

}
