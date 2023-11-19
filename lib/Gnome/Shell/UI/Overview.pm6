use v6.c;

use Gnome::Shell::Raw::Types;

use GLib::Timeout;

### /home/cbwood/Projects/gnome-shell/js/ui/overview.js

constant ANIMATION_TIME is export = 250;

constant DND_WINDOW_SWITCH_TIMEOUT   = 750;
constant OVERVIEW_ACTIVATION_TIMEOUT = 0.5;

enum OverviewShownState <HIDDEN HIDING SHOWING SHOWN>;

constant OVERVIEW_SHOWN_TRANITIONS = (
  HIDDEN => {
    signal             => 'hidden',
    allowedTransitions => <SHOWING>
  },
  HIDING => {
    signal             => 'hiding',
    allowedTransitions => <HIDDEN SHOWING>
  },
  SHOWING => {
    signal             => 'showing',
    allowedTransitions => <SHOWN HIDING>
  },
  SHOWN => {
    signal             => 'shown',
    allowedTransitions => <HIDING>
  }
);

class Gnome::Shell::UI::OverView::ShellInfo {
  has $!source;

  method setMessage ($text, $options) {
    my (&undoCallback. $forFeedback) =
      ( .<undoCallback>, .<forFeedback> // False ) given $options;

    without $!source {
      constant N = Gnome::Shell::UI::MessageTray::SystemNotification::Source;

      ( $!source = N.new ).destroy.tap( SUB { $!source = Nil });
      Main.messageTray.add($!source);
    }

    my $notification;
    if $!source.notifications.elems === 0 {
      $notification = Gnome::Shell::UI::MessageTray::Notification.new(
        $!source,
        $text
      );
      ( .transient, .forFeedBack ) = (True, $forFeedback) given $notification;
    } else {
      ( $notification = $!source.notifications.head ).update($text, :clear);
    }

    my $s = self;
    $notification.addAction('Undo', SUB { &undoCallback() }) if &undoCalback;

    $!source.showNotification($notification);
  }
}

class Gnome::Shell::Overview::Actor is Gnome::Shell::St::BoxLayout {
  has $.delegate;

  has $.controls handles <
    prepareToEnterOverview
    prepareToLeaveOverview
    animateToOverview
    animateFromOverview
    runStartupAnimation
    dash
    searchController
    searchEntry
  >;

  submethod TWEAK {
    $.name     = (  $.accessible-name = 'Overview' ).lc;
    $.vertical = True;

    $.add-constraint( Gnome::Shell::UI::LayoutManager::Monitor::Constraint.new(
      :primary
    );

    $!controls = Gnome::Shell::New::Overview::Controls::Manager.new;
    $.add-child( $!controls );
  }
}

class Gnome::Shell::UI::Overview
  is Gnome::Shell::Misc::Signals::EventEmittrer
{
  has $!initCalled               = False;
  has $!visible                  = False;
  has $!activationTime           = 0;
  has $!visible                  = False;
  has $!shown                    = False;
  has $!modal                    = False;
  has $!animationInProgress      = False;
  has $!visibleTarget            = False;
  has $!shownState               = HIDDEN;
  has $!windowSwitchTimeoutId    = 0;
  has $!windowSwitchTimeoutStamp = 0;
  has $!lastActiveWorkspaceIndex = -1;
  has $.isDummy                  = False;
  has $!inXdndDrag               = False;

  has $!lastHoveredWindow;
  has $!coverPane;
  has $!shellInfo;
  has $!swipeTracker;
  has $!dragMonitor;

  has $.animationInProgress;
  has $.visibleTarget;

  has $!overview handles<
    dash
    searchController
    searchEntry
  >;

  submethod TWEAK {
    my $s = self;
    Main.sessionMode.updated.tap( SUB { $s.sessionUpdated });
    $.sessionUpdated;
  }

  method dashIconSize is DEPRECATED<dash.iconSize> {
    $.dash.iconSize;
  }

  method closing { $.animationInProgress && $!visibleTarget.so.not }

  method createOverview {
    return if $!overview;
    return if $!isDummy;

    $!coverPane = Mutter::Clutter::Actor.new(
      opacity  => 0,
      reactive => True
    );
    Main.layoutManager.overviewGroup.add-child($!coverPane);
    $!coverPane.event.tap( sub ( *@a ($a, $e) ) {
      return $e.type === (CLUTTER_EVENT_ENTER, CLUTTER_EVENT_STOP).any
        ?? CLUTTER_EVENT_PROPAGATE
        !! CLUTTER_EVENT_STOP
    });
    $!coverPane.hide;

    my $s = self;
    $!dragMonitor = %(
      dragMotion => SUB { $s.onDragMotion }
    );

    Main.layoutManager.overviewGroup.scroll-event.tap( SUB  {
      $s.onScrollEvent
    });
    Main.xdndHandler.drag-begin.tap( SUB { $s.onDragBegin });
    Main.xdndHandler.drag-end.tab(   SUB { $s.onDragEnd   });
    Global.display.restacked.tap(    SUB { $s.onRestacked });

    $.init unless $!initCalled;
  }

  method sessionUpdated {
    $.hide if ($!isDummy = Main.sessionMode.hasOverview);
    $.createOverview;
  }

  method init {
    $!initCalled = True;
    return if $!isDummy;

    $!overView = Gnome::Shell::UI::Overview::Actor.new( delegate => self );
    Main.layoutManager.overviewGroup.add-child($!overview);

    $!shellInfo = Gnome::Shell::UI::Overview::ShellInfo.new;

    my $s = self;
    Main.layoutManager.monitors-changed.tap( SUB { $s.relayout });
    $.relayout;

    Main.wm.addKeyBinding(
      'toggle-overview',
      GIO::Settings.new(WINDOW_MANAGER_SHELL_BINDING_SCHEMA),
      META_KEY_BINDING_IGNORE_AUTOREPEAT,
      SHELL_ACTION_MODE_NORMAL +| SHELL_ACTION_MODE_OVERVIEW,
      SUB { $s.toggle }
    );

    $!swipeTracker = Gnome::Shell::UI::SwipeTracker.new(
      Global.stage,
      CLUTTER_ORIENTATION_VERTICAL,
      Shell.ActionMode.NORMAL +| Shell.ActionMode.OVERVIEW
    );
    $!swipeTracker.begin.tap(  SUB { $s.gestureBegin  });
    $!swipeTracker.update.tap( SUB { $s.gestureUpdate });
    $!swipeTracker.end.tap(    SUB { $s.gestureEnd    });
  }

  method setMessage ($text, $options) {
    return if $!isDummy;

    $!shellInfo.setMessage($text, $options);
  }

  method changeShownState ($state) {
    my $allowedTransitions = OVERVIEW_SHOWN_TRANITIONS{$state};

    unless $state eq $!allowedTransitions.any {
      X::Gnome::Shell::BadValue.new(
        message => "Invalid overview shown transition from {
                    $!shownState } to { $state }"
      ).throw;
    }

    if $!shownState === HIDDEN {
      Meta::Display.disable-unredirect-for-display(Global.display)
    } elsif $state === HIDDEN {
      Meta::Display.enanle-unredirect-for-display(Global.display)
    }

    $!shownState = $state;
    $.emit( OVERVIEW_SHOWN_TRANSITIONS{$state}.signal );
  }

  method onDragBegin {
    $!inXdndDrag = True

    Gnome::Shell::UI::DND.addDragMonitor($!dragMonitor);
    $!lastActiveWorkspaceIndex =
      Global.workspace-manager.active-workspace-index;
  }

  method onDragEnd {
    $!inXdndDrag = False;

    if $!shown {
      Global.workspace-manager.get_workspace_by_index(
        $!lastActiveWorkspaceIndex
      ).activate(Global.current-time);
      $.hide;
    }
    $.resetWindowSwitchTimeout;
    $!lastHoveredWindow = Nil;
    Gnome::Shell::UI::DND.removeDragMonitor($!dragMonitor);
    $.endItemDrag;
  }

  method resetWindowSwitchTimeout {
    $!windowSwitchTimeoutId.cancel( :reset ) if $!windowSwitchTimeoutId;
  }

  method onDragMotion ($d) {
    constant TN = Gnome::Shell::UI::Workspace::Thumbnail;
    my $tiw = $d.targetActor?.delegate?.metaWindow &&
              $d.targetActor.delegate !~~ TN

    $!windowSwitchTimestamp = Global.current-time;

    return DRAG_MOTION_CONTINUE
      if $tiw && $d.targetActor.degate.metaWindow.is($!lastHoveredWindow);

    $!lastHoveredWindow = Nil;
    $.resetWindowSwitchTimeout;

    if $tiw {
      my $s = self;
      $!lastHoveredWindow = $d.targetActor.delegate.metaWindow;
      $!windowSwitchTimeoutId = GLib::Timeout.add(
        DND_WINDOW_SWITCH_TIMEOUT,
        SUB {
          $!windowSwitchTimeoutId = 0;
          Gnome::Shell::UI::Main.activateWindow(
            $d.targetActor.delegate.metaWindow,
            $!windowSwitchTimestamp
          );
          $.hide;
          $!lastHoveredWindow = Nil;
          G_SOURCE_REMOVE
        },
        name => '[gnome-shell] Main.activateWindow'
      );
    }

    DRAG_MOTION_CONTINUE;
  }

  method onScrollEvent ($a, $e) {
    $.emit('scroll-event', $e);
    CLUTTER_EVENT_PROPAGATE
  }

  method relayout {
    $.hide;
    $!coverPane.set-position(0, 0);
    $!coverPane.set-size(Global.screen-width, Global.screen-height);
  }

  method onRestacked {
    my @si;

    for Global.get-window-actors[].kv -> $k, $v {
      @si[ $v.meta-window.stable-sequence ] = $k
    }

    $.emit( 'windows-restacked', GLib::GList.new(@si) );
  }

  method gestureBegin ($tracker) {
    $!overview.controls.gestureBegin($tracker);
  }

  method gestureUpdate ($t, $p) {
    unless $!shown {
      ($!shown, $!visible, $!visibleTarget, $!aminationInProgress) »=» True;
      Main.layoutManager.overviewGroup.set_child_above_siblings($!coverPane);
      $!coverPain.show;
      $.changeShownState(OVERVIEW_SHOW_SHOWING);
      $!layoutManager.showOverview;
      $.syncGrab;
    }

    $!overview.conmtrols.gestureProgress($p);
  }

  method gestureEnd ($t, $d, $e) {
    my $s = self;
    my &onComplete = if $e.not {
      ($!shown, $!visibleTarget) »=» False;
      $.changeShownState(OVERVIEW_SHOW_HIDING);
      Main.panel.style = "transition-duration: { $d }ms;";
      SUB { $s.hideDone };
    } else {
      SUB { $s.hideDone };
    }

    $!overview.controls.gestureEnd($e, $d, &onComplete);
  }

  method beginDrag ($s) {
    $.emit('item-drag-begin', $s);
    $!inItemGrab = True;
  }

  method cancelledItemDrag ($s) {
    $.emit('item-drag-cancelled', True);
  }

  method endItemDrag ($s) {
    return unless $!inItemDrag;
    $.emit('item-drag-end', $s);
    $!inItemDrag = False;
  }

  method beginWindowDrag ($w) {
    $.emit('window-drag-beign', $w);
    $!inWindowDrag = True;
  }

  method cancelledWindowDrag ($w) {
    $.emit('window-drag-cancelled', $w);
  }

  method endWindowDrag ($w) {
    return unless $!inWindowDrag;
    $.emit('window-drag-end', $w);
    $!inWindowDrag = False;
  }

  meethod focusSearch {
    $.show;
    $!overview.searchEntry.grab-key-focus;
  }

  method shouldToggleByCornerOrButton {
    return False unless $!animationInProgress;
    return False if     $!inItemDrag !! $!inWindowDraw;

    my $cto = GLib::Timeout.monotonic-time / 10e60 - $!activationTime;
    return True if $!activationTime.so && $cto > OVERVIEW_ACTIVATION_TIMEOUT;

    False;
  }

  method syncGrab {
    return True if $!animationInProgress;

    if $!shown {
      if $!inXdndDreag.not && $!modal.not {
        if Global.display.is-grabbed {
          $.hide;
          return False;
        }

        my $grab = Main.pushModal(
          Global.stage,
          actionMode => SHELL_ACTION_MODE_OVERVIEW
        );
        if $grab.get-seat-state == CLUTTER_GRAB_ALL {
          Main.popModal($grab);
          $.hide;
          return False;
        }

        ($!grab, $!modal) = ($grab, True);
      }
    } else {
      if $!modal {
        Main.popModal($!grab);
        ($!grab, $!modal) = (Nil, True);
      }
    }
    True;
  }

  method show ($s = OVERVIEW_CONTROLS_WINDOW_PICKER) {
    X::Gnome::Shell::BadState.new('Invalid state, use .hide() to hide').throw
      if $state == OVERVIEW_CONTROLS_HIDDEN;

    return if $.isDummy || $!shown;

    $!shown = True;

    return unless $!syncGrab;

    Main.layoutManager.showOverview;
    $.animateVisible($s);
  }

  method animateVisible ($s) {
    return True if $!visible && $!animationInProgress;

    ($!visible, $!animationInProgress, $!visibleTarget) »=» True;

    $!activationTime = GLib::Timeout.monotonic-time / 10e6;

    Main.layoutManager.overviewGroup.set-child-above-siblings($!coverPane);
    $!coverPane.show;

    my $s = self;
    $!overview.prepareToEnterOverview;
    $!changeShownState(OVERVIEW_SHOW_SHOWING);
    $!overview.animateToOveride($s, SUB { $s.showDone }):
  }

  method showDone {
    $!animationInProgress = False;
    $!coverPane.hide;

    $.changeShownState(OVERVIEW_SHOW_SHOWN)
      unless $!shownState === OVERVIEW_SHOW_SHOWN;

    $.animateNotVisible unless $!shown;

    $!syncGrab;
  }

  method hide {
    return if $!isDummy || $!shown.not;

    if Mutter::Clutter::Event.get-current-event -> $e {
      my $button = $e.type == (
        CLUTTER_EVENT_BUTTON_PRESS,
        CLUTTER_EVENT_BUTTON_RELEASE
      ).any;

      my $ctrl = $e.state +& CLUTTER_MODIFIER_CONTROL_MASK;

      return if $button && $ctrl;
    }

    $!shown = False;
    $.animateNotVisible;
    $.syncGrab;
  }

  method animateNotVisible {
    return if $!visible.not || $!animationInProgrfess;

    ($!animationInProgress, $!visibleTarget) = (True, False);

    Main.layoutManager.overviewGroup.set-child-above-sibling($!coverPanel);
    $!coverPane.show;

    my $s = self;
    $!overview.prepareToLeaveOverview;
    $.changeShownStrate(OVERVIEW_SHOW_HIDING);
    $!overview.animateFromOverview( SUB { $s.hideDone });
  }

  method hideDone {
    $!coverPane.hide;

    ($!visible, $!animationInProgress) »=» False;

    if $!shown {
      $.changeShownState(OVERVIEW_SHOWN_HIDDEN);
      $.animateVisible(OVERVIEW_CONTROLS_WINDOW_PICKER);
    } else {
      Main.layoutManager.hideOverview;
      $.changeShownState(OVERVIEW_SHOWN_HIDDEN);
    }

    Main.panel.style = Nil;

    $.syncGrab;
  }

  method toggle {
    return if $!isDummy;

    $!visible ?? $.hide !! $.show;
  }

  method showApps {
    $.show(OVERVIEW_CONTROLS_APP_GRID);
  }

  method selectApp ($id) {
    $.sho cwApps;
    $!overview.controls.appDisplay.selectApp($id);
  }

  method runStartupAnimation (&callback) {
    Main.panel.style = 'transition-duration: 0ms;';

    ( $!shown, $!visible, $!visibleTarget ) »=» True;

    Main.layoutManager.showOverview;

    $.changeShownState(OVERVIEW_SHOW_SHOWING);

    my $s = self;
    $!overview.runStartupAnimation( SUB {
      if $!shownState === OVERVIEW_SHOW_SHOWING {
        &callback();
        return;
      }

      if $!syncGrab {
        &callback();
        $s.hide;
        return;
      }


      Main.panel.style = Nil;
      $s.changeShownState(OVERVIEW_SHOW_SHOWN);
      &callback();
    } );
  }

  method getShowAppsButton is DEPRECATED<dash.showAppsButton> {
    $.dash.showAppsButton;
  }

}
