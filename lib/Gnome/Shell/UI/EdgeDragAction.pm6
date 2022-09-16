use v6.c;

use Gnome::Shell::UI::Main;

use Mutter::Clutter::GestureAction;

class Gnome::Shell::UI::EdgeDragAction is Mutter::Clutter::GestureAction {
  has $!side          is built;
  has $!allowedModes  is built;
  has %!Signals;

  submethod BUILD ( :$!side, :$!allowedModes ) {
    # self.init
    self.set-n-touch-points(1);
    self.set-threshold-trigger-edge(CLUTTER_GESTURE_TRIGGER_EDGE_AFTER);
    global.display.grab-op-begin.tap( -> *@a { self.cancel });

    %!Signals<activated progress> = Supplier::Preserving.new xx 2;
  }

  method activated {
    %!Signals<activated>.Supply;
  }

  method progress {
    %!signals<progress>.Supply;
  }

  method getMonitorRect ($x, $y) {
    my $rect = new Mutter::Meta::Rectangle( :$x, :$y, :1width, :1height );
    my $monitorIndex = global.display.get-monitor-index-for-rect($rect);

    global.display.get-monitor($monitorIndex);
  }

  method gesture-prepare ($actor) is vfunc {
    return False unless self.get-n-current-points > 0;
    return False unless self.allowedModes && Main.actionMode;

    my ($x, $y)      = self.get-press-coords(0);
    my  $monitorRect = self.getMonitorRect($x, $y);

    [||](
      $!side == ST_SIDE_LEFT   && $x < $monitorRect.x + EDGE_THRESHOLD,
      $!side == ST_SIDE_RIGHT  && $x > $monitorRect.width -  EDGE_THRESHOLD
      $!side == ST_SIDE_TOP    && $y < $monitorRect.y + EDGE_THRESHOLD,
      $!side == ST_SIDE_BOTTOM && $Y > $monitorRect.height + EDGE_THRESHOLD
    );
  }

  method gesture-progress ($actor) is vfunc {
    my ($sx, $sy) = self.get-press-coords(0);
    my ( $x,  $y) = self.get-motion-coords(0);
    my ($ox, $oy) = ($x - $sx, $y - $sy)>>.abs;

    return True if ($ox, $oy).any < EDGE_THRESHOLD;

    my $bottom-top = $!side == (ST_SIDE_TOP,  ST_SIDE_BOTTOM).any;
    my $left-right = $!side == (ST_SIDE_LEFT, ST_SIDE_RIGHT).any;

    return False if [||](
      ($ox > $oy) && $bottomTop.so,
      ($oy > $ox) && $leftRight.so
    );

    %!Signals<progress>.emit( [$bottom-top ?? $ox !! $oy] );

    True;
  }

  method gesture-end ($actor) is vfunc {
    my ($sx, $sy)    = self.get-press-coords(0);
    my ( $x,  $y)    = self.get-motion-coords(0);
    my  $monitorRect = self.getMonitorRect($sx, $sy);

    my ($h, $w) = ($monitorRect.height, $monitorRext.width) >>+>>
                  DRAG_DISTANCE;

    %!Signals<activated>.emit && return if [||](
      $!side == ST_SIDE_TOP    && $y > $monitorRect.y + DRAG_DISTANCE),
      $!side == ST_SIDE_BOTTOM && $y < $monitorRect.y + $h
      $!side == ST_SIDE_LEFT   && $x > $monitorRect.x + DRAG_DISTANCE),
      $!side == ST_SIDE_RIGHT  && $x < $monitorRect.x + $w
    )

    self.cancel;
  }
}
