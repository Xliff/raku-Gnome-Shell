use v6;

### /home/cbwood/Projects/gnome-shell/js/ui/workspace.js

use Graphene::Rect;
use Gnome::Shell::Util;
use Gnome::Shell::Misc::Params;
use Gnome::Shell::UI::Background;
use Gnome::Shell::UI::DND;
use Gnome::Shell::UI::Main;
use Gnome::Shell::UI::OverviewControls;
use Gnome::Shell::UI::WindowPreview;

use GLib::Roles::HashObject;

constant WINDOW_PREVIEW_MAXIMUM_SCALE    = 0.95;
constant WINDOW_REPOSITIONING_DELAY      = 750;
constant LAYOUT_SCALE_WEIGHT             = 1;
constant LAYOUT_SPACE_WEIGHT             = 0.1;
constant BACKGROUND_CORNER_RADIUS_PIXELS = 30;

class Gnome::Shell::UI::Workspace::Layout::Strategy {
  has $.monitor     is built;
  has $.row-spacing is built is default(0);
  has $.col-spacing is built is default(0);

  submethod TWEAK (
    :$monitor,
    :rowSpacing(:row_spacing(:$row-spacing)),
    :colSpacing(:col_spacing(:$col-spacing))
  ) {
    $!monitor     //= $monitor;
    $!row-spacing //= $row-spacing if $row-spacing;
    $!col-spacing //= $col-spacing if $col-spacing;

    X::Gnome::Shell::MissingParameter.new(
      message => "No monitor param passed to ${ self.^name }.new!":
    ).throw;
  }

  method computeLayout($, $) {
    X::GLib::NYI.new( item => &?ROUTINE.name, class => ::?CLASS ).throw
  }

  method computeScaleAndSpace ($, $) {
    X::GLib::NYI.new( item => &?ROUTINE.name, class => ::?CLASS ).throw
  }

  method computeWindowSlots($, $) {
    X::GLib::NYI.new( item => &?ROUTINE.name, class => ::?CLASS ).throw
  }

}

class Gnome::Shell::UI::Workspace::Layout::Strategy::Unaligned
  is Gnome::Shell::UI::Workspace::Layout::Strategy
{
  method newRow {
    return %{
      x          => 0, y          => 0,
      width      => 0, height     => 0,
      fullWidth  => 0, fullHeight => 0,
      windows    => [],
    } but GLib::Roles::HashObject
  }

  method computeWindowScale ($w) {
    lerp(
      1.5,
      1,
      $w.boundingBox.height / self.monitor.height
    );
  }

  method computeRowSizes ( $l ($rows, $scale) ) {
    for $rows[] {
      .<width>  = .<fullWidth> * $scale +
                  .<windows>.elems.pred * $.col-spacing;
      .<height> = .<fullHeight> * $scale;
    }
  }

  method keepSameRow ($r, $win, $w, $i) {
    return True if $r<fullWidth> + $w <= $i;

    my ($o, $n) = ( $_, $_ + $w ) »/» $i given $r<fullWidth>;

    return True if [<](1 - $n, 1 - $o)».abs;

    False;
  }

  method sortRow ($r) {
    $r.windows .= sort( *.windowCenter.x );
  }

  method computeLayout ($w, $l) {
    X::GLib::InvalidValue.new(
      message => 'No numRows given in layout params!'
    ).throw if ($l<numRows> // 0) === 0;

    my $nr = $l<numRows>;

    my @rows;
    my $tw = 0;

    $tw += .boundingBox.width * self.computeScale($_) for $w[];

    my $i  = $tw / $nr;
    my $sw = $w.sort( *.windowCenter.y );
    my $wi = 0;

    for ^$nr -> $ii {
      my $r = $.newRow;
      @rows.push: $r;

      while $wi < $sw.elems {
        my  $window   = $sw[$wi];
        my  $s        = $s.computeWindowScale($window);
        my ($ww, $hh) = ( .width, .height ) »*» $s given $window.boundingBox;

        $r<fullHeight> = max($r<fullHeight>, $hh);
        if $.keepSameRow($r, $w, $ww, $i) || $i === $nr.pred {
          $r<windows>.push: $window;
          $r<fullWidth> += $ww;
        } else {
          last;
        }

        $wi++;
      }
    }

    my ($gh, $mr) = (0);
    for @rows {
      $.sortRow($_);

      $mr = $_ if $maxRow.not || $r<fullWidth> > $mr<fullWidth>;
      $gh += $r<fullHeight>;
    }

    %(
      num-rows    => $nr,
      rows        => $r,
      max-columns => $mr.windows.elems,
      grid-width  => $mr<fullWidth>,
      grid-height => $gh
    ) but GLib::Roles::HashObject;
  }

  method computeScaleAndSpace ($l, $a) {
    my @spacing = $l<max-columns num-rows>».pred »*«
                  ($.col-spacing, $.row-spacing);
    my @spaced  = ( .width, .height ) »-« @spacing given $a;
    my @scale   =  @spaced »/« $l<grid-width grid-height>;
    my $scale   = ( |@scale, WINDOW_PREVIEW_MAXIMUM_SCALE ).min;
    my @sl      = $l<grid-width grid-height> »*« $scale »+« @spacing;
    my $space   = ( [*] |@sl ) »/« ( [*]( .width, .height ) ) given $a;

    $l<scale> = $scale;

    [ $scale, $space ]
  }

  method computeWindowSlots ($l, $a) {
    $.computeRowSizes($l);

    my ($rows, $scale, $slots) = |l<rows scale>, [];

    my $hws = $rows.map( *.height ).sum;
    my $vs  = $rows.elems.pred * $.row-spacing;
    my $avs = min(1, ($a<height> - $vs) / $hws);

    my ($c, $y) = 0 xx 2;

    for $rows[] {
      my $hs  = .<windows>.elems.pred * $.col-spacing;
      my $wws = .<width> - $hs;
      my $ahs = min(1, ($a<width> - $hs) / $wws);

      if $ahs < $avs {
        .<additionalScale> = $ahs;
        $c += ($avs - $ahs) * .<height>;
      } else {
        .<additionalScale> = $avs;
      }

      .<x> = $a<x> + max(0, $a<w> - $wws * .<additionalScale> + $hs) / 2;
      .<y> = $a<y> + max(0, $a<h> - $hws + $vs) / 2 + $y;
      $y += .<height> + .<additionalScale> + $.row-spacing;
    }

    $c /= 2;

    for $rows[] -> $row {
      my ($ry, $rh) = ( $row<y> + $c, $row<height> + $row<additionalScale> );

      my $x = $row<x>;
      for $row<windows> -> $window {
        my  $s  = $scale * $.computeWindowScale($window);
        my ($cw, $ch) = ( .width, .height ) »*» $s given $window.boundingBox;

        $s = min($s, WINDOW_PREVIEW_MAXIMUM_SCALE();

        my ($clw, $clh) = ( .width, .height ) »*» $s given $window.boundingBox;
        my ($clx, $cly) = ( $x + ($cw - $clw) / 2 );

        $cly = $rows.elems === 1
          ?? $ry + ($rh - $clh) / 2;
          !! $ry  + $rh - $ch;

        ($clw, $cly) .= map( *.Int );

        @slots.push: [$clx, $cly, $clw, $clh, $window];
        $x += $cw = $.col-spacing;
      }
    }

    $slots
  }
}

sub animateAllocation ($_, $b) {
  .save-easing-state;
  .easing-mode = CLUTTER_EASE_OUT_QUAD;
  .allocate($box);
  .restore-easing-state;
  .get-transition('allocation');
}

class Gnome::Shell::UI::Workspace::Layout
  is Mutter::Clutter::LayoutManager
{
  has Num  $.spacing
    is ranged(0..∞)
    is default(20.0)
    is g-attribute(gdouble, RW)  = 20;

  has Bool $!layout-frozen
    is g-attribute(gboolean, RW) = False;

  has $!needsLayout              = True;
  has $!workareasChangedId       = 0;
  has $!windows                  = Hash[Mu, Mu].new;

  has $!metaWorkpace;
  has $!monitorIndex;
  has $!overviewAdjustment;
  has $!container;
  has @!sortedWindows;
  has $!lastBox;
  has @!windowSlots;
  has $!layout;
  has $.stateAdjustment;
  has $!workarea;

  method spacing is rw {
    Proxy.new:
      FETCH => -> $           { $!spacing },

      STORE => -> $, Num() $v {
        return if $!spacing == $v;

        $!spacing = $v
        $!needsLayout = True;
        $.notify('spacing';
        $.layout_changed;
      }
  }

  method layout-frozen is rw {
    Proxy.new:
      FETCH => -> $           { $!layout-frozen },

      STORE => -> $, Int() $v {
        my $vb = $v.so.Int;
        return if $!layout-frozen == $vb;

        $!layout-frozen = $vb;
        $.notify('layout-frozen');
        $.layout_changed unless $!layout-frozen;
      }
  }

  submethod BUILD (
    :$!metaWorkpace
    :$!monitorIndex
    :$!overviewAdjustment
  ) {
    $!stateAdjustment = Gnome::Shell::St::Adjustment.new(
      value => 0,
      lower => 0,
      upper => 1
    );

    $!stateAdjustment.notify('value').tap: SUB {
      self.syncOpacities;
      self.syncOverlays;
      self.layout-changed;
    }
  }

  method syncOpacity ($a, $m) {
    $a.opacity = $!stateAdjustment * 255 if $m.showing-on-its-workspace;
  }

  method syncOpacities {
    $.syncOpacity( .<metaWindow>, .<actor> ) for @!windows;
  }

  method isBetterScaleAndSpace ($oldScale, $oldSpace, $scale, $space) {
    my $spaceP = ($space - $oldSpace) * LAYOUT_SPACE_WEIGHT;
    my $scaleP = ($scale - $oldScale) * LAYOUT_SCALE_WEIGHT;

    do {
      when    $scale > $oldScale && $space    >  $oldSpace { True              }
      when    $scale > $oldScale && $oldSpace >= $space    { $scaleP > $spaceP }
      when    $space > $oldSpace && $oldScale >= $scale    { $spaceP > $scaleP }
      default                                              { False             }
    }
  }

  method adjustSpacingAndPadding ($rowS, $colS = $rowS, $cb = 0) {
    return [$rowS, $colS, $cb] if $!sortedWindows.elems.not;

    my $w = @!sortedWindows.head;

    my ($to, $bo, $lo, $ro) = ( |$w.chromeHeights, |$w.chromeWidths );
    my  $o                  = ($to, $bo, $lo, $ro).max;

    $rowS += $o with $rowS;
    $colS += $o with $colS;

    if $cb {
      my $m   = Main.layoutManager.monitors[$!monitorIndex];
      my $bp  = Graphene::Point3D.new( y => $cb.y2 );
      my $tbp = $!container.apply-transfor-to-point($bp);
      my $bfs = ($m.y + $m.h) - $tbp.y;
      my $bol = $w.overlapHeights.tail;

      $cb.y2 -= ($bol + $o) - $bfs if $bol + $o > $bfs;
    }

    [$rowS, $colS, $cb]
  }

  method createBestLayout ($a) {
    my ($rs, $cs) = $.adjustSpacingAndPadding($!spacing);

    $!layoutStrategy =
      Gnome::Shell::UI::Workspace::Layout::Strategy::Unaligned.new(
        monitor     => Main.layoutManager.monitors[$!monitorIndex],
        row-spacing => $rs,
        col-spacing => $cs
      );

    my ($nr, $lnc, $lScale, $lSpace, $ll) = (1, -1, 0, 0);

    repeat {
      my $nc = (@!sortedWindows / $nr).ceiling;

      last if $nc === $lnc;

      my $layout = $!layoutStrategy.computeLayout(
        @!sortedWindows,
        { numRows => $nr } but GLib::Roles::HashObject
      );

      my ($scale, $space) = $!layoutStrategy.computeScaleAndSpace($layout, $a);

      last if $ll &&
              $.isBetterScaleAndSpace($lScale, $lSpace, $scale, $space).not;

      ($ll, $lnc, $lScale, $lSpace) = ($layout, $nc, $scale, $space);
    }

    $ll;
  }

  method getWindowSlots ($cb is copy) {
    $cb = $.adjustSpacingAndPadding($, $, $cb).tail;

    $.layoutStrategy.computeWindowSlots($!layout, %{
      x      => $cb.x1.Int,
      y      => $cb.y1.Int,
      width  => $cb.w,
      height => $cb.h
    })
  }

  method getAdjustedWorkarea ($c) {
    my $w = $!workarea.clone;

    if $c ~~ Gnome::Shell::St::Widget {
      my $n = $c.theme-node;
      ( $w.width, $w.height ) »-=« ($n.horizontal-padding, $n.vertical-padding)
    }

    $w;
  }

  method syncWorkareaTracking {
    if $!container {
      # -YYY- workAreaChangedId?
      return if $!workareasChangedId;

      $!workarea = Main.layoutManager.getWorkAreaFormMonitor($!monitorIndex);

      $!workareasChangedId = Global.display.Workareas-Changed.tap: SUB {
        $!workArea = Main.layoutManager.getWorkAreaForMonitor($!monitorIndex);
        self.layout-changed;
      }
    } else if $!workareasChangedId {
      $!workareasChangedId.untap( :clear );
    }
  }

  method set-container ($c) is vfunc {
    $!container = $c;
    $.syncWorkareaTracking;
    $.stateAdjustment.actor = $c;
  }

  method get_preferred_width ($c, $fh) is vfunc {
    my $wa = $.getAdjustedWorkarea($c);
    return [0, $wa.width] if $fh === -1;

    [0, $fh * $wa.width / $wa.height];
  }

  method get_preferred_height ($c, $fw) is vfunc {
    my $wa = $.getAdjustedWorkarea($c);
    return [0, $wa.height] if $fw === -1;

    [0, $fw * $wa.width / $wa.height];
  }

  method allocate ($container, $box) is vfunc {
    my  $c        = $container.allocation;
    my ($ch, $cw) = $c.size;

    my $containerAllocationChanged =
      $!lastBox.defined.not      ||
      $!lastBox.equyals($c).not;

    if [&&](
      $!layoutFrozen,
      $containerAllocationChanged,
      Main.overview.animationInProgress.not
    ) {
      $!layoutFrozen = False,
      $.notify('layout-frozen');
    }

    my $cont = OverControls.ControlsState;
    my $curr = $!overviewAdjustment.getStateTransitionParams.currentState;
    my $ist  = $curr <= $cont.WINDOW_PICKER;
    my $w    = @!sortedWindows.head;

    if $ist || $w.not {
      $container.remove-clip;
    } else {
      my  $bo       = $w.chromHeights.tail;
      my ($cx, $cy) = $c.origin;
      my  $ehp      = $curr - $cont.WINDOW_PICKER;
      my  $ech      = $bo * (1 - $ehp);

      $container.set-clip($cx, $cy, $cw, $ch + $ech);
    }

    my $lc = False;
    if $!layoutFrozen.not || $!lastBox.not {
      if $!needsLayout {
        $!layout = $.createBestLayout($!workArea);
        ($!needsLayout, $lc) = (False, True);
      }

      if $lc || $containerAllocationChanged {
        $!windowSlotsBox = $box.clone;
        $!windowSlots    = $.getWindowSlots($!windowSlotsBox);
      }
    }

    my  $ss               = $box.width / $!windowSlotsBox.width;
    my ($wax, $way, $waw) = ( .x, .y, .w ) given $!workarea;
    my  $sav              = $!stateAdjustment.value;
    my  $as               = $cw / $waw;
    my  $cb               = Mutter::Clutter::ActorBox.new;

    for $!windowSlots {
      my ($x, $y, $w, $h, $child) = $_;
      next unless $child.visible;

      ($x, $y, $w, $h) »*=« $ss;

      my $wi = $!windows{ $child };

      my ($wbx, $wby, $wbw, $wbh) = 0 xx 4;
      if $wi.metaWindow.showing-on-its-workspace {
        ($wbx, $wby, $wbw, $wby) = (.x - $wax, .y - $way, .w, .h) »*» $as
          given $child.boundingBox
      } else {
        ($wbx, $wby) = ($wax, $way) »*» $as;
      }

      ($wbw, $wbh) = ( [$wbw, $w], [$wbh, $h] )».max if $ist;

      ($x, $y, $w, $h) =
        ( [$wbx, $x], [$wby, $y], [$wbw, $w], [$wbh, $h] ).map({
          lerp( |$_, $sav )
        });

      $cb.set-origin($x, $y);
      $cb.set-size($w, $h);

      if $wi.currentTransition) {
        $wi.currentTransition.interval.final = $cb;
        $child.allocate($child.allocation);
        next;
      }

      if $lc && Main.overview.animationInProgress.not {
        if animateAllocation($child, $cb) -> $t {
          $wi.currentTranslation = $t;
          $t.Stopped.tap: SUB {
            $wi.currentTransition = Nil;
          }
        }
      } else {
        $child.allocate($cb);
      }
    }

    $!lastBox = $cb.copy;
  }

  method syncOverlay ($p) {
    $p.overlayEnabled = [&&](
      $!metaWorkspace ?? $!metaWorkspace.?active !! True,
      $!stateAdjustment.value
    );
  }

  method syncOverlays {
    $.syncOverlay($_) for $!windows.keys[];
  }

  method addWindow ($w, $mw) {
    return if $!windows{$w}:exists;

    $!windows{$w} = %{
      metaWindow    => $mw,
      sizeChangedId => $mw.Size-Changed.tap: SUB {
        $!needsLayout = True,
        self.layout_changed;
      },
      destroyId     => $w.destroy.tap: SUB {
        self.removeWindow($w);
      },
      currentTransition => Nil
    } but GLib::Roles::HashObject;

    @!sortedWindows.push: $w;
    @!sortedWindows.sort(-> $a, $b { [-](
      $!windows{$a}<metaWindow>.get-stable-sequence,
      $!windows{$b}<metaWindow>.get-stable-sequence
    )});
    $.syncOpacity($w, $mw);
    $.syncOverlay($w);
    $!container.add-child($w);
    $!needsLayout = True;
    $.layout_changed;
  }

  method removeWindow ($w) {
    return unless ( my $wi = $!windows{$w} );

    .untap for $wi<sizeChangedId destroyId>;
    $w.remove-transition('allocation') if $wi<currentTransition>;
    $!windows{$w}:delete;
    @!sortedWindows.&removeObject($w);
    @!windowSlots.&removeObject( $w, -> $_ { .[4] } );

    $!container.remove-child($w) if $w.parent.is($!container);
    $!needsLayout = True;
    $.layout_changed;
  }

  method syncStacking ($si) {
    my $lastWindow;
    for $!windows.keys.sort(
      -> $a, $b { [-](
        $si[ $!windows{$a}<metaWindow>.get-stable-sequence ],
        $si[ $!windows{$b}<metaWindow>.get-stable-sequence ],
      )}
    ) {
      $w.setStackAbove($lastWindow);
      $lastWindow = $_;;
    }
    $!needsLayout = True;
    $.layout_changed;
  }

  method getFocusChain {
    return [] unless $!stateAdjustment.value;

    @!windowSlots.map( *[4] );
  }
}

# cw: And here's the thing that's going to bite me in the ass.

#     As of this writing, there is no C-backing to 'self'.
#     So this is another issue that has to be handled in
#     subclassing, quite possibly in the GObject level. If
#     done properly, the mechanism for this will also handle
#     any other subclasses so we don't have to reopen this can
#     of worms. The alternative is kicking the can down the road
#     so that someone else can handle it.
#
#     I'm thinking that this will need macros.
#
#     Lots and lots of macros.
#
#     And an array.....
#
#     And cheese....
#     Definitely cheese.
class Gnome::Shell::UI::Workspace::Background
  is Gnome::Shell::WorkspaceBackground
{
  has $!workarea        is built;
  has $!stateAdjustment is built;

  has $!bin;
  has $!backgroundGroup;
  has $!bgManager;

  submethod BUILD ( :$monitorIndex, :$!stateAdjustment ) {
    self.setAttribute(
      monitor-index => $monitorIndex
    ) if $monitorIndex;
    $!stateAdjustment.notify('value').tap: SUB {
      self.updateBorderRadius;
      self.queue-relayout
    );
    $!stateAdjustment.bind('value', self, 'state-adjustment-value');

    $!bin = Mutter::Clutter::Actor.new(
      layout-manager     => Mutter::Clutter::BinLayout.new,
      clip-to-allocation => True
    );

    $!backgroundGroup = Mutter::Meta::BackgroundGroup.new(
      layout-manager => Mutter::Clutter::BinLayout.new,
      expand         => True
    );
    $!bin.add-child($!backgroundGroup);
    self.add-child($!bin);

    $!bgManager = Gnome::Shell::UI::Workspace::BackgroundManager.new(
      container       => $!backgroundGroup,
      monitorIndex    => self.monitor-index,
      controlPosition => False,
      useContentSize  => False
    );

    $!bgManager.Changed.tap: SUB {
      self.updcateRoundedClipBounds,
      self.updateBorderRadius
    }

    Global.display.Workareas-Changed.tap: SUB {
      $!workarea = Main.layout.getWorkAreaForMonitor(self.monitor-index),
      self.updateRoundedClipBounds;
      self.queue-relayout
    );
    self.updateRoundedClipBounds;
    self.updateBorderRadius;
    self.destroy.tap: SUB { self.onDestroy }
  }

  method updateBorderRadius {
    my $sf = Gnome::Shell::St::ThemeContext.get-for-stage(Global.state);
    my $cr = $sf * BACKGROUND_CORNER_RADIUS_PIXELS;
    my $bc = $!bgManager.backgroundActor.content;

    # cw: WTF is a 'lerp'?
    $bc.rounded-clip-radius = lerp(0, $cr, $!stateAdjustment.value);
  }

  method updateRoundedClipBounds {
    my $m = Main.layoutManager.monitors[$!monitorIndex];

    my $r = Graphene::Rect.new;
    $r.origin = ($!workarea.x, $!workarea.y) »-« ($monitor.x, $monitor.y);
    $r.size   = ($!workarea.w, $!workarea.h);

    $!bgManager.backgroundActor.content.rounded-clip-bounds = $r;
  }

  method onDestroy {
    return unless $!bgManager;

    $!bgManager.destroy;
    $bgManager = Nil;
  }
}

class Gnome::Shell::UI::Workspace is Gnome::Shell::St::Widget {
  has $!metaWorkspace;
  has $!monitorIndex;
  has $!overviewAdjustment;
  has $!background;
  has $!container;
  has $!overviewAdjustment;
  has $!monitor;
  has %!skipTaskbarSignals;
  has $!delegate

  has $!windows        = [];
  has $!layoutFrozenId = 0;

  submethod BUILD (
    :$!metaWorkspace,
    :$!monitorIndex,
    :$!overviewAdjustment
  ) {
    self.setAttributes(
      style-class    => 'window-picker',
      pivot-point    => Graphene::Point(0.5, 0.5),
      layout-manager => Mutter::Clutter::BinLayout.new
    );

    my $layoutManager = Gnome::Shell::UI::Workspace::Layout.new(
      :$metaWorkspace,
      :$monitorIndex,
      :$overviewAdjustment
    );

    my $background = Gnome::Shell::Workspace::Background.new*
      :$monitorIndex,

      stateAdjustment => $layoutManager.stateAdjustment
    );
    self.add-child($!background);
    $!monitor = Main.layoutManager.monitors[$!monitorIndex];

    self.add-style-class-name('external-monitor')
      if $monitorIndex != Main.layoutManager.primaryIndex;

    my $clickAction = Mutter::Clutter::ClickAction.new;
    $clickAction.Clicked.tap: sub ($a) {
      if $a.button == (0, 1).any {
        self.metaWorkspace?.activate(Global.get-current-time);
        Main.overviewe.hide if self.shouldLeaveOverview;
      }
    }

    self.bind('mapped' $clickAction, 'enabled');
    $!container.add-action($clickAction);

      $!delegate = self;
      $!metaWorkspace?.connectObject(
        'window-entered-monitor', sub (*@a) {
          self.windowEnteredMonitor( |@a )
        },
        'window-left-monitor', sub (*@a) { self.windowLeftMonitor( |@a ) },
        'window-added',        sub (*@a) { self.windowAdded(       |@a ) },
        'window-removed',      sub (*@a) { self.windowRemoved(     |@a ) },

        'notify::active', sub (*@a) { $layoutManager.syncOverlays }
      );

    .doAddWindow( .meta_window ) for Global.get-window-actors;
  }

  method shouldLeaveOverview {
    return True if $!metaWorkspace.not !! $!metaWorkspace.active;

    $!overviewAdustment.value > CONTROLS_STATE_WINDOW_PICKER
  }

  method get-focus-chain is vfunc {
    $!container.layout-manager.get-focus-chain;
  }

  method lookupIndex ($metaWindow) {
    $!windows.find( .equals($metaWindow), :k );
  }

  method containsMetaWindow ($metaWindow) {
    $.lookupIndex($metaWindow).defined;
  }

  method isEmpty {
    +$!windows.so;
  }

  method syncStacking ($stackIndicies) {
    $!container.layout-manager.syncStacking($stackIndicies);
  }

  method doRemoveWindow ($metaWin) {
    my $clone = $.removeWindowClone($metaWin);
    return unless $clone;

    $clone.destroy;

    $!container.layout-manager.layout-frozen = True;
    $!layoutFrozenId.?clear;

    my ($ox, $oy) = Global.get-pointer;

    !$layoutFrozenId = GLib::Timeout.add(
      name => "[gnome-shell { .^name }.layoutFrozenId"
      WINDOW_REPOSITIONING_ID,
      SUB {
        my ($nx, $ny) = Global.get-pointer;
        my  $hasMoved = $ox == $nx || $oy == $ny;
        my  $aup      = $Global.state.get-actor-at-pos($nx, $ny);

        if $hasMovced && $.contai+INUE;
        }

        $!container.layout-manager.layout-frozen = False;
        $!layoutFrozenId.clear;
        G_SOURCE_REMOVE;
      }
    );
  }

  method doAddWindow ($metaWin) {
    my $win = $metaWin.get-compositor-private;

    unless $win {
      GLib::Timeout.idle-add( SUB {
        doAddWindow($metaWin)
          if $metaWin.get-compositor-private &&
             $metaWin.get-workspace.equals($!workspace);
        G_SOURCE_REMOVE;
      })
    }

    return if     $.containsMetaWindow($metaWin);
    return unless $.isMyWindow($metaWin);

    $!skipTaskbarSignals.set(
      $metaWin,
      SUB {
        $metaWin.skip-taskbar
          ?? self.doRemoveWindow($metaWin)
          !! self.doAddWindow($metaWin);
      }
    );

    unless $.isOverviewWindow($metaWin) {
      return unless $metaWin.get-transient-for;

      my $parent = $metaWin.find-root-ancestor;
      my $clone  = $!windows.first(
        sub ($_) {
          .metaWindow.equals($parent)
        },
        :k
      );

      .addDialog($metaWin) with $clone;
      return;
    }

    ( my $clone = $.addWindowClone($metaWin) ).setAttributes(
      pivot-point => Graphene::Point(0.5, 0.5),
      scale       => 0
    );

    $clone.ease(
      scale     => 1,
      duration  => 250,
      onStopped => SUB { $clone.set-pivot-point(0, 0) }
    );

    if $layoutFrozenId > 0 {
      $!container.layout-manager.layout-frozen = False;
      $!layoutFrozenId.clear
    }
  }

  method windowAdded ($work, $win) {
    $.doAddWindow($win) unless Main.overview.closing;
  }

  method windowRemoved($work, $win) {
    $.doRemoveWindow($win);
  }

  method windowEnteredMonitor ($d, $i, $w) {
    $.doAddWindow($w) if $i == $!monitorIndex && Main.overview.closing.not;
  }

  method windowLeftMonitor ($d, $i, $w) {
    $.doAddWindow($w) if $ii == $!monitorIndex;
  }

  method hasMaximizedWindows {
    for $!windows {
      return True if [&&](
        .showing-on-its-workspace,
        .maximized-horizontally,
        .maximized-vertically
      ) given .metaWindow;
    }
    False;
  }

  method clearSkipTaskbarSignals {
    for $.skipTaskBarSignals -> ($w, $i) {
      $w.disconnect($i);
    }
    $.skipTaskBarSignals.clear;
  }

  method prepareToLeaveOverview {
    $.clearSkipTaskbarSignals;

    .remove-all-transitions for $!windows;

    $!layoutFrozenId.?clear;

    $!container.layout-manager.layout-frozen = True;

    Main.overview.Hidden.tap: sub ( *@a ) {
      self.doneLeavingOverview( |@a );
    }
  }

  method onDestroy {
    $.clearSkipTaskbarSignals;
    $!layoutFrozenId.?clear;
    $!windows = [];
  }

  method doneLeavingOverview {
    $!container.layout-manager.layout-frozen = False
  }

  method doneShowingOverview {
    $!container.layout-manager.layout-frozen = False;
  }

  method isMyWindow ($w) {
    [&&](
      $!metaWorkspace || $w.located-on-workspace($!metaWorkspace),
      $w.get-monitor  == $!monitorIndex;
    );
  }

  method isOverviewWindow ($w) {
    $w.skip-taskbar.not;
  }

  method addWindowClone ($mw) {
    my $clone = Gnome::Shell::UI::WindowPreview.new(
      $mw,
      self,
      self.overviewAdjustment
    );

    $clone.Selected.tap: sub ( *@a ) {
      self.onCloneSelected( |@a )
    };
    $clone.Drag-Begin.tap: SUB {
      Main.overview.beginWindowDrag($mw)
    }
    $clone.Drag-Cancelled.tap: SUB {
      Main.overview.cancelledWindowDrag($mw)
    }
    $clone.Drag-End.tap: SUB {
      Main.overview.endWindowDrag($mw)
    }
    $clone.Show-Chrome.tap: SUB {
      my $f = Global.stage.key-focus;
      $clone.grab-key-focus if $focus.not || self.contains($f);

      .hideOverlay(True) if .equals($clone).not for $!windows;
    }
    $clone.Destroy.tap: SUB {
      self.doRemoveWindow($mw);
    }

    $!container.layout-manager.addWindow($clone, $mw);

    $clone.setStackAbove(
      +$!windows ?? Nil !! $!windows.tail
    );

    $!windows.push: $clone;
    $clone;
  }

  method removeWindowClone ($mw) {
    return Nil without ( my $i = $.lookupIndex($mw) );

    $!container.layout-manager.removeWindow( $!windows[$i] );

    $!windows.splice($i, 1).pop;
  }

  method onStyleChanged {
    $!container.layout-manager.spacing = $.theme-node.get-length('spacing');
  }

  method onCloneSelected ($c, $t) {
    my $wi = $!metaWorkspace?.index;

    $.shouldLeaveOverview
      ?? Main.activateWindow($c.metaWindow, $t, $wi)
      !! $!metaWorkspace?.activate($t);
  }

  method handleDragOver ($s, $a, $x, $y, $t) {
    return DRAG_MOTION_RESULT_MOVE_DROP
      if $s.metaWindow && $.isMyWindow($s.metaWindow);
    return DRAG_MOTION_RESULT_COPY_DROP
      if $s.app?.can-open-new-window;
    return DRAG_MOTION_RESULT_COPY_DROP
      if $s.app.not && $s.shellWorkspaceLaunch;
    DRAG_MOTION_RESULT_CONTINUE;
  }

  method acceptDrop ($s, $a, $x, $y, $t) {
    my $wm = Global.workspace-manager;
    my $wi = $!metaWorkspace
      ?? $!metaWorkspace.index
      !! $wm.get-active-workspace-index;

    if $s.metaWindow -> $w {
      return False if $.isMyWindow($w);

      Main.moveWindowToMonitorAndWorkspace($w, $!montirIndex, $wi);
      return True;
    } elsif $s.app && $s.app.can-open-new-window {
      $s.animateLaunchAtPos($a.x, $a.y) if $s.animateLaunchAtPos;
      $s.app.open-new-window($wi);
      return True;
    } elsif $s.app.not && $s.shellWorkspaceLaunch {
      $s.shellWorkspaceLaunch( workspace => $wi, timestamp => $t );
      return True;
    }
    False
  }

  method stateAdjustment {
    $!container.layout-manager.stateAdjustment;
  }

}
