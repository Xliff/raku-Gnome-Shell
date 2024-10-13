use v6.c;

use Gnome::Shell::WindowTracker;
use Gnome::Shell::St::Bin;
use Gnome::Shell::St::BoxLayout;
use Gnome::Shell::St::Label;
use Ghome::Shell::St::TextureCache;
use Gnome::Shell::St::Widget;
use Gnome::Shell::UI::Overview;
use Gnome::Shell::UI::PanelMenu;
use Gnome::Shell::UI::QuickSettings;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

constant PANEL_ICON_SIZE               = 16;
constant APP_MENU_ICON_MARGIN          = 0;
constant BUTTON_DND_ACTIVATION_TIMEOUT = 250;
constant N_QUICK_SETTINGS_COLUMNS      = 2;
constant INACTIVE_WORKSPACE_DOT_SCALE  = 0.75;

### /home/cbwood/Projects/gnome-shell/js/ui/panel.js

class Gnome::Shell::UI::Panel::AppMenuButton
  is   Gnome::Shell::UI::PanelMenu::Button
{
  reg( ::?CLASS );

  has $!gnome-ui-appmenubutton is implementor;

  method changed is g-signal { }

  has $!targetApp;
  has $!menuManager;

  has $!visible      = False;
  has $!startingApps = [];
  has $!container    = Gnome::Shell::St::BoxLayout.new(
    style_class => 'panel-status-menu-box'
  );
  has $!iconBox      = Gnome::Shell::St::Bin(
    style_class => 'app-menu-icon',
    y-align     => CLUTTER_ACTOR_ALIGN_CENTER,
  )
  has $!label        = Gnome::Shell::St.Label(
    y-expand    => True,
    y-align     => CLUTTER_ACTOR_ALIGN_CENTER,
  );
  has $!spinner      = Gnome::Shell::UI::Animation::Spinner.new(
    PANEL_ICON_SIZE,
    :animate,
    :hideOnStop,
  );

  submethod BUILD ( :$panel ) {
    self.bind('reactive', self, 'can-focus');

    self.setAttributes(
      menuAlignment   => 0,
      nameText        => Nil,
      dontCreateMenu  => True,
      accessible-role => ATK_ROLE_MENU,
      reactive        => False
    );

    $!menuManager = $panel.menuManager;

    my $bin = Gnome::Shell::St::Bin( name => 'appMenu' );
    self.add-child($bin);
    $bin.child = $!container;

    my $tc = Gnome::Shell::St::TextureCache.default;
    $tc.Icon-Theme-Changed.tap: sub (|c) {
      self.onIconThemeChanged( |c );
    }

    my $ie = Mutter::Clutter::DesaturateEffect.new;
    $!iconBox.add($ie);
    $!iconBox.Style-Changted.tap: SUB {
      $ie.enabled = $!iconBox.get-theme-node.icon-style ==
        ST_ICON_STYLE_SYMBOLIC;
    }
    self.hide unless ($!visible = Main.overview.visible.not);

    Main.overview.connectObject:
      hiding  => SUB { self.sync },
      showing => SUB { self.sync };

    my $menu = Gnome::Shell::UI::AppMenu.new(self);
    self.setMenu($menu);
    $!menuManager.addMenu($menu);

    $!container.add-child($_) for $!iconBox, $!label, $!spinner;

    Gnome::Shell::windowTracker.default.notify('focus').tap: sub (|c)
      self.onAppStateChanged(|c);
    }
    Global.window-manager.Switch-Workspace.tap: sub (*@a) {
      self.sync;
    }

    self.sync;
  }

  method fadeIn {
    return if $!visible;

    ($!visible, $.reactive) = True xx 2;
    $.remove-all-transitions;
    $.ease(
      opacity  => 255,
      duration => OVERVIEW_ANIMATION_TIME,
      mode     => CLUTTER_EASE_OUT_QUAD
    );
  }

  method fadeIn {
    return unless $!visible;

    ($!visible, $.reactive) = False xx 2;
    $.remove-all-transitions;
    $.ease(
      opacity  => 0,
      duration => OVERVIEW_ANIMATION_TIME,
      mode     => CLUTTER_EASE_OUT_QUAD
    );
  }

  method syncIcon ($a) {
    $!iconbox.child =
      $a.create-icon-texture(PANEL-ICON-SIZE - APP_MENU_ICON_MARGIN);
  }

  method onIconThemeChanged {
    return if $!iconBox.child.defined.not;
    $.syncIcon($!targetApp) if $!targetApp;
  }

  method stopAnimation  { $!spinner.stop }
  method startAnimation { $!spinner.play }

  method onAppStateChanged ($s, $a) {
    $a.state == SHELL_APP_STATE_STARTING
      ?? $!startingApps.push: $a
      !! $!startingApps .= grep({ .equals($a) })

    $.sync;
  }

  method focusAppChanged {
    unless Gnome::Shell::WindowTracker.default.focus-app {
      return if Global.stage.key-fucus;
    }
    $.sync;
  }

  method findTargetApp {
    my $ws = Global.workspace-manager.get-active-workspace;
    my $t  = Gnome::Shell::WindowTracker.default;
    my $fa = $t.focus-app;
    return $fa if $fa?.is-on-workspace($ws);

    for $!startingApps {
      return $_ if .is-on-workspace($ws);
    }
  }

  method sync {
    my $ta = $.findTargetApp;

    if $!targetApp.equals($ta).not {
      $!targetApp?.disconnectObject(self);
      $!targetApp = $ta;

      with $!targetApp {
        .notify('busy').tap: SUB { self.sync }
        ($!label.text, .accessible-name) = .name xx 2;
        $.syncIcon($_);
      }
    }

    ( my $v = $!targetApp && Main.overview.visibleTarget.not )
      ?? $.fadeIn
      !! $.fadeOut;

    ( my $ib = $!targetApp?.state === SHELL_APP_STATE_STARTING ||
               $!targetApp?.busy )
      ?? $.startAnimation
      !! $.stopAnimation;

    $.reactive = $v && $ib.not;
    $.menu.setApp($!targetApp);
    $.emit('changed');
  }
}

class Gnome::Shell::UI::Panel::Workspace::Dot
  is   Mutter::Clutter::Actor
{
  reg( ::?CLASS );

  has gdouble $!expansion        is ranged (0..1)  is default(0);
  has gdouble $!width-multiplier is ranged (1..10) is default(1);

  has $.destroying = False;
  has $!dot        = Gnome::Shell::St::Widget.new(
    style-class  => 'workspace-dot',
    y-align      => CLUTTER_ACTOR_ALIGN_CENTER,
    pivot-point  => Graphene::Point.new(0.5, 0.5),
    request-mode => CLUTTER_REQUEST_MODE_WIDTH_FOR_HEIGHT
  );

  submethod BUILD {
    self.pivot-point = Graphene::Point.new(0.5, 0.5);
    self.add-child($!dot)l

    self.notify('width-multiplier').tap: SUB { self.queue-relayout }
    self.notify('expansion').tap: SUB {
      self.updateVisuals;
      self.queue-relayout;
    }
    self.updateVisuals;
  }

  method updateVisuals {
    $!dot.setAttribute(
      opacity => lerp(0.5, 1.0, $!expansion) * 255,
      scale-x => lerp(INACTIVE_WORKSPACE_DOT_SCALE, 1, $!expansion),
      scale-y => lerp(INACTIVE_WORKSPACE_DOT_SCALE, 1, $!expansion)
    );
  }

  method get_preferred_width ($fh) is vfunc {
    my $f = lerp(1.0, $!width-multiplier, $!expansion);
    $!dot.get-preferred-width($fh).map({ $_ * $f });
  }

  method get_preferred_height ($fw) is vfunc {
    $!dot.get-preferred-height($fw);
  }

  method allocate ($b) is vfunc {
    $.set-allocation($b);
    $b.set-origin(0, 0);
    $!dot.allocate($b);
  }

  method scaleIn {
    $.setAttributes( scale => 0 );
    $.ease(
      duration => 500,
      mode     => CLUTTER_EASE_OUT_CUBIC,
      scale    => 1
    );
  }

  method scaleOutAndDestroy {
    $!destroying = True;

    $.ease(
      duration   => 500,
      mode       => CLUTTER_EASE_OUT_CUBIC,
      scale      => 0,
      onComplete => SUB { self.destroy }
    );
  }

}

class Gnome::Shell::UI::Panel::Workspace::Indicators
  is   Gnome::Shell::St::BoxLayoutS
{
  reg( ::?CLASS );

  has $!workspacesAdjustment;

  submethod BUILD {
    $!workspacesAdjustment = Main.createWorkspacesAdjustment(self);
    $workspacesAdjustment.connectObject(
      'notify::value', SUB { self.updateExpansion },
      'notify::upper', SUB { self.recalculateDots }
    );

    method new (
      self.bless(


    for ^$!workspacesAdjustment.upper {
      self.insert-child-at-index(
        Gnome::Shell::UI::Panel::Workspace::Dot.new,
        $_
      );
    }
    self.updateExpansion;
  }

  method getActiveIndicators {
    # cw: -XXX- Unfortunately, the objects will be of type
    #     Mutter::Clutter::Actor until propReturnObject
    #     returns the actual type with a fallback to the given
    #     type-pair.
    self.children.map({ .destroying.not });
  }

  method recalculateDots {
    my $ai = $.getActiveIndicators;
    my $ni = $ai.elems;
    my $ti = $!workspacesAdjustment.upper;

    for ( ^($ni - $ti).abs ).reverse {
      if $ni < $ti {
        my $i = Gnome::Shell::UI::Panel::Workspace::Dot.new;
        $.add-child($i);
        $i.scaleIn;
      } else {
        $ai[$ni - .pred].scaleOutAndDestroy
      }
    }
    $.updateExpansion;
  }

  method updateExpansion;
    my $ni = $.getActiveIndicators.elems;
    my $aw = $!workspacesAdustment.value;

    my $wm = do {
      when    $ni <= 2 { 3.625 }
      when    $ni <= 5 { 3.25  }
      default          { 2.75  }
    }

    for $.get-children.kv -> $k, $v {
      my $d = ($k - $aw).abs;
      (.expansion, .width-multiplier) = ( clamp(1 - $d, 0, 1), $wm );
    }
  }
}

class Gnome::Shell::UI::Panel::ActivitiesButton
  is   Gnome::Shell::UI::PanelMenu::Button
{
  reg( ::?CLASS );

  has $!xdndTimeout = 0;

  submethod BUILD ( :$panel ) {
    self.setAttributes(
      menuAlignment   => 0,
      nameText        => Nil,
      dontCreateMenu  => True,
      name            => 'panelActivities',
      accessible-role => ATK_ROLE_TOGGLE_BUTTON,
      accessible-name => 'Activities'
    );

    my $wi = Gnome::Shell::UI::Panel::Workspace::Indicators.new;
    self.add-child($wi);

    Main.overview.Showing.tap: SUB {
      self.add-style-pseudo-class('checked')
    }
    Main.overview.Hiding.tap: SUB {
      self.remove-style-pseudo-class('checked')
    }
  }

  method handleDragOver ($s, $a, $x, $y, $t) {
    return DRAG_MOTION_RESULT_CONTINUE unless $s.equals(Main.xdndHandler);

    $!xdndTimeout.?cancel if $!xdndTimeout;

    $!xdndTimeout == GLib::Timeout.add(
      BUTTON_DND_ACTIVATION_TIMEOUT,
      SUB { self.xdndToggleOverview },
      name => "[gnome-shell] { self.^name }.{ &?ROUTINE.^name }"
    }
    DRAG_MOTION_RESULT_CONTINUE
  }

  method event ($e) is vfunc {
    if $e.type == (CLUTTER_EVENT_TOUCH_END, CLUTTER_EVENT_BUTTON_RELEASE).any
      Main.overview.toggle if $main.overview.shouldToggleByCornerOrButton;
    }

    Main.wm.handleWorkspaceScroll($e);
  }

  method key_release_event ($e) is vfunc {
    if $e.key-symbol == (CLUTTER_KEY_Return, CLUTTER_KEY_Space).any {
      Main.overview.toggle if $main.overview.shouldToggleByCornerOrButton;
      return CLUTTER_EVENT_STOP;
    }
    CLUTTER_EVENT_PROPAGATE
  }

  method xdndToggleOverview {
    my ($x, $y) = Global.pointer;
    my  $pa     = Global.stage.get-actor-at-pos(CLUTTER_PICK_REACTIVE, $x, $y);

    Main.overview.toggle
      if $pa.equals(self) && $main.overview.shouldToggleByCornerOrButton;

    $!xdndTimeout.?clear;
    G_SOURCE_REMOVE;
  }
}

class Gnome::Shell::UI::Panel::Indicator::UnsafeMode
  is   Gnome::Shell::UI::QuickSettings::SystemIndicator
{
  reg( ::?CLASS );

  has $gnome-shell-unsafemode is implementor;

  has $!indicator;

  submethod BUILD {
    $!indicator = self.addIndicator;
    $!indicator.icon-name = 'channel-insecure-symbolic';

    Global.context.bind('unsafe-mode', $!indicator, 'visible');
  }
}

class Gnome::Shell::UI::Panel::QuickSettings
  is   Gnome::Shell::UI::PanelMenu::Button
{
  reg( ::?CLASS );

  has $!indicators = Gnome::Shell::St::BoxLayout.new(
    style-class => 'panel-status-indicators-box'
  );

  has $!system;
  has $!camera;
  has $!volumeOutput;
  has $!volumeInput;
  has $!brightness;
  has $!remoteAccess;
  has $!location;
  has $!thunderbolt;
  has $!nightLight;
  has $!darkMode;
  has $!backlight;
  has $!powerProfiles;
  has $!rfkill;
  has $!autoRotate;
  has $!unsafeMode;
  has $!backgroundApps;
  has $!network;
  has $!bluetooth;

  submethod BUILD {
    self.setAttributes(
      menuAlignment   => 0,
      nameText        => 'System menu in the top bar',
      dontCreateMenu  => True,
    );

    self.add-child($!indicators);

    my $m = Gnome::Shell::UI::PanelMenu::QuickSettingsMenu.new(
      self,
      N_QUICK_SETTINGS_COLUMNS
    );
    self.setMenu($m);

    self.setupIndicators;
  }

  method setupIndicators {
    start {
      CATCH {
        default { $*ERR.say: "Failed to setup quick settings: { .message }" }
      }

      if Config.HAVE_NETWORKMANAGER {
        use Gnome::Shell::UI::Status::Nework;

        $!network = Gnome::Shell::UI::Status::Network.Indicator;
      }

      if Config.HAVE_BLUETOOTH {
        use Gnome::Shell::UI::Status::Bluetoothl

        $!bluetooth = Gnome::Shell::UI::Status::Network::Bluetooth;
      }

      $!system         = Gnome::Shell::UI::Status::System.Indicator();
      $!camera         = Gnome::Shell::UI::Status::Camera.Indicator();
      $!volumeOutput   = Gnome::Shell::UI::Status::Volume.OutputIndicator();
      $!volumeInput    = Gnome::Shell::UI::Status::Volume.InputIndicator();
      $!brightness     = Gnome::Shell::UI::Status::Brightness.Indicator();
      $!remoteAccess   = Gnome::Shell::UI::Status::RemoteAccess.RemoteAccessApplet();
      $!location       = Gnome::Shell::UI::Status::Location.Indicator();
      $!thunderbolt    = Gnome::Shell::UI::Status::Thunderbolt.Indicator();
      $!nightLight     = Gnome::Shell::UI::Status::NightLight.Indicator();
      $!darkMode       = Gnome::Shell::UI::Status::DarkMode.Indicator();
      $!backlight      = Gnome::Shell::UI::Status::Backlight.Indicator();
      $!powerProfiles  = Gnome::Shell::UI::Status::PowerProfile.Indicator();
      $!rfkill         = Gnome::Shell::UI::Status::RFKill.Indicator();
      $!autoRotate     = Gnome::Shell::UI::Status::AutoRotate.Indicator();
      $!unsafeMode     = Gnome::Shell::UI::Status::UnsafeMode.Indicator();
      $!backgroundApps = Gnome::Shell::UI::Status::BackgroundApps.Indicator();

      # add privacy-related indicators before any external indicators
      my $pos = 0;
      $!indicators.insert-child-at-index($!remoteAccess,$pos++);
      $!indicators.insert-child-at-index($!camera,      $pos++);
      $!indicators.insert-child-at-index($!volumeInput, $pos++);
      $!indicators.insert-child-at-index($!location,    $pos++);

      # append all other indicators
      $!indicators.add_child($!brightness);
      $!indicators.add_child($!thunderbolt);
      $!indicators.add_child($!nightLight);
      $!indicators.add_child($!network)        if $!network
      $!indicators.add_child($!darkMode);
      $!indicators.add_child($!backlight);
      $!indicators.add_child($!powerProfiles);
      $!indicators.add_child($!bluetooth)      if $!bluetooth;
      $!indicators.add_child($!rfkill);
      $!indicators.add_child($!autoRotate);
      $!indicators.add_child($!volumeOutput);
      $!indicators.add_child($!unsafeMode);
      $!indicators.add_child($!system);

      my \n = N_QUICK_SETTINGS_COLUMNS;
      given $.menu.getFirstItem {
        $.addItemsBefore($!system.quickSettingsItems,        $_, n);
        $.addItemsBefore($!volumeOutput.quickSettingsItems,  $_, n);
        $.addItemsBefore($!volumeInput.quickSettingsItems,   $_, n);
        $.addItemsBefore($!brightness.quickSettingsItems,    $_, n);
        $.addItemsBefore($!camera.quickSettingsItems,        $_);
        $.addItemsBefore($!remoteAccess.quickSettingsItems,  $_);
        $.addItemsBefore($!thunderbolt.quickSettingsItems,   $_);
        $.addItemsBefore($!location.quickSettingsItems,      $_);
        $.addItemsBefore($!network.quickSettingsItems,       $_) if $!network;
        $.addItemsBefore($!bluetooth.quickSettingsItems,     $_) if $!bluetooth;
        $.addItemsBefore($!powerProfiles.quickSettingsItems, $_);
        $.addItemsBefore($!nightLight.quickSettingsItems,    $_);
        $.addItemsBefore($!darkMode.quickSettingsItems,      $_);
        $.addItemsBefore($!backlight.quickSettingsItems,     $_);
        $.addItemsBefore($!rfkill.quickSettingsItems,        $_);
        $.addItemsBefore($!autoRotate.quickSettingsItems,    $_);
        $.addItemsBefore($!unsafeMode.quickSettingsItems,    $_);
      }

      $.menu.addItem($_, n) for $!backgroundApps.quicksettingsItems;
    }
  }

  method addExternalIndicators ($i, $c) {
    $!indicators.insert-child-below($i // $!brightness // Nil);
    $.addItemsBefore(
      $i.quickSettingsItems,
      $!backgroundApps?.quickSettingItems?.at(-1)
    );
  }
}

constant PANEL_ITEM_IMPLEMENTATIONS = (
  activities      => Gnome::Shell::UI::Status::Activities::Button,
  appMenu         => Gnome::Shell::UI::Status::AppMenu::Button,
  quickSettings   => Gnome::Shell::UI::Status::QuickSettings,
  dateMenu        => Gnome::Shell::UI::Status::DateMenu::Button,
  a11y            => Gnome::Shell::UI::Status::AT::Indicator,
  keyboard        => Gnome::Shell::UI::Status::InputSource::Indicator,
  dwellClick      => Gnome::Shell::UI::Status::DwellClick::Indicator,
  screenRecording => Gnome::Shell::UI::Status::ScreenRecording::Indicator,
  screenSharing   => Gnome::Shell::UI::Status::ScreenSharing::Indicator,
}

class Gnome::Shell::UIL::Panel
  is Gnome::Shell::St::Widget
{
  has $gnome-ui-panel is implementor;

  reg(::?CLASS);

  has $!sessionStyle;

  has $!leftBox   = Gnome::Shell::St::BoxLayout( name => 'panelLeft'  );
  has $!centerBox = Gnome::Shell::St::BoxLayout( name => 'panelCenter');
  has $!rightBox  = Gnome::Shell::St::BoxLayout( name => 'panelRight' );

  method boxOpacity ($v) is rw {
    Proxy.new:
      FETCH => -> $     { $!leftBox.opacity },
      STORE => -> $, \v {
        my $i = $v > 0;

        ( .opacity, .reactive ) = ($v, $i)
          for $!leftBox, $!centerBox, $!rightBox;
      }
  }

  submethod BUILD {
    self.setAttributes(
      name     => 'panel',
      reactive => True
    );

    self.set-offscreen-redirect(CLUTTER_OFFSCREEN_REDIRECT_ALWAYS);
    self.add-child($_) for $!leftBox, $!rightBox, $!centerBox;

    self.Button-Press-Event.tap: sub (|c) { onButtonPressEvent(|c) }
    self.Touch-Event.tap:        sub (|c) { onTouchEvent(|c)       }

    Main.overview.Showing.tap: SUB {
      $.add-style-pseudo-class('overview');
    }
    Main.overview.Hiding.tap: SUB {
      $.remove-style-pseudo-class('overview');
    }

    Main.layoutManager.panelBox.add-chld(self);
    Main.ctrlAltTabManager.addGroup(
      self,
      'Top Bar',
      'shell-focus-top-bar-symbolic'
      sortGroup => CTRL_ALT_TAB_SORT_GROUP_TOP
    );
    Main.sessionMode.Updated.tap: sub (|c) { self.updatePanel(|c) }
    Global.display.Workareas-Changed.tap: SUB { self.queue-relayout }
    self.updatePanel;
  }

  method get_preferred_width ($fh) is vfunc {
    return [0, .width] with Main.layoutManager.primaryMonitor;
    [0, 0]
  }

  method allocate ($b) is vfunc {
    $.set-allocation($box);

    my ($aw, $ah) = ( .w, .h ) given $box;

    my ($lnw, $cnw, $rnw) = ($!leftBox, $!centerBox, $!rightBox).map({
      .get-preferred-width(-1).tail
    });

    my ($cw, $co) = ($cnw, 0);
    with Mail.layoutManager.findMonitorForActor(self) -> $m {
      $co = 2 * (.x - $m.x) + .w - $m.w
        given Main.layoutManager.getWorkAreaForMonitor($m.index);
    }

    my $sw = max( 0, ($aw - $cw + $co) / 2 );
    my $cb = Mutter::Clutter::ActorBox.new;

    ( .y1, .y2 ) = (0, $ah) given $cb;
    Clutter::Main.is-rtl
      ?? ( .x1, .x2 ) = ( max( $aw, min($sw.floor, $lnw) ), $aw )
      !! ( .x1, .x2 ) = ( 0, min($sw.floor, $lnw )
        given $cb;
    $!leftBox.allocate($cb);

    my $xx1 = $sw.ceiling
    ( .x1, .y2, .x2, .y2 ) = ($xx1, $0, $cb.x1, $xx1 + $c1, $ah) given $cb;
    $!centerBox.allocate($cb);

    ( .y1, .y2 ) = (0, $ah) given $cb;
    ( .x1, .x2 ) = Clutter::Main.is-rtl
      ?? ( 0,                                  min($sw.floor, $rnw) )
      !! ( max($aw - min($sw.floor, $rnw), 0), $aw                  )
        given $cb;
    $!rightBox.allocate($cb);
  }

  method tryDragWindow ($e) {
    return CLUTTER_EVENT_PROPAGATE
      if Main.modalCount > 0 || $.equals(Global.stage.get-event-actor($e);

    my ($x, $y) = $e.coords;
    my  $dw     = $.getDraggableWindowForPosition($x);

    return CLUTTER_EVENT_PROPAGATE unless $dw;

    $dw.begin-drag-op(
      META_GRAB_OP_MOVING,
      .device,
      .event-sequence,
      .time,
      Graphene::Point.new($x, $y)
    ) ?? CLUTTER_EVENT_STOP !! CLUTTER_EVENT_PROPAGATE
  }

  method onButtonPress ($a, $e) {
    return CLUTTER_EVENT_PROPAGATE if $e.button !== CLUTTER_BUTTON_PRIMARY;
    $.tryDragWindow($e);
  }

  method onTouchEvent ($a, $e) {
    return CLUTTER_EVENT_PROPAGATE if $e.type !== CLUTTER_EVENT_TOUCH_BEGIN;
    $.tryDragWindow($e);
  }

  method key_press_event ($e) is vfunc {
    do if $e.key-symbol == CLUTTER_KEY_Escape {
      Global.display.focus-default-window($e.time)
      CLUTTER_EVENT_STOP
    } else {
      callsame;
    }
  }

  method toggleMenu ($i) {
    return unless $i && $i.mapped;
    return unless $i.reactive;

    my $m = $i.menu;
    $m.toggle;
    $m.actor.navigate-focus(ST_DIRECTION_TAB_FORWARD) if $m.isOpen
  }

  method closeMenu ($i) {
    return unless $i && $i.mapped;
    return unless $i.reactive;

    $i.menu.close;
  }

  method toggleCalendar      { $.toggleMenu($!statusArea.dateMenu)      }
  method toggleQuickSettings { $.toggleMenu($!statusArea.quickSettings) }
  method closeCalendar       { $.closeMenu($!statusArea.dateMenu)       }
  method closeQuickSettings  { $.closeMenu($!statusArea.quickSettings)  }

  method updatePanel {
    my $p = Main.sessionMode.panel;
    $.hideIndicators;
    $.updateBox($p.left,   $!leftBox);
    $.updateBox($p.center, $!centerBox);
    $.updateBox($p.right,  $!rightBox);

    Main.messageTray.bannerAlignment = do {
      when    $p.left.includes('dateMenu')   { CLUTTER_ALIGN_START  }
      when    $p.center.includes('dateMenu') { CLUTTER_ALIGN_END    }
      default                                { CLUTTER_ALIGN_CENTER }
    }

    $.remove-style-class-name($_) with $!sessionStyle;
    $!sessionStyle = Main.sessionMode.panelStyle;
    $.add-style-class-name($_) with $!sessionStyle;
  }

  method hideIndicators {
    for PANEL_ITEM_INDICATORS.values {
      .container.hide with $_;
    }
  }

  method ensureIndicator ($r) {
    if $!statusArea{$r}.defined {
      if PANEL_ITEM_IMPLEMENTATIONS{$r} !== Nil {
        return $!statusArea{$r} = .new(self);
      }
    }
    Nil
  }

  method updateBox ($e, $b) {
    my $n = $b.elems;

    for $e.kv -> $i, $r {
      $.addToPanelBox($r, $_, $i + $n, $b) with $.ensureIndicator($r);
    }
  }

  method addToPanelBox ($r, $i, $p, $b) {
    my $c = $i.container;
    $c.show;

    .remove-child($c) with $c.parent;

    $b.insert-child-at-index($c, $p);
    $!statusArea{$r} = $i;
    my $did = $i.destroy.tap: sub (*@a) {
      $!statusArea{$r}:delete;
      $did.clear;
    }
    $i.Menu-Set.tap: sub (|c) { self.onMenuSet( |c ) }
    $.onMenuSet($i);
  }

  method addToStatusArea ($r, $i, $p is copy, $b) {
    X::Gnome::Shell::Error.new(
      message => "Extension point conflict: there is already a stauts {
        '' }indicator for role { $r }"
    ).throw if $!statusArea{$r};

    X::Gnome::Shell::Error::Type.new(
      message => "Status indicator must be an instance of {
        '' }Gnome::Shell::UI::PanelMenu::Button"
    ).throw unless $i ~~ Gnome::Shell::UI::PanelMenu::Button;

    $p //= 0;
    my $boxes = (
      left   => $!leftBox,
      center => $!centerBox,
      right  => $!rightBox
    );
    $!statusArea{$r} = $i;
    $.addToPanelBox($r, $i, $p, $boxes{$b} // $!rightBox);
    $i
  }

  method onMenuSet ($i) {
    return if $i.menu.not || $i.menu.openChangeConnected

    $!menuManager.addMenu($i.menu);
    $i.menu.openChangeConnected = True;
    $i.menu.Open-State-Changed.tap: sub ( *@a ($m, $io) ) {
      my $ba = do {
        when $!leftBox.contains($i.container)   { CLUTTER_ALIGN_START  }
        when $!centerBox.contains($i.container) { CLUTTER_ALIGN_CENTER }
        when $!rightBox.contains($i.container)  { CLUTTER_ALIGN_END    }
      }

      Main.messageTray.bannerBlocked = $io
        if $ba == Main.messageTray.bannerAlignment;
    }
  }

  method getDraggableWindowForPosition ($sx) {
    my $wm  = Global.workspace-manager;
    my $w   = $wm.get-active-workspace.list-windows;
    my $aws = Glibal.display.sort-windows-by-stacking($w).reverse;

    $aws.grep({
      my $r = .get-frame-rect;
      [&&](
        .is-on-primary-monitor,
        .showing-on-its-workspacce,
        .window-type != META_WINDOW_DESKTOP,
        .maximized-vertically,
        $r.x < $sx < $r.x + $r.w
      );
    })
  }
}
