use v6.c;

use Method::Also;

use Gnome::Shell::Raw::Types;

### /home/cbwood/Projects/gnome-shell/js/ui/messageTray.js

constant SHELL_KEYBINDINGS_SCHEMA               = 'org.gnome.shell.keybindings';
constant ANIMATION_TIME               is export = 200;
constant NOTIFICATION_TIMEOUT                   = 4000;
constant HIDE_TIMEOUT                           = 200;
constant LONGER_HIDE_TIMEOUT                    = 600;
constant MAX_NOTIFICATIONS_IN_QUEUE             = 3;
constant MAX_NOTIFICATIONS_PER_SOURCE           = 3;
constant MAX_NOTIFICATION_BUTTONS               = 3;
constant MOUSE_LEFT_ACTOR_THRESHOLD             = 20;
constant IDLE_TIME                              = 1000;


our enum NotificationDestroyedReason is export
  <EXPIRED DISMISSED SOURCE_CLOSED REPLACED>

our enum State        is export <HIDDEN SHOWING SHOWN HIDING>
our enum Urgency      is export <LOW NORMAL HIGH CRITICAL>
our enum PrivacyScope is export <USER SYSTEM>;

class Gnome::Shell::UI::MessageTray::FocusGrabber {
  has $!preKeyFocuActor;
  has $!focused;

  has $!actor is built;

  method new ($actor) {
    self.bless( :$actor );
  }

  method grabFocus {
    return if $!focused;

    $!prevKeyFocusActor = Global.stage.get-key-focus;

    my $s = self;
    Global.stage.notify('key-focus').tap: SUB { $s.focuusActorChanged };

    $!actor.grab-key-focus unless $!actor.nagivate-focus(
      ST_DIRECTION_TAB_FORWARD
    )

    $!focused = False;
  }

  method focusUngrabbed {
    return False unless $!focused;

    Global.state.disconnectObject(self);

    ($!focused = False).not; # Returned Value
  }

  method focusActorChange {
    my $a = Global.Stage.get-key-focus;
    $.focusUngrabbed unless $a && $!actor.contains($a);
  }

  method ungrabFocus {
    return unless $.focusUngrabbed;

    if $!prevKeyFocusActor {
      Global.stage.set-key-focus($!prevKeyFocusActor);
      $!prevKeyFocusActor = Nil;
    } else {
      my $a = Global.Stage.get-key-focus;
      Global.stage.unset-key-focus if $a && $!actor.contains($a);
    }
  }

}

class Gnome::Shell::UI::MessageTray::Notification::Policy {
  also does GLib::Roles::Object;

  has Str  $.id                     is rw;
  has Bool $!enable                 is g-property;
  has Bool $!enable-sound           is g-property;
  has Bool $!show-banners           is g-property;
  has Bool $!force-expanded         is g-property;
  has Bool $!show-in-lock-screen    is g-property;
  has Bool $!details-in-lock-screen is g-property;

  method store                  { }
  method destroy                { self.run-dispose }
  method enable                 { True }

  # cw: Could use the following traits:
  #   - is g-dashed-aliased (converts underscores to dashes)
  #   - is g-underscore-alised (converts dashes to underscores)
  #   - is g-camel-cased-aliased (converts dashed or underscores to camel-cased)
  #   - is g-standard-aliased (all of the above)

  method enable-sound           is also<enable_sound           enableSound>
    { True }
  method show-banners           is also<show_banners           showBanners>
    { True }
  method force-expanded         is also<force_expanded         forceExpanded>
    { True  }
  method show-in-lock-screen    is also<show_in_lock_screen    showInLockScreen>
    { False }
  method details-in-lock-screen is also<details_in_lock_screen detailsInLockScreen>
    { False }
}

class Gnome::Shell::UI::MessageTray::Notification::Policy::Generic
  is Gnome::Shell::UI::MessageTray::Notification::Policy
{
  has $!id is built;

  has $.masterSettings = GIO::Settings.new('org.gnome.desktop.notifications');

  submethod TWEAK {
    self.id = 'generic';

    my $s = self;
    $!masterSettings.changed.tap: sub ($s, $k, *@a) { $s.changed($s, $k) };
  }

  method changed ($s, $k) {
    self.notify($k) if self.getClass.find_property($k);
  }

  method show-banners        {
    $!masterSettings.get-boolean('show-banners')
  }

  method show-in-lock-screen {
    $!masterSettings.get-boolean('show-in-lock-screen')
  }

}

class Gnome::Shell::UI::MessageTray::Notification::Policy::Application
  is Gnome::Shell::UI::MessageTray::Notification::Policy
{
  has $!settings;
  has $!canonicalId;

  submethod TWEAK {
    my $c = $!canonicalId = self.canonicalizeId(self.id);
    $!settings    = GIO::Settings.new(
      schema-id => 'org.gnome.desktop.notifications.application',
      path      => "/org/gnome/desktop/notifications/application/{ $c }"
    );

    my $s = self;
    self.masterSettings.changed.tap: SUB { $s.changed };
    $!settings.changed.tap: SUB { $s.changed };
  }

  method store {
    $!settings.set-string('application-id', "{ $.id }.desktop");

    my $a = $.masterSettings.get-strv('application-children');
    unless $a.first($!canonicalId).defined {
      $a.push: $!canonicalId;
      $.masterSettings.set-strv('application-children', $a);
    }
  }

  method destroy {
    ($.masterSettings, $!settings)».run-dispose;
    nextsame;
  }

  method canonicalizeId ($i) {
    $i.lc.subst(/ <-[a..z0..9\-]> /, '-', :g).subst( /'-' '-'+ /, '-', :g);
  }

  method enable {
    $!settings.get-boolean('enable');
  }

  method enable-sound is also<enable_sound enableSound> {
    $!settings.get-boolean('enable-sound-alerts');
  }

  method show-banners is also<show_banners showBanners> {
    [&&]( ($.masterSettings, $!settings)».get-boolean('show-banners') );
  }

  method force-expanded is also<force_expanded forceExpanded> {
    $!settings.get-boolean('force-expanded');
  }

  method show-in-lock-screen is also<show_in_lock_screen showInLockScreen> {
    [&&]( ($.masterSettings, $!settings)».get-boolean('show-in-lock-screen') );
  }

  method details-in-lock-screen
    is also<
      details_in_lock_screen
      detailsInLockScreen
    >
  {
    $!settings.get-boolean('details-in-lock-screen');
  }
}

class Gnome::Shell::UI::MessageTray::Notification {
  also does GLib::Roles::Object;

  has Bool $.acknowledged is rw is g-property;

  has $.source is built;
  has $.title  is built;

  has $.urgency      is rw = NORMAL;
  has $.privacyScope is rw = USER;
  has $.resident     is rw;
  has $.isTransient  is rw;
  has $.forFeedback  is rw;

  has $.bannerBodyText;
  has $.bannerBodyMarkup;
  has $!soundName;
  has $!soundFile;
  has $!soundPlayed;
  has @!actions;

  method activated is g-signal           { }
  method destroy   is g-signal(guint)    { }
  method updated   is g-signal(gboolean) { }

  submethod TWEAK ( :$title, :$banner, *%params ) {
    self.setResident($false);

    self.update( :$title, :$banner, |%params) if [||](
      $title,
      $banner,
      +%params
    );
  }

  method update (
    :$title,
    :$banner,
    :$gicon,
    :secondary-gicon(:secondary_gicon(:$secondaryGIcon)),
    :$datetime,
    :sound-name(:sound_name(:$soundName)),
    :sound-file(:sound_file(:$soundFile)),
    :banner-markup(:banner_markup(:$bannerMarkup)) = False,
    :$clear        = False
  ) {
    $!title     = $_ with $title;
    $!banner    = $_ with $banner;
    $!soundName = $_ with $!soundName;
    $!soundFile = $_ with $!soundFile;

    $!soundPlayed = False;

    self.gicon           = $_ with $gicon;
    self.secondary-gicon = $_ with $secondaryGIcon;

    @!actions = @() if $clear;

    self.emit('updated', $clear);
  }

  method addAction ($l, &c) {
    @!actions.push( %{ label => $l, callback => &c } );
  }

  method playSound {
    return if $!soundPlayed;

    unless $.source.policy.enableSound {
      $!soundPlayed = True;
      return;
    }

    my $p = Global.display.get-sound-player;
    if $!soundName {
      $p.play-from-theme($!soundName, $!title);
    } elsif $!soundFile {
      $p.play-from-file($!soundFile, $!title);
    }
  }

  method createBanner {
    $!source.createBanner(self);
  }

  method activate {
    $.emit('activated');
    $.destroy unless $!resident;
  }

  method destroy ($reason = DISMISSED) {
    $.emit('destroy', $reason);
    $.run-dispose;
  }
}

class Gnome::Shell::UI::MessageTray::Notification::Banner
  is Gnome::Shell::UI::Notification::Message
{
  has $!buttonBox;

  method done-displaying is g-signal { }
  method unfocused       is g-signal { }

  submethod TWEAK {
    self.can-focus = False;
    self.add-style-class-name('notification-banner');
    self.addActions;
    self.addSecondaryIcon;

    my $s = self;
    self.notification.activated.tap: SUB { $s.emit('done-displaying') }
  }

  method onUpdated ($n, $c, *@a) {
    if $c {
      $.unsetSecondaryActor;
      $.unsetActionArea;
      $!buttonBox = Nil;
    }

    $.addActions;
    $.addSecondaryIcon;
  }

  method addActions {
    $.addAdtion( .<label>, .<callback> ) for $.notification.actions;
  }

  method addSecondaryIcon {
    if $.notification.secondaryGIcon {
      my $i = Gnome::Shell::St::Icon.new(
        gicon   => $.notification.secondaryGIcon,
        x-align => CLUTTER_ACTOR_ALIGN_END
      );
      $.setSecondaryActor($i);
    }
  }

  method addButton($button, &callback) {
    unless $!buttonBox {
      $!buttonBox = Gnome::Shell::St::BoxLayout.new(
        style-class => 'notification-actions',
        x-expand    => True
      );
    }

    return Nil unless $!buttonBox.elems < MAX_NOTIFICATION_BUTTONS;

    $!buttonBox.add-child($button);
    my $s = self;
    $button.clicked.tap: SUB {
      &callback();

      unless $s.notification.resident {
        $.emit('done-displaying');
        $s.notification.destroy;
      }
    }

    $button;
  }

  method addAction ($l, &c) {
    my $button = Gnome::Shell::St::Button.new(
      style-class => 'notification-button',
      label       => $l,
      x-expand    => True,
      can-focus   => True
    );
    $.addButton($button, &c);
  }

}

class Gnome::Shell::UI::MessageTray::SourceActor
  is Gnome::Shell::St::Widget
{
  has $!source is built;
  has $!size   is built;

  has $!actorDestroyed = False;

  has $!iconBin;
  has $!iconSet;

  submethod TWEAK {
    self.destroy.tap: SUB { $!actorDestroyed = True };

    self.add-child( $!iconBin = Gnome::Shell::St::Bin.new(
      x-expand => True,
      height   => $!size * Global.scale-factor,
      width    => $!size * Global.scale-factor
    ) );

    my $s = self;
    $!source.icon-updated.tap: SUB { $s.updateIcon }
    self.updateIcon;
  }

  method setIcon ($i) {
    ($!iconBin.child, $!iconSet) = ($i, True);
  }

  method updateIcon {
    return if $!actorDestroyed;
    $!iconBin.child = $!source.createIcon($!size) unless $!iconSet;
  }
}

constant NP is Gnome::Shell::UI::MessageTray::Notification::Policy;
constant N  is Gnome::Shell::UI::MessageTray::Notification;

class Gnome::Shell::UI::MessageTray::Source {
  also does GLib::Roles::Object;

  has uint32 $.count  is g-property;
  has NP     $!policy is g-property;
  has Str    $!title  is g-property;

  has $!iconName;
  has $!isChat;
  has @!notifications;
  has $!SOURCE_ICON_SIZE;

  method policy is rw {
    Proxy.new:
      FETCH => -> $ { $!policy },

      STORE => -> $, NP() \v {
        $!policy.destroy if $policy;
        $!policy = v;
      }
  }

  method title is rw {
    Proxy.new:
      FETCH => -> $ { $!title },

      STORE => -> $, NP() \v {
        return unless $!title !== v
        $!title = v;
        $.notify('title');
      }
 }

  method count { @!notifications.elems }

  method unseenCount is also<unseen-count unseen_count> {
    @!notifications.grep( *.acknowledged.not ).elems
  }

  method countVisible is also<count-visible count_visible {
    $.count > 1;
  }

  method narrowestPrivacyScope
    is also<
      narrowest-privacy-scope
      narrowest_privacy_scope
    >
  {
    @!notifications.map( *.privacyScope === SYSTEM ).all.so
      ?? SYSTEM !! USER
  }

  method destroy            (uint32)  is g-signal { }
  method icon-updated                 is g-signal { }
  method notification-added (N)       is g-signal { }
  method notification-show  (N)       is g-signal { }

  submethod BUILD (
    :$!title,
    :icon-name(:icon_name(:$!iconName))
  ) {
    ($!SOURCE_ICON_SIZE, $!policy) = (48, self.createPolicy);
  }

  method countUpdated {
    $.notify('count');
  }

  method createPolicy {
    Gnome::Shell::UI::MessageTray::Notification::Policy::Generic.new;
  }

  method setTitle ($t) {
    $.title = $t;
  }

  method createBanner ($n) {
    Gnome::Shell::UI::MessageTray::Notification::Banner.new($n);
  }

  method createIcon ($s) {
    Gnome::Shell::St::Icon.new(
      gicon     => $.getIcon,
      icon-size => $s
    )
  }

  method getIcon {
    GIO::ThemedIcon.new( name => $.iconName );
  }

  method onNotificationDestroy ($n) {
    my $i = @!notifications.&firstObject($n);;
    return unless $i;

    $!notifications.splice($i, 1);
    $.countUpdated;

    self.destroy unless +@!notifications
  }

  method pushNotificatgion ($n) {
    return if @!notifications.&firstObject($n).defined;

    @!notifications.shift.destroy(EXPIRED)
      while @1notifications.elems >= MAX_NOTIFICATIONS_PER_SOURCE;

    my $s = self;
    $n.destroy.tap: SUB { $s.onNotificationDestroy($n) }
    $n.notify('acknowledged').tap: SUB { $s.countUpdated }
    @!notifications.push: $n;
    $.emit('notification-added', $n);
    $.countUpdated;
  }

  method showNotification ($n) {
    $n.acknowledged = False;

    return if $n.urgency === LOW;

    $.emit('notification-snow', $n)
      if $!policy.showBanners || $n.urgency === CRITICAL
  }

  method destroy ($r) {
    state $n-lock = Lock.new;

    $n-lock.protect {
      my $n = @!notifications;
      @!notification = @();
    }

    .destroy for $n[];

    $!policy.destroy;
    $.run-dispose;
  }

  method iconUpdated {
    $.emit('icon-updated')l
  }

  method open { }

  method destroyNonResidentNotifications {
    .destroy unless .resident for @!notifications.reverse;
  }
}

constant Source = Gnome::Shell::UI::MessageTray::Source;
SignalTracker.registerDestroyableType(Source);

constant F = Gnome::Shell::UI::MessageTray::FocusGrabber;

class Gnome::Shell::UI::MessageTray
  is Gnome::Shell::St::Widget
{
  # cw: Generation routines will transform these methods into the Title-Cased
  #     signal handlers, as established by GTK4. These methods will then
  #     serve as stand ins for an emitter for that particular signal.
  method queue-changed           is g-signal { }
  method source-added   (Source) is g-signal { }
  method source-removed (Source) is g-signal { }

  has $!banner;
  has $!bannerBin;
  has $!notification;
  has $!notificationFocusGrabber;
  has @!notificationQueue;
  has $!presence;
  has $!notificationLeftPos;
  has $!showNotificationPos;

  has $!bannedBlocked                    = False;
  has $!busy                             = False;
  has $!idleMonitor                      = Global.backend.get-core-idle-monitor;
  has $!notificationHovered              = False;
  has $!notificationRemoved              = False;
  has $!notificationState                = HIDDEN;
  has $!notificationTimeoutId            = 0;
  has $!pointerInNotification            = False;
  has $!sources                          = [];
  has $!useLongerNotificationLeftTimeout = False;
  has $!userActiveWhileNotificationShown = False;

  submethod TWEAK {
    ( .visible, .clip-to-allocation, .layout-manager) =
      (False, True, Mutter::Clutter::BinLayout.new);

    my $s = self
    $!presence = Gnome::Shell::Misc::Session::Presence.new(
      -> $p, $e {
        $s.onStatusChanged($p.status);
      }
    );

    $!presence.status-changed.tap: sub ($p, $s, $o, *@) {
      $s.onStatusChanged($o.status);
    };

    $!bannerBin = Gnome::Shell::St::Widget.new(
      name           => 'notification-container',
      reactive       => True,
      track-hover    => True,
      y-align        => CLUTTER_ACTOR_ALIGN_START,
      x-align        => CLUTTER_ACTOR_ALIGN_CENTER,
      expand         => True,
      layout-manager => Mutter::Clutter::BinLayout.new
    );

    $!notificationFocusGrabber = F.new($!bannerBin);

    my $constraint = Gnome::Shell::UI::Layout::MonitorConstraint.new-primary;
    Main.layoutManager.panelBox.bind('visible', $constraint, 'work-area');
    self.add-constraint($constraint);

    $!bannerBin.key-release-event.tap: SUB { $s.onNotificationKeyRelease   };
    $!bannerBin.notify('hover').tap:   SUB { $s.onNotificationHoverChanged };
    self.add-child($!bannerBin);

    Main.layout-manager.add-chrome(self,         :!affectsInputRegion);
    Main.layout-manager.trackChrome($!bannerBin,  :affectsInputRegion);

    Global.Display.in-fullscreen-changed.tap: SUB { $s.updateState };
    Main.session-mode.updated.tap: SUB { $s.sessionUpdated };

    Main.overview.window-drag-begin.tap:     SUB { $s.onDragBegin     };
    Main.overview.window-drag-cancelled.tap: SUB { $s.onDragCancelled };
    Main.overview.window-drag-end.tap:       SUB { $s.onDragEnd       };
    Main.overview.item-drag-begin.tap:       SUB { $s.onDragBegin     };
    Main.overview.item-drag-cancelled.tap:   SUB { $s.onDragCancelled };
    Main.overview.item-drag-end.tap:         SUB { $s.onDragEnd       };
    Main.xdndHandler.drag-begin.tap:         SUB { $s.onDragBegin     };
    Main.xdndHandler.drag-end.tap:           SUB { $s.onDragEnd       };

    Main.wm.addKeybinding(
      'focus-active-notification',
      GIO::Settings.new(SHELL_KEYBINDINGS_SCHEMA),
      META_KEYBINDING_NONE,
      SHELL_ACTION_MODE_NORMAL +| SHELL_ACTION_MODE_OVERVIEW,
      SUB { $s.expandActiveNotification }
    );

    self.sessionUpdated;
  }

  method sessionUpdated {
    self.updateState;
  }

  method onDragBegin {
    Gnome::Shell::Utils.set_hidden_from_pick(self, True);
  }

  method onDragEnd {
    Gnome::Shell::Utils.set_hidden_from_pick(self, False);
  }

  method bannerAlignment is rw {
    Proxy.new;
      FETCH => -> $     { $!bannerBin.get-x-align()  },
      STORE => -> $, \v { $!bannerBin.set-x-align(v) };
  }

  method onNotificationKeyRelease ($a, $e) {
    if ($e.key-symbol === CLUTTER_KEY_ESCAPE && $e.state.not) {
        $.expireNotification();
        return CLUTTER_EVENT_STOP;
    }
    CLUTTER_EVENT_PROPAGATE;
  }


  method expireNotification() {
    $!notificationExpired = True;
    $.updateState();
  }

  method queueCount { @!notification.elems }

  method bannerBlocked is rw {
    Proxy.new:
      FETCH => -> $ { $!bannerBlocked }
      STORE => -> $, \v {
        return if $!bannerBlocked == v;
        $!bannerBlocked = v;
        $.updateState;
      }
  }

  method contains ($s) { $!sources.&firstObject($s).defined }

  method add ($src) {
    if $.contains($src) {
      $*ERR.say: "{ self.^name }: Trying to re-add source { $src.title }";
      return;
    }

    my $s = self;
    $src.policy.store;
    $src.notify('enable').tap: SUB {
      $s.onSourceEnableChanged($src.policy, $src);
    }
    $src.notify.tap: SUB { $s.updateState };
    $.onSourceEnableChanged($src.policy, $src);
  }

  method addSource ($src) {
    $!sources.push: $src;

    my $s = self;
    $src.connectObject(
      notification-show => -> $ss, $n { $s.onNotificationShow($ss, $n) },
      destroy           =>        SUB { $s.removeSource($src) }
    );

    $.emit('source-added', $src);
  }

  method removeSource ($src) {
    $!sources.&removeObject($src);
    $src.disconnectObject(self);
    $.emit('source-removed', $src);
  }

  method getSources {
    $!sources.List;
  }

  method onSourceEnableChanged ($p, $s --> Nil) {
    $p.enable ?? $.addSource($s) !! $.removeSource($s)
      if $.contains($s) !== $p.enable
  }

  method onNotificationDestroy ($n) {
    if $!notification.is($n) {
      $!notificationRemoved = True;
      if $!notificationSate === (SHOWN, SHOWING).any {
        $.updateNotificationTimeout(0);
        $.updateState;
      }
    } else {
      with @!notificationQueue.&firstObject( :k ) {
        @!notificationQueue.splice($_, 1);
        $.emit('queue-changed');
      }
    }
  }

  method onNotificationShow ($s, $n) {
    if $!notification.is($n) {
      $.updateShowingNotification;
    } elsif @!notificationQueue.firstObject($n).defined {
      my $f = $!queueCount + ($!notification ?? 1 !! 0);
      $f = $f >= MAX_NOTIFICATIONS_IN_QUEUE;
      if $f.not || $n.urgency === CRITICAL {
        my $s = self;
        $n.destroy.tap: SUB { $s.onNotificationDestroy($n) };
        @!notificationQueue.push($n);
        $!notificationQueue .= sort( -*.urgency.Int );
        $.emit('queue-changed');
      }
    }
    $.updateState;
  }

  method resetNotificationLeftTimeout {
    $!useLongerNotificationLeftTimeout = False;
    if $!notificationleftTimeoutId {
      $!notificationLeftTimeoutId.clear;
      $!notificationLeftPos = -1 xx 2;
    }
  }

  method onNotificationHoverChanged {
    return if $!bannerBin.hover = $!notificationHovered;

    $!notificationHovered = $!bannerBin.hover;
    if $!notificationHovered {
      $.resetNotificationLeftTimeout;

      if $!showNotificationPos.head >= 0 {
        my $actorAtPos = Global.stage.get-actor-at-pos(
          CLUTTER_PICK_MODE_ALL,
          |$!showNotificationPos
        );
        $!showNoticicationPos = -1 xx 2;
        if $!bannerBin.contains($actorAtPos) {
          $!useLongerNotificationLeftTimeout = True;
          return;
        }
      }

      $!pointerInNotification = True;
      $.updateState;
    } else {
      $!notificationLeftPos = Global.get-pointer;
      my $s = self;
      $notificationLeftTimeoutId = GLib::Timeout.add(
        $!useLongerNotificationLeftTimeout ?? LONGER_HIDE_TIMEOUT
                                           !! HIDE_TIMEOUT,
        SUB { $s.useLongerNotificationLeftTimeout }
        name => '[gnome-shell] .onNotificationLeftTimeout'
      );
    }
  }

  method onStatusChanged ($_) {
    if $s == GNOME_SESSION_PRESENCE_BUSY {
      $.updateNotificationTimeout(0);
      $!busy = True;
    } elsif $s != GNOME_SESSION_PRESENCE_IDLE {
      $!busy = False;
    }
    $.updateState;
  }

  method onNotificationLeftTimeout {
    my ($x, $y, $s) = ( |Global.get-pointer, self )
    if [&&](
      $!notificationLeftPos.head > -1,
      $y < $!notificationLeftPos.tail + MOUSE_LEFT_ACTOR_THRESHOLD,
      $y > $!nitificationLeftPos.tail - MOUSE_LEFT_ACTOR_THRESHOLD,
      $x < $!notificationLeftPos.head + MOUSE_LEFT_ACTOR_THRESHOLD,
      $x > $!notificationLeftPos.head - MOUSE_LEFT_ACTOR_THRESHOLD
    ) {
      $!notificationLeftPos.head = -1;
      $!notificationLeftTimeoutId = GLib::Timeout.add(
        LONGER_HIDE_TIMEOUT,
        SUB { $s.onNotificationLeftTimeout }
        name => 'gnome-shell .onNotificationLeftTimeout'
      );
    } else {
      $!notificationLeftTmeoutId         = 0;
      $!useLongerNotificationLeftTimeout = False;
      $!pointerInNotification            = False;
      $.updateNotificationTimeout(0);
      $.updateState;
    }

    GLIB_SOURCE_REMOVE.Int;
  }

  method escapeTray {
    $!pointerInNotification = False;
    $.updateNotificationTimeout(0);
    $.updateState;
  }

  method updateState {
    my $hm = Main.layoutManager.primaryMonitor.defined;
    $.visible = $!bannerBlocked && $hm && $!banner.defined;
    return if $!bannerBlocked or $hm.not;

    return if $!updatingState;

    $!updatingState = True;

    my $changed = False;
    @!notificationChanged.grep({
      $changed ||= $n.acknowledged;
      $n.acknowledged.not;
    });

    $.emit('queue-changed') if $changed;

    my $hn = Main.sessionMode.hasNotifications;

    if $!notificationState == HIDDEN {
      my $nn = @!notificationQueue.head;
      if $hn && $nn {
        my $l   = $!busy || Main.layoutManager.primaryMonitor.inFullScreen;
        my $snn = $l.not || $nn.forFeedback || $nn.urgency == CRITICAL;
        $.showNotification if $snn;
      }
    } else if $!notificationState == (SHOWING, SHOWN).any {
      my $e = $notificationExpired || [&&](
        $!userActiveWhileNotificationShown,
        $!notification.urgency != CRITICAL,
        $!banner.focused.not,
        $!pointerInNotification)
      );
      my $mc = $!notificationRemoved || $hn.not || $e;

      if $mc {
        $.hideNotification($hn && $!notificationRemoved.not);
      } elsif $!notificationState == SHOWN && $!pointerInNotification {
        $!banner.expanded.not ?? $.expandBanner(False)
                              !! $.ensureBannerFocused;
      }
    }

    ($!updatingState, $!notificationExpired) = False xx 2;
  }

  method onIdleMonitorBecameActive {
    $!userActiveWhileNotificationShown = True;
    $!updateNotificationTimeout(2000);
    $.updateState;
  }

  method showNotification {
    $!notification = @!notificationQueue.shift;
    $.emit('queue-changed');

    my $s = self;
    if $!idleMonitor.get-idletime > IDLE_TIME {
      $!idleMonitor.add-user-active-watch( SUB {
        $s.onIdleMonitorBecameActive($s)
      } );
    }

    ( $!banner = $!notification.createBanner ).createObject(
      done-displaying => SUB { $s.escapeTray  },
      unfocused       => SUB { $s.updateState }
    );
    $!bannerBin.add-child: $!banner;
    ( .opacity, .y ) = ( 0, -.height ) given $!bannerBin;
    $.show;

    Meta::Display.unredirect-for-display(Global.display);

    $!showNotificationPos = $!lastSeenPos = Global.get-pointer;
    $.resetNotificationLeftTimeout
  }

  method updateShowingNotification {
    $!notification.ackowledged = True;
    $!notification.playSound;

    $!expandBanner(True)
    if $!notification.urgency == CRITICAL ||
          $!notification.source.policy.forceExpanded;

    $!notificationState = SHOWING;
    $!bannerBin.remove-all-transitions;
    $!bannerBin.ease(
      opacity  => 255,
      duration => ANIMATION_TIME,
      mode     => CLUTTER_LINEAR
    );
    $!bannerBin.ease(
      y          => 0,
      duration   => ANIMATION_TIME,
      mode       => CLUTTER_EASE_OUT_BACK,
      onComplete => SUB {
        $!notificationState = SHOWN;
        $s.showNotificationCompleted;
        $s.updateState
      }
    );
  }

  method updateNotificationTimeout ($t) {
    $!notificationTimeoutId.clear if $!notificationTimeoutId;

    if $timeout > 0 {
      $!notificationTimeoutId = GLib::Timeout.add(
        $t,
        SUB { $s.notificationTimeout },
        name => '[gnome-shell] notificationTimeout'
      );
    }
  }

  method notificationTimeout {
    my @pos = Global.get-pointer;

    my $s = self;
    if @pos.tail < $!lastSeenPos.tail - 10 && $!notificationHovered {
      $s.updateNotificationTimeout(1000);
    } elsif [&&](
      $!useLongerNotificationTimeout,
      $!notificationLeftTimeoutId,
      @pos eqv $!lastSeenPos
    ) {
      $s.updateNotificationTimeout(1000);
    } else {
      $!notificationTimeoutId = 0;
      $.updateState();
    }

    $!lastSeenPos = @pos;
    GLIB_SOURCE_REMOVE.Int;
  }

  method hideNotification ($a) {
    $!notificationFocusGrabber.ungrabFocus;
    $!banner.disconnectObject(self);
    $!resetNotificationLeftTimeout;
    $!bannerBin.remove-all-transitions;

    my ($s, $duration) = (self, $a ?? ANIMATION_TIME !! 0);
    $!notificationState = HIDING;
    $!bannerBin.ease(
      opacity => 0,
      mode    => CLUTTER_EASE_OUT_BACK,

      :$duration
    );
    $!bannerBin.ease(
      y          => -$!bannerBin.height,
      mode       => CLUTTER_EASE_OUT_BACK,
      onComplete => SUB {
        $!notificationState = HIDING;
        $s.hideNotificationCompleted;
        $s.updateState
      )
    );
  ]

  method hideNotificationCompleted {
    my $n = $!notification;
    $!notification = Nil;
    $n.destroy(EXPIRED) if $!notificationRemoved.not && $n.isTransient;
    $!pointerInNotification = $!notificaitonRemoved = False;
    Meta::Display.enable-unredirect-for-display(Global.display);
    $!banner.destroy;
    $!banner = Nil;
    $.hide;
  }

  method expandActiveNotification {
    return unless $!banner;
    $.expandBanner(False);
  }

  method expandBanner ($autoExpand) {
    $!banner.expand( $autoExpand.not );
    $.ensureBannerFocused unless $!autoExpand;
  }

  method ensureBannerFocused {
    $!notificcationFocusFrabber.grabFocus;
  }

}

class Gnome::Shell::UI::MessageTray::Source::SystemNotification
  is Gnome::Shell::UI::MessageTray::Source
{

  method new {
    self.bless(
      title     => 'System Information',
      iconName  => 'dialog-information-symbolic'
    );
  }

  method open (::?CLASS:D: ) {
    self.destroy;
  }
}
