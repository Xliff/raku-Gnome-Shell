use v6;

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
  .easing-mode = CLUTTER_ANIMATION_EASE_OUT_QUAD;
  .allocate($box);
  .restore-easing-state;
  .get-transition('allocation');
}

class Gnome::Shell::UI::Workspace::Layout
  is Mutter::Clutter::LayoutManager
{
  has Num  $!spacing
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
  has $!stateAdjustment;
  has $!workarea;

  method spacing is rw {
    Proxy.new:
      FETCH => -> $           { $!spacing },
      STORE => -> $, Num() $v { $!spacing = $v }
  }

  method layout-frozen is rw {
    Proxy.new:
      FETCH => -> $           { $!layout-frozen             }
      STORE => -> $, Int() $v { $!layout-frozen = $v.so.Int }
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
  }d
















}
