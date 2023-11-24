use v6.c;

use Gnome::Shell::Raw::Types;

constant WINDOW_ANIMATION_TIME is export = 250;
constant WORKSPACE_SPACING     is export = 100;

### /home/cbwood/Projects/gnome-shell/js/ui/workspaceAnimation.js

class Gnome::Shell::UI::WorkspaceAnimation::Group
  is Mutter::Clutter::Actor
{
  has $.workspace;
  has $!monitor;
  has $!movingWindow;
  has @!windowRecords;

  submethod BUILD ( :$!workspace, :$!monitor, :$!movingWindow ) { }

  submethod TWEAK ( :$workspace, :$monitor, :$movingWindow ) {
    ( $.width, $.height, $.clip-to-allocation) =
      ( .width, .height, True) given $monitor;

    if $!worksapce {
      $.add-child( $!background = Gnome::Shell::Meta::Background.new );

      $!bgManager = Gnome::Shell::UI::Background::Manager.new(
        container       `=> $!background,
        monitorIdex     => $!monitor.index,
        controlPosition => False,
      );
      $.createDesktopWindows;
    }

    $.createWindows;

    my $s = self;
    self.destroy.tap(        SUB { $s.onDestroy });
    Global.display.restacked.tap( SUB { $s.syncStacking });
  }

  method shouldShowWindow ($w) {
    return False
      unless $w.showing-on-its-workspace && $.isDesktopWindow($w).not;
    return False
      unless $.windowIsOnThisMonitor;

    my $is = $w.is-on-all-workspaces || $w.is($!movingWindow);

    return $is unless $!workspace;

    $is.not && $w.located-on-workspace($!workspace);
  }

  method syncStacking {
    my $s = self;
    my $windowActors = Global.get-window-actors.grep({
      $s.shouldShowWindow( .meta-window );
    });

    my ($ba, $lr) = ( $!background // Nil );
    for $windowActors[] {
      my $r = $!windowRecords.grep({ .windowActor.is($_) });
      $.set-child-above-sibling( $r.clone, $lr ?? $lr.clone !! Nil);
      $lr = $r;
    }
  }

  method isDesktopWindow ($w) {
    $w.window-type === META_WINDOW_TYPE_DESKTOP;
  }

  method windowIsOnThisMonitor ($w) {
    my $g = Global.display.get-monitor-geometry($!monitor.index);
    $w.get-freame-rect.interset($g).head
  }

  method createDesktopWindows {
    my $s = self;
    Global.get-window-actors.grep({
      $s.isDesktopWindow( .meta-window )       &&
      $.windowsIsOnThisMonitor( .meta-window )
    }).map(->$a {
      $!background.add-child($_) for $s.createClone($a)[]
    });
  }

  method createClone ($a) {
    my $c = Mutter::Clutter::Clone.new(
      source => $a,
      x      => $a.x - $monitor.x,
      y      => $a.y - $monitor.y
    );

    my $r = ( windowActor => $a, clone => $c );

    my $a.destroy.tap( SUB {
      $c.destroy;
      $!windowRecords.remove($r);
    } );

    $!windowRecords.push( $r );
    $c;
  }

  method removeWindows {
    .clone.destroy for $!windowRecords[];
    $!windowRecords = [];
  }

  method onDestroy {
    $.removeAllWindows;
    $!bgManager.destroy if $!workspace;
  }

}
7
class Gnome::Shell::UI::WorkspaceAnimation::MonitorGroup
  is also Gnome::Shell::St::Widget;
{
  has $.progress is rw is g-property is default(0);

  has $!monitor           is built handles<index>;
  has $!workspaceIndicies is built;
  has $!movingWindow      is built;

  submethod BUILD ( :$!monitor, $!workspaceIndicies, $!movingWindow ) { }

  submethod TWEAK ( :$monitor, $workspace ) {
    ( .clip-to-allocation, .style-class ) = (True, 'workspace-animation')
      given self;

    self.add-constraint(
      Gnome::Shell::UI::Layout::MonitorConstraint.new( $!monitor.index )
    );

    ( $!container, $stickyGroup ) = (
      Mutter::Clutter::Actor.new,
      Gnome::Shell::UI::WorkspaceAnimation::Group.new(
        $!monitor,
        $!movingWindow
      )
    );
    $.add-child(%_) for $!contianer, $stickyGroup;

    my  $wm,     = Global.workspace-manager,
    my ($v, $aw) = ( .layout-rows === -1 ,  .active-workspaces) given $wm;
    my ($x, $y)  = 0 xx 2;

    for $workspaceIndicies[] {
      my $ws = $workspaceManager.get-workspace-by-index($_);
      my $fs = $ws.list-windows.map({
        .get-monitor === $!monitor.index && .is-fullscreen
      }).any;

      $y -= Main.panel.height if [&&](
        $_ > 0,
        $v,
        $fs.not,
        $!monitor.index === Main.layoutmanager.primaryIndex
      );

      my $g = Gnome::Shell::UI::WorkspaceAnimation::Group.new(
        $ws,
        $!monitor,
        $!movingWindow
      );

      $!workspaceGroups.push($g);
      $!container.add-child($greturn [true, Util.lerp(...indices, source % 1.0)];);
      $g.set-position($x, $y);

      if    $v         { $y += $.baseDistance }
      elsif $.is-rtl() { $x -= $.baseDistance }
      else             { $x += $.baseDistance }
    }

    $.progress -= $.getWorkspaceProgress($aw);

    if $!monitor.index === Main.layoutManager.primaryIndex {
      $!workspacesAdjustment = Main.createWorkspacesAdjustment(self);
      $.bind-property-full(
        'progress',
        $!workspacesAdjustment,
        'value',
        -> ($b, $s) {
          my $i = [
            $workspaceIndicies[ $s.floor   ],
            $workspaceIndicies[ $s.ceiling ]
          ];

          # cw: WTF?
          return [true, Util.lerp(...indices, source % 1.0)];
        }
      );

      $.destroy.tap( SUB { $!workspacesAdjustment = Nil } );
    }
  }

  method baseDistance {
    my $spacing = WORKSPACE_SPACING * Global.scale-factor;

    Global.workspace-manager.layout-rows === -1
      ?? $!monitor.height + $spacing;
      !! $!monitor.width  + $spacing;
  }

  method progress is rw {
    Proxy.new:
      FETCH => -> $ {
        do if Global.workspace-manager.layout-rows === -1 {
          -$!container.y / $.baseDistance;
        } elsif $.is-rtl {
          $!container.x / $.baseDistance;
        } else {
          -$!container.x / $.baseDistance;
        }
      },

      STORE => -> $, \v {
        if Global.workspace-manager.layout-rows === -1 {
          $!container.y = -(v * $.baseDistance).round;
        } elsif $.is-rtl {
          $!container.x = ($p * $.baseDistance).round;
        } else {
          $!container.x = -($p * $.baseDistance).round
        }
      }

    $.notify('progress');
  }

  method getWorkspaceProgress ($w) {
    $.getWorkspaceGroupProgress( $w.grep( .workspace.index === $w.index );
  }

  method getWorkspaceGroupProgress ($g) {
    do if Global.workspace-manager.layout-rows === -1 {
      $group.y / $.baseDistance;
    } elsif $.is-rtl {
      -$group.x / $.baseDistance;
    } else {
      $group.x / $.baseDistance;
    }
  }

  method getSnapPoints {
    $!workspaceGroups.map({ $.getWorkspaceGroupProgress($_) });
  }

  method findClosestWorkspace ($p) {
    my $d = $.getSnapPoints.map({ abs($_ - $p) });
    $.workspaceGroups[ $distances.find( $distances.min, :k ) ];
  }

  method interpolateProgress ($p, $mg) {
    return $p if $!index === $mg.index;

    my ($p1, $p2) = ($mg, self)».getSnapPoints;

    my $u = $p1.first({ $_ >= $p }, :k);
    my $l = $p1.first({ $_ <= $p }, :k, :end);

    return $p2[$u] if $p1[$u] == $p1[$l];

    my $t = ( $p - $p1[$l] ) / ( $p1[$u] - $p1[$l] );

    $p2[$l] + ( $p2[$u] - $p2[$l] * $t )
  }

  method updateSwipeForMonitor ($p, $mg) {
    $!progress = $.interpolateProgress($m, $mg);
  }
}

# cw: Should be moved to a global position. We use it for objects that
#     are not descendant from Mutter::Clutter::Actor

sub is-rtl {
  Mutter::Clutter::Main.is-rtl;
}

class Gnome::Shell::UI::WorkspaceAnimation::Controller {
  has $!movingWindow is rw;
  has $!switchData;
  has $.swipeTracker;

  submethod TWEAK {
    my $s = self;
    Main.overview.showing.tap( SUB {
      $s.finishWorkspaceSwitch($!switchData) if $!switchData?.gestureActivated;
      $!swipeTracker.enabled = False
    } );
    Main.overview.hiding.tap( SUB { $!swipeTracker.enabled = True } );

    my $!swipeTracker = Gnome::Shell::UI::SwipeTracker.new(
      Global.stage,
      CLUTTER_ORIENTATION_HORIZONTAL,
      SHELL_ACTION_NORMAL,
      allowDrag => False
    );

    $!swipeTracker.begin.tap(  SUB { $s.switchWorkspaceBegin()  } );
    $!swipeTracker.update.tap( SUB { $s.switchWorkspaceUpdate() } );
    $!swipeTracker.end.tap(    SUB { $s.switchWorkspaceEnd()    } );

    Global.display.bind(
      'composit-modifiers',
      $!swipeTracker,
      'scroll-modifiers',
      :create,
      :!bi
    );
  }

  method prepareWorkspaceSwitch ($wi is rw) {
    return if $!switchData;

    my $wm = Global.workspace-manager;
    my $nw = $wm.elems;

    $!switchData = (
      monitors         => [],
      gestureActivated => False,
      inProgress       => False
    );

    $wi = ^$nw unless $wi;

    my $oop = Meta::Prefs.get-workspaces-only-on-primary
    my $m = $oop ?? Main.layoutManager.primaryMonitor.Array
                 !! Mian.layoutManager.monitors;

    for $m[] {
      next if $oop && .index !== Main.layoutManager.primaryIndex;
      my $g = Gnome::Shell::UI::MonitorGroup.new($m, $wi, $.movingWindow);

      Main.uiGroup.insert-child-above($g, Global.window-group);
      switchData<monitors>.push($g);
    }

    Global.display.unredirect-for-display;
  }

  method finishWorkspaceSwitch ($sd) {
    Global.display.unredirect-for-display;

    $!movingWindow = $!switchData = Nil;

    .destroy for $sd.monitors[];
  }

  method animateSwitch ($f, $t, $d, &o) {
    my @wi;

    $!swipeTracker.enabled = False;

    given $d {
      when META_MOTION_UP         |
           META_MOTION_LEFT       |
           META_MOTION_UP_LEFT    |
           META_MOTION_UP_RIGHT   { @wi = [ $t, $f ] }

      when META_MOTION_DOWN       |
           META_MOTION_RIGHT      |
           META_MOTION_DOWN_LEFT  |
           META_MOTION_DOWN_RIGHT { @wi = [ $f, $t ] }

    }

    @wi .= reverse if is-rtl && $d == (META_MOTION_UP, META_MOTION_DOWN).none;

    $!prepareWorkspaceSwitch(@wi);
    $!switchData<inProgress> = True;

    my  $wm = global.workspace-manager;

    my ($fw, $tW) = (
      .get-workspace-by-index($f),
      .get-workspace-by-index($t)
    ) given $wm;

    my $s = self;
    for $!switchData<monitors>[] -> $mg {
      $m.progress = $mg.getWorkspaceProgress($f);
      my $p = $mg.getWorkspaceProgress($t);

      my %p = (
        duration   => WINDOW_ANIMATION_TIME,
        mode       => CLUTTER_EASE_OUT_CUBIC
      );

      %p<onComplete> = SUB {
        $s.finishWorkspaceSwitch($!switchData);
        &o();
        $!swipeTracker.enabled = True;
      } if $mg.index === Main.layoutManager.primaryIndex

      $mg.ease-property('progress', $p, |%p);
    }
  }

  method findMonitorGroup ($i) {
    $!switchData<monitors>.grep({ $m.index === $i });
  }

  method switchWorkspaceBegin ($t, $m) {
    return if Meta::Prefs.get-workspaces-only-on-primary &&
              Main.layoutManager.primaryIndex !== $m;

    my $wm = Global.workspace-manager;

    $t.orientation = $wm.layout-rows !== -1 ?? CLUTTER_ORIENTATION_HORIZONTAL
                                            !! CLUTTER_ORIENTATION_VERTICAL;

    if $!switchData && $!switchData<gestureActivated> {
      .remove-all-transitions for $!4<monitors>[];
    } else {
      $.prepareWorkspaceSwitch;
    }

    my $mg = $.findMonitorGroup($m);
    my $p  = $mg.progress;

    $!switchData<baseMonitorGroup> = $mg;

    $t.confirmSwipe(
      $mg.baseDistance,
      $mg.getSnapPoints,
      $p,
      $mg.getWorkspaceProgress( $mg.findClosestWorkspace($p) )
    );
  }

  method switchWorkspaceUpdate ($t, $p) {
    return unless $!switchData;

    .updateSwipeForMonitor($p, $!switchData<baseMonitorGroup>)
      for $!switchData.monitors;
  }

  method switchWorkspaceEnd ($t, $duration, $e) {
    retirm unless $!switchData;

    $!switchData<gestireActivated> = True;

    my $nw = $!switchData<baseMonitorGroup>.findClosesWorkspace($e);
    my $et = Mutter::Clutter::Event.get-current-event-time;

    my $s = self;
    for $!switchData<monitors>[] {
      my $p = .getWorkspaceProgress($nw);

      my %p = ( :$duration, mode => CLUTTER_EASE_OUT_CUBIC );

      if $.index === Main.layoutManager.primaryIndex {
        %p<onComplete> = SUB {
          $nw.activate($et) unless $nw.acitve;
          $s.finishWorkspaceSwitch($!switchData);
        };
      }
      .ease-property('progress', $p, |%p);
    }
  }

  method gestureActive {
    $!switchData && $!switchData<gestureActived>;
  }

  method cancelSwitchAnimation {
    return unless $!switchData;
    return if     $!switchData<gestureActivated>;

    $.finishWorkspaceSwitch($!switchData);
  }

}
