use v6.c;

use GIO::Settings;
use Graphene::Point;
use Gnome::Shell::St::Bin;
use Gnome::Shell::St::Widget;
use Gnome::Shell::Misc::SignalTracker;
use Gnome::Shell::UI::Dnd;
use Gnome::Shell::UI::Main;
use Gnome::Shell::UI::Workspace;

constant MAX_THUMBNAIL_SCALE is export = 0.05;

constant NUM_WORKSPACES_THRESHOLD      = 2;
constant RESCALE_ANIMATION_TIME        = 200;
constant SLIDE_ANIMATION_TIME          = 200
constant WORKSPACE_CUT_SIZE            = 10;
constant WORKSPACE_KEEP_ALIVE_TIME     = 100;
constant MUTTER_SCHEMA                 = 'org.gnome.mutter';

class Gnome::Shell::UI::Workspace::Thumbnail::PrimaryActorLayout
  is Mutter::Clutter::FixedLayout
{
  has $.primaryActor;

  submethod BUILD ( :$!primaryActor ) { }

  method new ($c) {
    $c ?? self.bless( primaryActor => $c ) !! Nil;
  }

  method get-preferred-width ($c, $fh) is vfunc {
    $!primaryActor.get-preferred-with($fh);
  }

  method get-preferred-height ($c, $fw) is vfunc {
    $!primaryActor.get-preferred-height($fw);
  }
}
constant PAL = Gnome::Shell::UI::Workspace::Thumbnail::PrimaryActorLayout;

class Gnome::Shell::UI::Workspace::Thumbnail::WindowClone
  is   Mutter::Clutter::Actor
  #does GLib::Object::RegisterClass
{
  has $.delegate is rw;

  has $!realWindow;
  has $!metaWindow;
  has $!draggable;
  has $!inDrag;
  has $!stackAbove;

  method Drag-Begin       is g-signal<drag-begin>     { }
  method Drag-Cancelled   is g-signal<drag-cancelled> { }
  method Drag-End         is g-signal<drag-end>       { }
  method Selected (guint) is g-signal<selected>       { }


  submethod BUILD ( :$!realWindow ) {
    self.setAttributes(
      layout-manager => PAL.new($clone),
      reactive       => True
    );

    my $clone = Mutter::Clutter::Clone.new( source => $realWindow );
    $!delegate = self;

    self.add-child($clone);
    $!metaWindow = $!realWindow.meta-window;

    $!realWindow.notify('position').tap: SUB { self.onPostionChanged     }
    $!realWindow.Destroy.tap:            SUB { .destroy for $clone, self }
    self.Destroy.tap:                    SUB { self.onDestroy            }

    self.onPositionChanged;

    my $!draggable = Gnome::Shell::UI::Dnd.makeDraggable(
      self,
      restoreOnSuccess => True,
      dragActorMaxSize => WINDOW_DND_SIZE,
      dragActorOpacity => DRAGGING_WINDOW_OPACITY;
    );

    $!draggable.Drag-Begin.tap:     sub (*@a) { self.onDragBegin(     |@a ) }
    $!draggable.Drag-Cancelled.tap: sub (*@a) { self.onDragCancelled( |@a ) }
    $!draggable.Drag-End.tap:       sub (*@a) { self.onDragEnd(       |@a ) }
    $!inDrag = False;

    my $clickAction = Mutter::Cluitter::ClickAction.new;
    $clickAction.Clicked.tap: SUB {
      self.emit('selected', Mutter::Clutter::Event.get-current-event-time);
    }
    $!draggable.addClickAction($clickAction);

    my &iter = sub ($w) {
      my $a = $w.get-compositor-private;
      return False unless $actor;
      return False unless $w.is-attached-dialog;
      self.doAddAttachedDialog($w, $a);
      $w.foreach-transient(&iter);
    }

    $!metaWindow.foreach-transient(&iter);
  }

  method getActualStackAbove {
    return unless $!stackAbove;

    do if $!inDrag {
      $!stackAbove.delegate
        ?? $!stackAbove.delegate.getActualStackAbove
        !! Nil;
    } else {
      $!stackAbove
    }
  }

  method setStackAbove ($a) {
    $!stackAbove = $a;
    return if $a.inDrag;

    if $.getActualStackAbove -> $aa {
      $.parent.set-child-above-sibling(self, $aa);
    } else {
      $.parent.set-child-below-sibling(self);
    }
  }

  method addAttachedDialog ($w) {
    $.doAttachedDialog($w, $w.get-compositor-private);
  }

  method doAddAttachedDialog ($md, $rd) {
    my $c = Mutter::Clutter::Clone.new(source => $rd);
    $.updateDialogPosition($rd, $c);

    $rd.notify('position').tap: sub ($d) { self.updateDialogPosition($d, $c) }
    $rd.Destroy.tap SUB { $c.destroy }
    $.add-child($c);
  }

  method updateDialogPosition ($rd, $cd) {
    my $dr = ( .x, .y ) given $rd.meta-window.get-frame-rect;
    my $r  = ( .x, .y ) given $!metaWindow.get-frame-rect;

    $cd.set-position( |($dr »-« $r) );
  }

  method onPositionChanged {
    self.set-position( .x, .y ) given $!realWindow;
  }

  method onDestroy {
    $!delegate = Nil;
    if $!inDrag {
      $.emit('drag-end');
      $!inDrag = False;
    }
  }

  method onDragBegin ($d, $t) {
    $!inDrag = True;
    $.emit('drag-begin');
  }

  method onDragEnd ($d, $t, $s) {
    $!inDrag = False;

    with $.get-parent {
      $!stackAbove
        ?? .set-child-above-sibling(self, $!stackAbove)
        !! .set-child-below-sibling(self);
    }
    $.emit('drag-end');
  }

}

our enum WorkspaceThumbnailStateEnum is export = (
  WORKSPACE_THUMBNAIL_STATE_NEW           => 0,
  WORKSPACE_THUMBNAIL_STATE_EXPANDING     => 1,
  WORKSPACE_THUMBNAIL_STATE_EXPANDED      => 2,
  WORKSPACE_THUMBNAIL_STATE_ANIMATING_IN  => 3,
  WORKSPACE_THUMBNAIL_STATE_NORMAL        => 4,
  WORKSPACE_THUMBNAIL_STATE_REMOVING      => 5,
  WORKSPACE_THUMBNAIL_STATE_ANIMATING_OUT => 6,
  WORKSPACE_THUMBNAIL_STATE_ANIMATED_OUT  => 7,
  WORKSPACE_THUMBNAIL_STATE_COLLAPSING    => 8,
  WORKSPACE_THUMBNAIL_STATE_DESTROYED     => 9,
);

class Gnome::Shell:::Workspace::Thumnail is Gnome::Shell::St::Widget {
  has $!gnome-shell-thumbnail is implementor;

  has gdouble $!collapse-fraction is ranged(0..1) is default(0) is g-property(RW);
  has gdouble $!slide-position    is ranged(0..1) is default(0) is g-property(RW);

  method slide-position
    is also<
      slide_position
      slidePosition
    >
  {
    Proxy.new:
      FETCH => -> $ { $!slide-position },

      STORE => sub ($, Num() $v) {
        return if $!slide-positon == $v;

        my $s = lerp(1, 0.75, $v);
        self.set-scale($s, $s);
        self.opacity = lerp(255, 0, $v);

        $!slide-position = $v;
        $.notify('slide-position');
        $.queue-relayout;
      }
  }

  method collapse-fraction
    is also<
      collapse_fraction
      collapseFraction
    >
  {
    Proxy.new:
      FETCH => -> $ { $!collapse-fraction },

      STORE => sub ($, Num() $v) {
        return if $!collapse-fraction == $v;
        $!collapse-fraction = $v;
        $.notify('collapse-fraction');
        $.queue-relayout;
      }
  }

  has $!delegate   = self;
  has $!viewport   = Mutter::Clutter::Actor.ne   = selfw;
  has $!contents   = Mutter::Clutter::Actor.new;
  has $!removed    = False;
  has $!windows    = [];
  has $!allWindows = [];
  has $!state      = WORKSPACE_THUMNAIL_STATE_NORMAL;

  submethod BUILD ( :$!metaWorkspace, :$!monitorIndex ) {
    $!viewport.add-child($!contents);
    self.add-child($!contents);
    self.Destroy.tap: SUB { self.onDestroy }

    my $wa = Main.layoutManager.getWorkAreaForMonitor($!monitorIndex);
    self.setPortHole( |( .x, .y, .w, .h ) ) given $wa;

    my $windows = Global.get-window-actors.grep( -> $a {
      $actor.meta-window.located-on-workspace($!metaWorkspace);
    }

    for $windows[] {
      .meta-window.notify('minimized').tap: sub (*@a) {
        self.updateMinimized( |@a );
      }
      $!allWindows.push: .meta-window;

      self.addWindowClone($_)
        if self.isMyWindow($_) && self.isOverviewWindow($_);
    }

    $!metaWorkspace.Window-Added.tap: sub ( *@a ) {
      self.windowAdded( |@a )
    }
    $!metaWorkspace.Window-Removed.tap: sub ( *@a ) {
      self.windowRemoved( |@a )
    }

    Global.display.Window-Entered-Monitor.tap: sub ( *@a ) {
      self.windowEnteredMonitor( |@a )
    }
    Global.display.Window-Left-Monitor.tap: sub ( *@a ) {
      self.windowLeftMonitor( |@a )
    }
  }

  method setPorthole ($x, $y, $w, $h) {
    $!viewport.set-size($w, $h);
    $!contents.set-position($x, $y);
  }

  method lookupIndex ($mw) {
    $!windows.find({ .equals($mw) }, :k);
  }

  method syncStacking (@i) {
    $!windows .= sort: -> $a, $b {
      @i[$a.metaWindow.get-stable-sequence] -
      @i[$b.metaWindow.get-stable-sequence]
    }

    .tail.setStackAbove( .head ) for $!windows.rotor(2 => -1);
  }

  method doRemovewindow ($mw) {
    if $.removeWindowClone($mw) -> $c {
      $c.destroy;
    }
  }

  method doAddWindow ($mw) {
    return if $!removed;

    my $win = $mw.get-compositor-private;

    unless $win {
      my $id = GLib::Timeout.idle-add(
        name => "[gnome-shell] { self.^name }.{ &?ROUTINE.name }",
        SUB {
          $.doAddWindow($mw) if [&&](
            $.removed.not,
            $mw.get-compositor-private,
            $mw.get-workspace.equals($mw)
          );
          G_SOURCE_REMOVE;
        }
      );
      return;
    }

    unless $!allWindows.includes($mw) {
      $mw.notify('minimized').tap: sub (*@a) { self.updateMinimized( |@a ) }
      $!allWindows.push: $mw;
    }

    return unless $.lookupIndex($mw).defined;
    return unless $.isMyWindow($win);

    if $.isOverViewWindow($win) {
      $.addWindowClone($win);
    } else {
      my $p = $mw.get-transient-for;
      $p .= get-transient-for while $p.is-attached-dialog;

      with $.lookupIndex($p) {
        $!windows[$_].addAttachedDialog($mw);
      }
    }
  }

  method windowAdded ($work, $win) {
    $.doAddWindow($Win);
  }

  method windowRemoved ($work, $win) {
    with $!allWindows.&firstObject($metawin, :k) {
      $win.disconnectObject(self);
      $!allWidnows.splice($_, 1);
    }

    $.doRemoveWindow($win);
  }

  method windowEnteredMonitor ($d, $i, $w) {
    $.doAddWindow($w) if $i == $!monitorIndex;
  }

  method windowLeftMonitor ($d, $i, $w) {
    $.doRemoveWindow($w) if $i == $!monitorIndex;
  }

  method updateMinimized ($w) {
    $w.minimized ?? $.doRemoveWindow($w) !! $.doAddWindow($w);
  }

  method workspaceRemoved {
    return if $!removed;
    $!removed = True;
    .disconnectObject(self)
      for $!metaWorkspace, Global.display, $!allWindows[];
  }

  method onDestroy {
    $.workspaceRemoved;
    $!windows = [];
  }

  method isMyWindow ($a) {
    .located-on-workspace($!metaworkspace) && .monitor == $!monitorIndex
      given $a.meta-window;
  }

  method isOverviewWindow ($w) {
    .skip-taskbar.not && .showing-on-its-workspace given $w.get-meta-window;
  }

  method addWindowClone ($w) {
    my $wc = Gnome::Shell::UI::WorkspaceThumbnail::WindowClone.new($w);

    $wc.Selected.tap: -> $o, $t { self.activate($t) }

    $wc.Drag-Begin.tap: SUB {
      Main.overview.beginWindowDrag( $wc.metaWindow );
    }

    $wc.Drag-Cancelled.tap: SUB {
      Main.overview.cancelledWindowDrag( $wc.metaWindow );
    }

    $wc.Drag-End.tap: SUB {
      Main.overview.endWindowDrag($wc.metaWindow);
    });

    $wc.destroy.tap: SUB {
      self.removeWindowClone($wc.metaWindow);
    });

    $!contents.add-child(clone);

    $wc.setStackAbove( $!windows.tail ) if +$!windows;
    $!windows.push($wc);
    $wc
  }

  method removeWindowClone ($mw) {
    return $!windows.splice($_, 1).pop with $.lookupIndex($mw);
    Nil;
  }

  method activate ($t) {
    return if $!state.Int > WORKSPACE_THUMBNAIL_STATE_NEW.Int;

    $!metaWorkspace.active
      ?? Main.overview.hide
      !! $!metaWorkspace.activate($t)
  }

  method handleDragOverInternal ($s, $a, $t) {
    if $s.equals(Main.xdndHandler) {
      $!metaWorkspace.activate($t);
      return DRAG_MOTION_RESULT_CONTINUE;
    }

    return DRAG_MOTION_RESULT_CONTINUE
      if $!state.Int > WORKSPACE_THUMBNAIL_STATE_NORMAL.Int;

    my $smw = $s.metaWindow;
    return DRAG_MOTION_RESULT_MOVE_DROP
      if $smw && $.isMyWindow($smw.get-compositor-private);

    return DRAG_MOTION_RESULT_COPY_DROP
      if $s.app && $s.app.can-open-new-window;

    return DRAG_MOTION_RESULT_COPY_DROP
      if $s.app.not && $s.shellWorkspaceLaynch;

    DRAG_MOTION_RESULT_CONTINUE;
  }

  method acceptDropInternal ($s, $a, $t) {
    return False if $!state.Int > WORKSPACE_THUMBNAIL_STATE_NORMAL.Int;

    if $s.metaWindow {
      my $w = $s.metaWindow.get-compositor-private;
      return False if $.isMyWindow($w);
      Main.moveWindowToMonitorAndWorkspace(
        $w.meta-window,
        $!monitorIndex,
        $!metaWorkspace.index
      );
      return True;
    } elsif $s.app?.can-open-new-window {
      if $s.^can('animateLaunchAtPos') {
        $s.animateLaunchAtPos($a.x, $a.y);
      }
      $s.app.open-new-window($!metaWorkspace.index);
      return True
    } elsif $s.app.not && $s.^can('shellWorkspaceLaunch') {
      $s.shellWorkspaceLaunch(
        workspace => $!metaWorkspace.index;
        timestamp => $t
      );
      return True;
    }
    False;
  }

  method setScale ($x, $y) {
    $!viewport.set-scale($x, $y);
  }
}

class Gnome::Shell::UI::Workspace::Thumbnail::Box
  is   Gnome::Shell::St::Widget
  does GLib::Object::RegisterClass
{
  has gdouble   $!expand-fraction is ranged(0..1) is default(0)     is g-property(RW);
  has gdouble   $!scale           is ranged(0..∞) is default(0)     is g-property(RW):
  has gbooolean $!should-show                     is default(False) is g-property(RW);

  has $!delegate;
  has $!indicator;
  has $!monitorIndex;
  has $!scrollAdjustment;
  has $!animatingIndicator;
  has $!dragCancelled;
  has $!dragMonitor;
  has $!dropPlaceholderPos;
  has $!dropWorkspace;

  has $!spliceIndex        = -1;
  has $!maxThumbnailScale  = MAX_THUMBNAIL_SCALE;
  has $!targetScale        = 0;
  has $!scale              = 0;
  has $!expandFraction     = 1;
  has $!updateStateId      = 0;
  has $!pendingScaleUpdate = False;
  has $!animatingIndicator = False;
  has $!shouldShow         = True;
  has $!stateCounts        = {};
  has $!thumbnails         = [];

  has $!dropPlaceholder = Gnome::Shell::St.Bin.new(
    style_class => 'placeholder'
  );

  has $!settings = GIO::Settings.new( schema_id => MUTTER_SCHEMA );

  method scale is rw {
    Proxy.new:
      FETCH => -> $ { $!scale },

      STORE => -> sub ($, \v) {
        return if ($!scale == v)

        $!scale = v;
        $.notify('scale');
        $.queue-relayout;
      }
  }


  submethod BUILD ( :$!monitorIndex, $!scrollAdjustment ) {
    $!delegate = self;

    self.setAttributes(
      style-class => 'workspace-thumbnails',
      reactive    => True,
      x-align     => CLUTTER_ACTOR_ALIGN_CENTER,
      pivot-point => Graphene::Point.new(0.5, 0.5)
    );

    $!indicator = Gnome::Shell::St::Bin.new(
      style-class => 'workspace-thumbnail'
    );
    Gnome::Shell::Utils.set-hidden-from-pick($!indicator, True);
    self.add-child($!indicator);

    self.resetStateCounts( :init );

    my $ca = Mutter::Clutter::ClickAction.new;
    $ca.Clicked.tap: SUB {
      self.activateThumnailAtPoint(
        |$ca.get-coords,
        Clutter::Event.get-current-event-time
      );
    }

    Main.overview.connectObject(
      showing               => SUB { self.createThumbnails },
      hidden                => SUB { self.createThumbnails },
      item-drag-begin       => SUB { self.onDragBegin      },
      item-drag-end         => SUB { self.onDragEnd        },
      item-drag-cancelled   => SUB { self.onDragCancelled  },
      window-drag-begin     => SUB { self.onDragBegin      },
      window-drag-end       => SUB { self.onDragEnd        },
      window-drag-cancelled => SUB { self.onDragCancelled  }
    );

    $!settings.changed('dynamic-workspaces').tap: SUB {
      self.updateShouldShow
    }
    self.updateShouldShow;

    Main.layoutManager.Monitors-Changed.tap: SUB {
      self.destroyThumbnails;
      self.createThumbnails if Main.overview.visible
    }

    Global.display.worareas-changed.tap: SUB { self.updatePorthole }
    self.updatePorthole;

    self.notify('visible').tap: SUB { self.queueUptateStates if self.visible}

    self.Destroy.tap: SUB { self.onDestroy }

    $!scrollAdjustment.notify('value').tap: SUB { self.updateIndicator }
  }

  method resetStateCounts ( :init = False ) {
    for WorkspaceThumbnailStateEnum.enums.pairs {
      $!statecounts{ .key }    = 0;
      $!statecounts{ .value } := $!statecounts{ .key } if $init
    }
  }

  method maxThumbnailScale      { $!maxThumnailScale  }
  method setMonitorIndex   ($i) { $!monitorIndex = $i }

  method onDestroy {
    $.destroyThumbnails;
    $!unqueueUpdateStates;
    $!settings?.run-dispose;
    $!settings = Nil;
  }

  method updateShouldShow {
    my $nw = Global.workspace-manager.nWorkspaces;
    my $ss = $!settings.get-boolean('dynamic-workspaces')
      ?? $nw > NUM_WORKSPACES_THRESHOLD
      !! $nw > 1;

    return if $!shouldShow == $ss;

    $!shouldShow = $ss;
    $.notify('should-show');
  }

  method updateIndicator {
    my $v  = $!scrollAdjustment.value;
    my $wm = Global.workspaceManager;
    my $ai = $wm.get-acive-workspace-index;

    $.queueUpdateStates unless ($!animatingIndicator = $v != $ai);
    $.queue-relayout;
  }

  method activateThumnailAtPoint ($sx, $sy, $t) {
    my ($r, $x) = $.transform-stage-point($sx, $sy);
    my  $th     = $!thumbnails.first({ .x <= $x <= .x + .width });

    .activate($t) with $th;
  }

  method onDragBegin {
    $!dragCancelled = False;
    $!dragMonitor   = (
      dragMotion => sub ( |c ) { self.onDragMotion( |c ) }
    );
    Gnome::Shell::UI::Dnd.addDragMonitor($dragMonitor)
  }

  method onDragEnd {
    return if $!dragCancelled;
    $.endDrag();
  }

  method onDragCancelled {
    $!dragCancelled = True;
    $.endDrag;
  }

  method endDrag {
    $.clearDragPlaceholder;
    Gnome::Shell::UI::Dnd.removeDragMonitor($!dragMonitor);
  }

  method onDragMotion ($e) {
    $.onLeave unless $.contains($e.targetActor);
    return DND_DRAG_MOTION_CONTINUE;
  }

  method onLeave {
    $.clearDragPlaceholder;
  }

  method clearDragPlaceholder {
    return without $!dropPlaceHolderPos;
    $!dropPlaceholderPos = Nil;
    $.queue-relayout
  }

  method getPlaceholderTarget ($i, $s, $rtl) {
    my ($x1, $x2);

    my $w = $!thumbnails[$i];
    if $rtl {
      my $bx = $w.x + $w.w;
      ($x1, $x2) = $bx «+« (0, $s)   »+« (-1, 1) »*» WORKSPACE_CUT_SIZE;
    } else {
      ($x1, $x2) = $w.x «+« (-$s, 0) »+« (-1, 1) »*» WORKSPACE_CUT_SIZE;
    }

    if $i.not {
      $rtl
        ?? $x2 -= $s + WORKSPACE_CUT_SIZE;
        !! $x1 += $s + WORKSPACE_CUT_SIZE;
    }

    if $i == $!dropPlaceHolderPos {
      my $pw = $!placeHolder.width + $s;
      $rtl  ?? $x2 += $ph !! $x1 -= $ph
    }

    [$x1, $x2];
  }

  method withinWorkspace ($x, $i, $rtl) {
    my ($l,   $w) = ( .elems, .[$i] ) given $!thumbnails;
    my ($x1, $x2) = ( .x, .x + .w) »+« (1, -1) »*» WORKSPACE_CUT_SIZE given $w;

    if $i == $l.pred {
      $rtl ?? ($x1 -= $_ ) !! ($x2 += $_) given WORKSPACE_CUT_SIZE;
    }

    $x1 < $x <= $x2;
  }

  method sourceLaunchApp {
    [&&](
      $s.metaWindow.not,
      $s.app?.can-open-new-window.not,
      $s.app || $s.shellWorkspaceLaunch.not,
    );
  }

  method handleDragOver ($s, $a, $x, $y, $t) {
    my $sndnd = $s.equals(Main.dndHandler).not;
    return DRAG_MOTION_RESULT_CONTINUE if $sndld && $.sourceLaunchApp;

    my $rtl = Clutter::Main.is-rtl;
    my $ccw = Meta::Prefs.get-dynamic-workspaces;
    my $sp  = self.get-theme-node.get-length('spacing');

    my ($php, $l);
    ($!dropWorkspace, $php, $l) = (Nil, Nil, $!thumnails.elems);

    for ^$l {
      my $i = $rtl ?? ($l - $_).pred !! $_;

      if $ccw && $sndnd {
        my ($s, $e) = $.getPlaceholderTarget($i, $s, $rtl);

        if ($s < $x <= $e {
          $php = $i;
          last;
        }
      }

      if $.withinWorkspace($x, $i, $rtl) {
        $!dropWorkspace= = $i;
        last;
      }
    }

    if $!dropPlaceholderPos !== $php {
      $!dropPlaceHolderPos = $php;
      $.queue-relayout;
    }

    do if $!dropWorkspace.defined.not {
      $!thumbnails[$!dropWorkspace].handleDragOverInternal($s, $a, $t)
    } elsif $!dropPlaceHolder.defined {
      $s.metaWindow
        ?? DRAG_MOTION_RESULT_MOVE_DROP
        !! DRAG_MOTION_RESULT_CONTINUE
    } else {
      DRAG_MOTION_RESULT_CONTINUE
    }
  }

  method acceptDrop ($s, $a, $x, $y, $t) {
    do if $!dropWorkspace.defined.not {
      Nil
    } elsif $!dropPlaceholderPos.defined.not {
      return False if $.sourceLaunchApp;

      my ($iw, $nwi) = ($source.metaWindow.so);

      ($nwi, $!dropPlaceHolderPos) = ($!dropPlaceHolderPos, Nil);
      $!spliceIndex = $nwi;
      Main.wm.insertWorkspace($nwi);

      if $iw {
        my $tm = $!thumnails[$nwi].monitorIndex;
        Main.moveWindowToMonitorAndWorkspace($s.metaWindow, $tm, $nwi, True);
      } elsif $s.app?.can-open-new-window() {
        $s.animateLaunchAtPos($a.x, $a.y) if $s.^can('animateLaunchAtPos');
        $s.app.open-new-window($nwi);
      } elsif $s.app.not && source.^can('shellWorkspaceLaunch') {
        $s.shellWorkspaceLaunch( workspace => $nwi, timestamp => $t );
      }

      if $s.app || ( $s.app.not && $s.^can('shellWorkspaceLaunch') ) {
        Main.wm.keepWorkspaceAlive(
          Glonal.workspace-manager.get-workspace-by-index($nwi),
          WORKSPACE_KEEP_ALIVE_TIME
        )
      }

      my $tn = $!thumbnails[$nwi];
      $.setThumbnailState($tn, WORKSPACE_THUMBNAIL_STATE_NEW);
      ( .slide-position, .collapse-fraction ) = 1 xx 2;

      $.queueUpdateStates;
      True;
    } else {
      False
    }
  }

  constant TH = Gnome::Shell::Misc::SignalTracker::TransientHolder;
  method createThumbnails {
    return unless +$!thumbnails;

    my $wm = Global.workspaceManager;
    $!transientSignalHolder = TH.new(self);
    $wm.connectObject(
      'notify::n-workspaces'   => sub (|c) { self.workspacesChanged(|c) },
      active-workspace-changed => SUB      { self.updateIndicator       },
      workspaces-reordered     => SUB {
        $!thumnails .= sort( *.metaWorkspace.index )
        self.queue-relayout
      }
    );

    Main.overview.Windows-Restacked.tap: sub (|c) { self.syncStacking(|c) }

    ($!targetScale, $!scale, $!pendingScaleUpdate) = (0, 0, False);
    $.unqueueUpdateStates;
    $.resetStateCounts;
    $.addThumnails(0, $wm.n-workspaces);
    $.updateShouldShow;
  }

  method destroyThumnails {
    return unless +$!thumbnails;

    $!transientSignalHolder.destroy;
    $!transientSignalHolder = Nil;

    .destroy for $!thumbnails;
    $!thumbnails = [];
  }
