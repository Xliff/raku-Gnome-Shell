use v6.c;

### /home/cbwood/Projects/gnome-shell/js/ui/swipeTracker.js

constant TOUCHPAD_BASE_HEIGHT             = 300;
constant TOUCHPAD_BASE_WIDTH              = 400;
constant EVENT_HISTORY_THRESHOLD_MS;
       = 150;
constant SCROLL_MULTIPLIER                = 10;
constant MIN_ANIMATION_DURATION           = 100;
constant MAX_ANIMATION_DURATION           = 400;
constant VELOCITY_THRESHOLD_TOUCH         = 0.3;
constant VELOCITY_THRESHOLD_TOUCHPAD      = 0.6;
constant DECELERATION_TOUCH               = 0.998;
constant DECELERATION_TOUCHPAD            = 0.997;
constant VELOCITY_CURVE_THRESHOLD         = 2;
constant DECELERATION_PARABOLA_MULTIPLIER = 0.35;
constant DRAG_THRESHOLD_DISTANCE          = 16;
constant DURATION_MULTIPLIER              = 3;
constant ANIMATION_BASE_VELOCITY          = 0.002;
constant EPSILON                          = 0.005;
constant GESTURE_FINGER_COUNT             = 3;

our enum State         <NONE SCROLLING>;
our enum TouchpadState <NONE PENDING HANDLING IGNORED>;

class Gnome::Shell::UI::SwipeTracker::History {
  has @!data;

  submethod BUILD {
    self.reset;
  }

  method trim ($time) {
    my $tt = $time - EVENT_HISTORY_THRESHOLD_MS;

    @!data.splice( 0, @!data.find({ .<time> > $tt }, :k) );
  }

  method append ($t, $d) {
    @!data.push: %( time => $t, delta => $d );
  }

  method calculateVelocity {
    return 0 if @!data.elems < 2;

    my @et = ( .head, .tail ).map( *<time> ) given @!data;
    return 0 if [==]( |@et );

    @!data.skip(1).map( *<delta> ).sum / [-]( |@et.reverse );
  }
}

class Gnome::Shell::UI::SwipeTracker::TouchpadGesture::Swipe
  does GLib::Roles::Object
  does GLib::Roles::RegisterClass
{
  has gboolean $!enabled
    is g-property(RW);

  has guint    $!orientation
    is g-property(RW, Mutter::Enuns::Clutter::Orientation;

   has $!allowedModes = TOUCHPAD_STATE_NONE;
   has $!state        = 0;
   has $!cumulative   = (0, 0);

   has $!touchpadSettings = GIO::Settings.new(
    'org.gnome.desktop.peripherals.touchpad'
   );

  method Begin  (guint, gdouble, gdouble) is g-signal { };
  method Update (guint, gdouble, gdouble) is g-signal { };
  method End    (guint, gdouble)          is g-signal { };

  submethod TWEAK {
    Global.stage.Captured-Event('touchpad').tap: SUB {
      self.handle-event( |$*A );
    }
  }

  method handleEvent ($a, $e) {
    {
      return return CLUTTER_EVENT_PROPAGATE
        if $e.type !== CLUTTER_EVENT_TOUCHPAD_SWIPE;

      $!state = TOUCHPAD_STATE_NONE
        if $e.gesture-phase == CLUTTER_TOUCHPAD_GESTURE_BEGIN;

      return CLUTTER_EVENT_PROPAGATE
        if $e.touchpad-gesture-finger-count != GESTURE_FINGER_COUNT;

      return CLUTTER_EVENT_PROPAGATE
        unless $!allowedModes +& Main.actionMode

      return CLUTTER_EVENT_PROPAGATE
        unless $!enabled;

      return CLUTTER_EVENT_PROPAGATE
        if $!state == TOUCHPAD_STATE_IGNORED;
    }

    my ($t, $c, \Δ) = ( .time, .coords, .gesture_motion_delta_unaccelerated )
      given $e;

    if $!state == TOUCHPAD_STATE_NONE {
      return CLUTTER_EVENT_PROPAGATE if Δ == (0, 0)

      $!cumulative = (0, 0);
      $!state      = TOUCHPAD_STATE_PENDING;
    }

    if $!state = TOUCHPAD_STATE_PENDING {
      $!cumulative «+=» Δ

      my $cd  = $!cumulative;
      my $d   = ( [+]( |($cd »*« $cd) ) ).sqrt;

      if $d >= DRAG_THRESHOLD_DISTANCE {
        my $go = $cd.head.abs > $cd.tail.abs ?? CLUTTER_ORIENTATION_HORIZONTAL
                                             !! CLUTTER_ORIENTATION_VERTICAL;
        $cd = (0, 0);

         if $go == $.orientation {
           $!state = TOUCHPAD_STATE_HANDLING;
           $.emit('begin', $time, |$c);
         } else {
           $!state = TOUCHPAD_STATE_IGNORED;
           return CLUTTER_EVENT_PROPAGATE;
         }
      } else {
        return CLUTTER_EVENT_PROPAGATE;
      }
    }

    my $v = $.orientation == CLUTTER_ORIENTATION_VERTICAL;
    my \Δ = $v ?? $Δ.tail !! $Δ.head;
    given $e.gesture-phase {
      when CLUTTER_TOUCHPAD_GESTURE_BEGIN |
           CLUTTER_TOUCHPAD_GESTURE_UPDATE
      {
        Δ = -Δ if $!touchpadSettings.get-boolean('natural-scroll');
        $.emit('update', $t, Δ, $d);
      }

      when CLUTTER_TOUCHPAD_END    |
           CLUTTER_TOUCHPAD_CANCEL
      {
        $.emit('end', $t, $d);
        $!state = TOUCHPAD_STATE_NONE;
      }
    }

    return $!state == TOUCHPAD_STATE_HANDLING
      ?? CLUTTER_EVENT_STOP
      !! CLUTTER_EVENT_PROPAGATE;
  }

  method destroy {
    Global.state.disconnectObject(self);
  }
}

class Gnome::Shell::UI::SwipeTracker::Gesture::TouchSwipe
  is   Mutter::Clutter::Action::Gesture
  does GLib::Roles::RegisterClass
{
  has gdouble $!distance
    is g-property(RW) = Global.screen.height;

  has ClutterOrientation $!orientation
    is g-property(RW, Mutter::Clutter::Orientation);

  has $!last-position = 0;

  has $!allowedModes;

  method Begin  (guint, gdouble, gdouble, gdouble) is g-signal { }
  method Update (guint, gdouble, gdouble, gdouble) is g-signal { }
  method End    (guint, gdouble)                   is g-signal { }
  method Cancel (guint, gdouble)                   is g-signal { }

  submethod BUILD ( :$!allowedModes ) { }

  submethod TWEAK ( :$nTouchPoints, :$thresholdTriggerEdge ) {
    self.set-n-touch-points($nTouchPoints);
    self.set-threshold-trigger-edge($thresholdTriggerEdge);
  }

  method distance is rw {
    Proxy.new:
      FETCH => -> $     { $!distance },
      STORE => -> $, \v {
        return unless $!distance == v;
        $!distance = v;
        $.notify('distance');
      }
  }

  method gesture-prepare ($a) is vfunc {
    return False unless nextsame;
    return False unless $!allowedModes +& Main.actionMode;

    my  $t        =   $.get-last-event(0).time;
    my ($pc, $mc) = ( $.press-coords, $.motion-coords );
    my  \Δ        =   $.mc »-« $pc;
    my  $so       =   Δ.head.abs > Δ.tail.abs
      ?? CLUTTER_ORIENTATION_HORIZONTAL
      !! CLUTTER_ORIENTATION_VERTICAL;

    return False unless $so != $.orientation;

    $!lastPosition = $.orientation == CLUTTER_ORIENTATION_VERTICAL
      ?? $mc.tail
      !! $mc.head;

    $.emit('begin', $t, |$pc);
    True;
  }

  method gesture-progress ($a) is vfunc {
    my $mc  = $.motion-coords;
    my $pos = $.orientation == CLUTTER_ORIENTATION_VERTICAL
      ?? $mc.tail
      !! $mc.head;

    my \Δ = $pos - $!last-position;
    my $t = $.last-event.time;

    $!last-position = $pos;
    $.emit('update', $t, -Δ, $!distance);
    True;
  }

  method gesture-end ($a) is vfunc {
    $.emit('end', $.last-event.time, $!distance);
  }

  method gesture-cancel is vfunc {
    $.emit('cancel', $.last-event.time, $!distance);
  }
}

class Gnome::Shell::UI::SwipeTracker::ScrollGesture
  is   GLib::Object
  does GLib::Roles::RegisterClass
{
  has gboolean $!enabled is g-property(RW);

  has MutterClutterOrientation $!orientation
    is g-property(RW, Mutter::Enums::Clutter::Orientation);

  has MutterClutterModifierType $!scroll-modifiers
    is g-property(RW, Mutter::Enums::Clutter::ModifierType);

  method Begin  (guint, gdouble, gdouble) is g-signal { }
  method Update (guint, gdouble, gdouble) is g-signal { }
  method End    (guint, gdouble)          is g-signal { }

  has $!began        = False;

  has $!allowedModes;

  submethod BUILD ( :$!allowedModes ) { }

  submethod TWEAK ( :$actor ) {
    $actor.Scroll-Event.tap: SUB { self.handleEvent( |$*A ) }
  }

  method enabled is rw {
    Proxy.new:
      FETCH => -> $ { $!enabled },

      STORE => -> $, \v {
        return if $!enabled == v;

        ($!enabled, $!began) = (v, False);
        $.notify('enabled');
      }
  }

  method canHandleEvent ($e) {
    return False unless $e.type == CLUTTER_EVENT_SCROLL;

    return False if [&&](
      $e.scroll-source             == CLUTTER_SCROLL_SOURCE_FINGER,
      $e.source-devide.device-type == CLUTTER_INPUT_DEVICE_TOUCHPAD
    );

    return False unless $.enabled;
    return False unless $!allowedModes +& Main.actionMode;

    return False if [&&](
      $!began.not,
      $!scrollModifiers.so,
      ($!state +& $.scrollModifies).so.not,
    );

    True;
  }

  method handleEvent ($a, $e) {
    return CLUTTER_EVENT_PROPAGATE unless $.canHandleEvent($e);
    return CLUTTER_EVENT_PROPAGATE
      unless $e.scroll-direction == CLUTTER_SCROLL_SMOOTH;

    my $v = $.orientation == CLUTTER_ORIENTATION_VERTICAL;
    my $d = $v ?? TOUCHPAD_BASE_HEIGHT !! TOUCHPAD_BASE_WIDTH;

    my ($t, \δ) = ( .time, .scroll-delta ) given $e;

    if [&&]( |δ.map( * == 0 ) ) {
      $.emit('end', $t, $d);
      $!began = False;
      return CLUTTER_EVENT_STOP;
    }

    if $!began {
      $.emit('begin', $t, |$e.coords);
      $!began = True;
    }

    my \Δ = ($v ?? δ.tail !! δ.head) * SCROLL_MULTIPLIER;
    $.emit('update', $t, Δ, $d);
    CLUTTER_EVENT_STOP
  }
}

class Gnome::Shell::UI::SwipeTracker
  is   GLib::Object
  does GLib::Roles::RegisterClass
{
  has gboolean $!enabled           is g-property(RW);

  has $!orientation
    is g-property(RW, Mutter::Enums::Clutter::Orientation)
    is default(CLUTTER_ORIENTATION_HORIZONTAL);

  has gdouble  $!distance          is g-property(RW);
  has gboolean $!allow-long-swipes is g-property(RW);

  has $scroll-modifiers
    is g-property(RW, Mutter::Enums::Clutter::ModifierType);

  method Begin  (uint)             is g-signal { }
  method Update (gdouble)          is g-signal { }
  method End    (guint64, gdouble) is g-signal { }

  has $!allowedModes;
  has $!cancelProgress;
  has $!dragGesture;
  has $!history;
  has $!initialProgress;
  has $!prevOffset;
  has $!progress;
  has $!scrollGesture;
  has $!touchGesture;
  has $!touchpadGesture;

  constant TPS = Gnome::Shell::UI::SwipeTracker::TouchpadGesture::Swipe;

  submethod BUILD (
    :$actor,
    :$!orientation,
    :$!allowedModes,
    :$!enabled,
    :$allowDrag       = True
    :$allowScroll     = True
  ) {
    $!distance = Global.screen-height
    self.reset;

    given $!touchpadGesture = TPS.new($!allowedModes) {
      .Begin.tap:  SUB { self.beginGesture(  |$*A ) }
      .Update.tap: SUB { self.updateGesture( |$*A ) }
      .End.tap:    SUB { self.endGesture(    |$*A ) }
    }
    self.bind-property('enabled',     $!touchpadGesture, flags => 0);
    self.bind-property('orientation', $!touchpadGesture);

    given $!touchGesture = TSG.new(
      $!allowedModes,
      GESTURE_FINGER_COUNT,
      CLUTTER_GESTURE_EDGE_AFTER
    ) {
      .Begin.tap:  SUB { self.beginTouchSwipe(       |$*A ) }
      .Update.tap: SUB { self.updateGesture(         |$*A ) }
      .End.tap:    SUB { self.endTouchGesture(       |$*A ) }
      .Cancel.tap: SUB { self.cancelTouchGesture(    |$*A ) }

      self.bind-property('enabled',     $_, flags => 0);
      self.bind-property('orientation', $_);
      self.bind-property('distance',    $_, flags => 0);
      Global.stage.add-action-full('swipe', CLUTTER_EVENT_CAPTURE, $_);
    }

    if $allowDrag {
      given $!dragGesture = TSG.new(
        $!allowedModes,
        1,
        CLUTTER_GESTURE_EDGE_AFTER
      ) {
        .Begin.tap:  SUB { self.beginTouchSwipe(       |$*A ) }
        .Update.tap: SUB { self.updateGesture(         |$*A ) }
        .End.tap:    SUB { self.endTouchGesture(       |$*A ) }
        .Cancel.tap: SUB { self.cancelTouchGesture(    |$*A ) }

        self.bind-property('enabled',     $_, flags => 0);
        self.bind-property('orientation', $_);
        self.bind-property('distance',    $_, flags => 0);
        Global.stage.add-action-full( 'drag', CLUTTER_EVENT_CAPTURE, $_ );
      }
    }

    if $allowScroll {
      given $!scrollGesture = SG.new($actor, $!allowedModes) {
        .Begin.tap:  SUB { self.beginTouchSwipe(       |$*A ) }
        .Update.tap: SUB { self.updateGesture(         |$*A ) }
        .End.tap:    SUB { self.endTouchPadGesture(    |$*A ) }

        self.bind-property('enabled',          $_, flags => 0);
        self.bind-property('orientation',      $_);
        self.bind-property('scroll-modifiers', $_, flags => 0);
      }
    }
  }

  method enabled is rw {
    Proxy.new:
      FETCH => -> $     { $!enabled },
      STORE => -> $, \v {
        return if $!enabled == v;

        $!enabled = v;
        $.interrupt if $!enabled.not && $!state == SCROLLING;
        $.notify('enabled');
      }
  }

  method distance is rw {
    # GENERIC-GET-SET(
    #   preFectch =>
    #   preStore =>
    #   postStore =>
    # )
    Proxy.new:
      FETCH => -> $     { $!distance },
      STORE => -> $, \v {
        return if $!distance == v;

        $!distance = v;
        $.notify('distance');
      }
  }

  method canHandleScrollEvent ($e) {
    return False if $!enabled.not || $!scrollGesture.defined.not;

    $!scrollGesture.canHandleEvent($e);
  }

  method reset {
    ($!initialProgress, $!cancelProgress, $!prevOffset, $!progress) = 0 xx 4;
    ($!snapPoints, $!cancelled, $!state) =  ( [], False, NONE );
    $!history.reset;
  }

  method interrupt {
    $.emit('end', 0, $!cancelProgress);
    $.reset;
  }

  method beginTouchSwipeGestue ($g, $t, $x, $y) {
    $!dragGesture.cancel if $!dragGesture;
    $.beginGesture($g, $t, $x, $y);
  }

  method beginGesture ($g, $t, $x, $y) {
    return if $!state == SCROLLING;
    $!history.append($t, 0);

    my $r = MTK::Rectangle.new( :$x, :$y );
    $.emit( 'begin', Global.display.get-monitor-index-from-rect($r) );
  }

  method findClosestPoint($pos) {
    $!snapPoints.kv
                .map( -> $k, $v { [ $k, ($v - $pos).abs ] })
                .sort( -*.tail )
                .head
  }

  method findNextPoint ($pos) {
    $!snapPoints.first( * > $pos, :k );
  }

  method findPrevPoint ($pos) {
    $!snapPoints.first( * < $pos, :k );
  }

  method findPointForProjection ($p, $v) {
    my  $i,     =   $.findClosestPoint($!initialProgress);
    my ($p, $v) = ( $.findPrevPoint($p), $.findNextPoint($p) );

    return $_ with if $v > 0 ?? $p !! $n;

    $.findClosestPoint($p);
  }

  method getBounds ($p) {
    return [ $!snapPoints.head, $!snapPoints.tail ] if $!allow-long-swipes;

    my $c = $.findClosestPoint($p)
    if $!snapPoints[$c] - $p < EPSILON {
      $p = $n = $c
    } else {
      ($p, $n) = ( $.findPrevPoint($p), $.findNextPoint($p) );
    }

    my ( $li, $ui ) = ( ($p.pred, 0).max, ($n.succ, $!snapPoints.elems).min );

    return [ .[$li], .[$ui] ] given $!snapPoints;
  }

  method updateGesture ($g, $t, $Δ, $d) {
    return unless $!state == SCROLLING;
    unless $!allowedModes +& Main.actionMode && $.enabled {
      $.interrupt;
      return;
    }

    $Δ = -$Δ if [&&](
      $.orientation == CLUTTER_ORIENTATION_HORIZONTAL,
      Mutter::Clutter::Main.is-rtl
    );

    $!progress += $Δ / $d;
    $!history.append($t, $Δ);
    $!progress = $!progress.&clamp( |$.getBounds );
    $.emit('update');
  }

  method getEndProgress ($v, $d, $it) {
    return $!cancelProgress if $.cancelled;

    my $t = $it ?? VELOCITY_THRESHOLD_TOUCHPAD !! VELOCITY_THRESHOLD_TOUCH;
    return $!snapPoints[ $.findClosestPoint($!progress) ] if $f.abs < $t;

    my $t = $it ?? DECELERATION_TOUCHPAD !! DECELERATION_TOUCH;
    my $s = $d / (1.0 - $d) / 1000.0;

    my $p = do if $v.abs > VELOCITY_CURVE_THRESHOLD {
      my $c = $s / 2 / DECELERATION_PARABOLA_MULTIPLIER;
      my $x = $v.abs - VELOCITY_CURVE_THRESHOLD + $c;

      $s * VELOCITY_CURVE_THRESHOLD + DECELERATION_PARABOLA_MULTIPLIER² * $x² -
           DECELERATION_PARABOLA_MULTIPLIER² * $c²;
    } else {
      $v.abs * $s;
    }

    $p = ( $p * $v.sign + $!progress );
    $p = $p.&clamp( |$.getBounds($!inintialProgress) );

    $!snapPoints[ $.findPointForProjection($p, $v) ];
  }

  method endTouchGesture  ($g, $t, $d) {
    $.endGesture($t, $d, False);
  }

  method endGesture ($t, $d, $it) {
    return unless $!state == SCROLLING;
    return unless ($!allowedModes +& Main.actionMode) && $!enabled;

    $!history.trim($t);

    my $v  = $!history.calculateVelocity;
    my $ep = $.getEndProgress($v, $d, $it);

    $v /= $d;
    $v  = ANIMATION_BASE_VELOCITY if ($ep - $!progress) * $v <= 0;

    my $n  = ( 1, ($!progress - $ep).abs.ceiling ).max;
    my $md = MAX_ANIMATION_DURATION * $n.succ.log(2);
    my $D  = ($!progress - $ep) / $v * DURATION_MULTIPLIER;

    $D = $D.&clamp(MIN_ANIMATION_DURATION, $md) if $D > 0;

    $.reset;
    $.emit('end', $D, $ep);
  }

  method cancelTouchGesture ($g, $t, $d) {
    return unless $!state == SCROLLING;

    $!cancelled = True;
    $.endGesture($t, $d, False);
  }

  method confirmSwipe ($d, $s, $c, $p) {
    ($!distance, $!snapPoints, $!state) = ($d, $s, SCROLLING);

    $!initialProgress = $!progress = $c;
    $!cancelProgress  = $p;
  }

  method destroy {
    if $!touchpadGesture {
      $!touchpadGesture.destroy;
      $!touchpadGesture = Nil;
    }

    if $!touchGesture {
      Global.stage.remove-action($!touchGesture);
      $!touchGesture = Nil;
    }
  }
}
