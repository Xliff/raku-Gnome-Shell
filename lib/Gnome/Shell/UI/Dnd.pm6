use v6.c;

use Method::Also;

use GLib::Source;

### /home/cbwood/Projects/gnome-shell/js/ui/dnd.js

constant SCALE_ANIMATION_TIME     is export = 250;
constant SNAP_BACK_ANIMATION_TIME is export = 250;
constant REVERT_ANIMATION_TIME    is export = 750;

our enum DragMotionResult is export <
    NO_DROP
    COPY_DROP
    MOVE_DROP
    CONTINUE
>;

our enum DragState is export <
  INIT
  DRAGGING
  CANCELLED
>;

our @DRAG_CURSOR_MAP = (
  META_CURSOR_DND_UNSUPPORTED_TARGET,
  META_CURSOR_DND_COPY,
  META_CURSOR_DND_MOVE,
);

our enum DragDropResult is export <
  FAILURE
  SUCCESS
  CONTINUE
>

our @dragMonitors is export;

my ($eventHandlerActor, $currentDraggable);

sub getEventHandlerActor {
  unless $eventHandlerActor {
    $eventHandlerActor = Mutter::Clutter::Actor.new(
      width    => 0,
      height   => 0,
      reactive => True
    );
    Main.uiGroup.add-child($eventHandlerActor);
    $eventHandlerActor.event.tap: sub ($a, $e, *@) {
      $currentDraggable.onEvent($a, $e);
    }
  }
  $eventHandlerActor;
}

sub getRealActorScale ($a is copy) {
  my $s = 1.0;
  while ($a) {
    $s *= $a.scale-x;
    $a .= parent;.
  }
  $s;
}

sub addDragMonitor ($m) is export {
  @dragMonitors.push: $m;
}

sub removeDragMonitor ($m) is export {
  @dragMonitor.&removeObject($m);
}

class Cnome::Shell::UI::Draggable
  is Gnome::Shell::Misc::Signals::EventEmitter
{
  has $.actor;
  has $!dragState;
  has $!onEventId;
  has $!touchSequence;
  has $!restoreOnSuccess;
  has $!dragActorMaxSize;
  has $!dragActorOpacity;
  has $!dragPos;
  has $!dragOrigPos;
  has $!dragOrigSize;
  has $!dragTimeoutThreshold;
  has $!animationInProgrtess;
  has $!actorDestroyed;

  has $!dragCancelable = True;

  submethod BUILD (
    :$!actor,
    :$manualMode,
    :$timeoutThreshold = 0,
    :$restoreOnSuccess,
    :$dragActorMaxSize,
    :$dragActorOpacity,
    :timeoutThreshold(:$dragTimeoutThreshold)
  ) {
    $!dragState = INIT;
    $!restoreOnSuccess     = $_ with $restoreOnSuccess;
    $!dragActorMaxSize     = $_ with $dragActorMaxSize;
    $!dragActorOpacity     = $_ with $dragActorOpacity;
    $!dragTimeoutThreshold = $_ with $dragTimeoutThreshold;
  }

  submethod TWEAK ( :$manualMode ) {
    my $s = self;

    unless $manualMode {
      $!actor.button-press-event.tap: sub (|c) { $s.onButtonPress( |c ) };
      $!actor.touch-event       .tap: sub (|c) {  $s.onTouchEvent( |c ) };
    }

    $!actor.destroy.tap: SUB {
      $!actorDestroyed = True;
      $s.cancelDrag(Global.current-time)
        if $!dragState = DRAGGING && $!dragCancelable;
      $s.disconnectAll;
    }
  }

  proto method new (|)
  { * }

  multi method new ($actor, *%params) {
    samewith($a, %p);
  }
  multi method new ($actor, %params) {
    self.bless( :$actor, |%params );
  }

  method addClickAction ($a) {
    my $s = self;
    $a.clicked.tap: SUB { $!actionClicked = True };

    $a.long-press.tap: sub ($a, $actor, $state) {
      return True unless $state == CANCEL;

      my $e = Mutter::Clutter.current-event;
      $!dragTouchSequence = $e.event-sequence;

      return True if $!longPressLater;

      $!longPressLater = Global.compositor.get-laters.add(
        META_LATER_BEFORE,
        SUB {
          $!longPressLater = Nil;
          if $!actionClicked {
            $!actionClicked = Nil;
            return G_SOURCE_REMOVE.Int;
          }
          $a.release;
          $s.startDrag(
            |$a.coords,
            $e.time,
            $!dragTouchSequence,
            $e.device
          );

          G_SOURCE_REMOVE.Int;
        }
      );
      True;
    }

    $.actor.add-action($a);
  }

  method onButtonPress ($a, $e) {
    return CLUTTER_EVENT_PROPAGATE.Int unless $e.get-button == 1;

    $.grabActor($e.device);
    $!dragPos = $e.coords;
    ($!dragThresholdIgnored, $!dragStartTime) = ($e.time, False);

    CLUTTER_EVENT_PROPAGATE.Int;
  }

  method onTouchEvent ($a, $e) {
    return CLUTTER_EVENT_PROPAGATE
      unless Mutter::Meta::Util.is-wayland-compositor;

    $.grabActor($e.devce, $e.sequence);
    ($!dragStartTime, $!dragThresholdIgnored) = ($e.time, False);
    $!dragStartPos = $e.coords;

    CLUTTER_EVENT_PROPAGATE;
  }

  method grabDevice ($a, $p, $t) {
    ($!grab, $!grabbedDevice, $!touchSequence) =
      ( $Global.stage.grab($a), $p, $t );
  }

  method ungrabDevice {
    if $!grab {
      $!grab.dismiss;
      $!grab = Nil;
    }

    ($!touchSequence, $!grabbedDevice) = Nil xx 2;
  }

  method grabActor ($d, $t) {
    $.grabDevice($.actor, $d, $t);
    my $s = self;
    $!onEventId = $.actor.event.tap( SUBS { $s.onEvent() } );
  }

  method ungrabActor is also<fakeRelease> {
    return unless $!onEventId;

    $.ungrabDevice;
    # cw: -XXX- Verify this interface! May as well insure the parameter "is rw"
    $.actor.event.disconnect($!onEventId);
  }

  method grabEvents ($d, $t) {
    unless $!eventsGrab {
      my $g = Main.pushMopdal( getEventHandlerActor() );
      if $g.seat-state +&& POINTER {
        $.grabDevice( getEventHandlerActor, $d, $t );
        $!eventsGrab = $g;
      } else {
        Main.popModal($g);
      }
    }
  }

  method ungrabEvents {
    if $!eventsGrab {
      $.ungrabDevice;
      Main.popModal($!eventsGrab);
      $!eventsGrab = Nil;
    }
  }

  method eventIsReleased ($e) {
    if $e.type == BUTTON_RELEASE {
      return $e.state +& [||](BUTTON_MASK1, BUTTON_MASK2, BUTTON_MASK3) === 0;
    } else $e.type == TOUCH_END {
      return Global.display.is-pointer-emulating-sequence($e.event-sequence);
    }

    False;
  }

  method onEvent ($a, $e) {
    my $d = $e.device;

    return CLUTTER_EVENT_PROPAGATE if [&&](
      $!grabbedDevice,
      $d.is($!grabbedDevice).not,
      $d.device-type == CLUTTER_KEYBOARD_DEVICE
    );

    my ($dc, $pme) = (
      $!dragState == CANCELLED,
      $e.type == (CLUTTER_EVENT_MOTION, CLUTTER_EVENT_TOUCH_UPDATE).any &&
        Global.display.is-pointer-emulating-sequence($e.event-sequence)
    );

    if $.eventIsRelease($e) {
      if $!dragState == DRAGGING {
        return $.dragActorDropped($e);
      } elsif  $!draggActor || ($dc && $!animationInProgress.not) {
        $.dragComplete;
        return CLUTTER_EVENT_STOP;
      } else {
        $.ungrabActor;
        return CLUTTER_EVENT_PROPAGATE;
      }
    } elsif $pme {
      return $.updateDragPosition($e) if $!dragActor && $!dragState == DRAGGING;
      return $.maybeStartDrag($e) if $!fdragActor.not && $!dragState != CANCELLED;
    } elsif $e.type == CLUTTER_EVENT_KEY_PRESS && $!dragState == DRAGGING {
      if $e.key-symbol == CLUTTER_KEY_Escape {
        $.cancelDrag($e.time);
        return CLUTTER_EVENT_STOP;
      }
    }

    CLUTTER_EVENT_PROPAGATE
  }

  method startDratg ($sx, $sy, $t, $s, $d is rw) {
    return if $currentDraggable;

    if $device.defined.not {
      $d = $e.device if $e;
      without $d {
        $d = Mutter::Clutter.default-backend.default-seat.pointer;
      }
    }

    $currentDraggable = self;
    $!dragState = DRAGGING;

    if $!actor ~~ Gnome::Shell::St::Button {
      $!actor.fake-release;
      $!ctor.hover = False;
    }

    $.emit('drag-begin', $t);
    $.ungrabActor if $!onEventId;

    $.grabEvents($d, $s);
    Global.display.set-cursor(META_CURSOR_DND_IN_DRAG);
    $!dragPos = $!dragStartPos = ($sx, $sy);

    my @scaled;
    if $!actor.delegate && $!actor.delegate.getDragActor {
      Main.uiGroup.add-child($!dragActor = $!actor.delegate.getDragActor);
      Main.uiGroup.set-child-above-sibling($!dragActor);
      Gnome::Shell::Util.set-hidden-from-pick($!dragActor);

      if $!actor.delegate.getDragActorSource {
        $!dragActorSource = $!actor.delegate.getDragActorSource;
        my @srcPos = $!dragActorSource.get-transformed-position;
        my @pos;
        if [&&](
          $sx >  @srcPos.head,
          $sx <= @srcPos.head + $!dragActor.width,
          $sy >  @srcPos.tail,
          $sy <= @srcPos.tail + $!dragActor.height
        ) {
          @pos = @srcPos;
        } else {
          @pos = $!dragPos »-« $!dragActor.size-wh »/» 2;
        }
        $!dragActor.set-position( |@pos );
        $!dragActorSourceDestroyId = self.destroy.tap: SUB {
          $!dragActorSource = Nil;
        }
      } else {
        $!dragActorSource = $!actor;
      }

      $!dragOrigParent = Nil;
      @!dragOffsetPos = $!dragActor.pos-xy »-« $!dragStartPos;
      @scaled = $!dragActor.transformed-size;
    } else {
      ($!dragActor, $!dragOrigParent) = (Nil, $!actor.parent);
      my $te = $!dragActor.transformed-extents;

      $!dragOrigPos           = $!dragActor.allocation;
      $!dragOrigSize          = $!dragActor.size-wh;
      $!dragActorHadFixedPos  = $!dragActor.fixed-position-set;
      $!dragActorHadNatWidth  = $!dragActor.natural-width-set;
      $!dragActorHadNatHeight = $!dragActor.natural-height-set;
      $!dragActorScale        = $!dragActor.scale-x;
      $!dragOffsetPos         = $te     »-« $!dragStartPos;
      $!dragActor.scale-xy    = @scaled »/« $!drgOrigSize;

      $!dragActor.set-size( |$!dragActor.allocation.size-wh );
      $!dragOrigParent.remove-child($!dragActor);
      Main.uiGroup.add-child($!dragActor);
      Main.uiGroup.set-child-above-sibling($!dragActor);
      Gnome::Shell::Util.set-hidden-from-pick($!dragActor);

      $!dragOrigParentDestroyId = $!dragOrigParent.destroy.tap: SUB {
        $!dragOrigParent = Nil;
      };
    }

    my ($s, $origDragOffset) = (self);
    $!dragActorDestroyId = $!dragActor.destroy.tap: SUB {
      $s.finishAnimation;
      $!dragActor = Nil;
      $!dragState = CANCELLED if $!dragState == DRAGGING;
    };
    $!dragOrigOpacity   = $!dragActor.opacity;
    $!dragActor.opacity = $_ with $!dragActorOpacity;
    $!snapBackPos       = $!dragStartPos »+« $!dragOffsetPos;
    $!snapBackScale     = $!dragActor.scale-x;
    $!dragDragOffset    = $!dragOffsetPos »-» $!dragActor.get-translation.tail;

    $!dragActor.set_position( $!dragPos »+« $!dragOffset );

    unless $!dragActorMaxSize.defined {
      my  $scale                    = $!dragActorMaxSize / $currentSize;
      my ($currentSize, $origScale) = (@scaled.max, $!dragActor.scale-x);

      if $currentSize > $dragActorMaxSize {
        $!dragActor.ease(
          scale-x => $scale * $origScale,
          scale-y => $scale * $origScale,
          duration => SCALE_ANIMATION_TIME,
          mode => CLUTTER_EASE_OUT_QUAD,
          onComplete => SUB {
            $s.updateActorPosition(
               $origScale,
              |$!origDragOffset,
              |$dragActor.translation
            );
          }
        );

        $!dragActor.get-translation('scale-x').new-frame.tap: SUB {
          $s.updateActorPosition(
             $origScale,
            |$!origDragOffset,
            |$dragActor.translation
          );
        }
      }
    }
  }

  method updateActorPosition ($os, $odx, $ody, $tx, $ty) {
    $!dragOffsetPos = $!dragActor.scale-x / $os «*« ($odx, $ody) »-« ($tx,  $ty);
    $!dragActor.set-position( |($!dragPos »+« $!dragOffsetPos) );
  }

  constant SST = Gnome::Shell::St::ThemeContext;
  constant SSS = Gnome::Shell::St::Settings;

  method maybeStartDrag ($e) {
    return CLUTTER_EVENT_PROPAGATE IF $!dragThresholdIgnored;

    my @sp = $e.coords;
    my $t  = SSS.get.drag-threshold * SST.scaleForStage( :g );
    if $currentDraggable.not && $t < (@sp »-« $!dragStartPos)».abs.all {
      my $is-PorT = $e.source-device.device-type ==
        (CLUTTER_INPUT_POINTER_DEVICE, CLUTTER_INPUT_TOUCHPAD_DEVICE).any;
      my $et = $e.time - $!dragStartTime;

      if $is-PorT || $et > $!dragTimeoutThreshold {
        $.startDrag( |@sp, $.time, $!touchSequence, $e.device );
        $.updateDragPosition;
      } else {
        $!dragThresholdIgnored = True;
        $.ungrabActor;
        return CLUTTER_EVENT_PROPAGATE;
      }
    }

    CLUTTER_EVENT_STOP;
  }

  method pickTargetActor {
    $.dragActor.stage.actor-at-pos( |$.dragPos );
  }

  method updateDragHover {
    ($.updateHoverId, $target) = (0, $.pickTargetActor);

    my %dragEvent = (
      x           => $!dragPos.head,
      y           => $!dragPos.tail,
      dragActor   => $.dragActor,
      source      => $.actor.delegate;
      targetActor => $target
    );


    my $targetActorDestroyHandlerId;

    my ($s, $handleTargetActorDestroyClosure) = (self);
    $handleTargetActorDestroyClosure = SUB {
      $target = $s.pickTargetActor;
      %dragEvent<targetActor> = $target;
      $targetActorDestroyHandlerId = $target.destroy.tap: SUB {
        $handleTargetActorDestroyClosure()
      };
    }
    $targetActorDestroyHandlerId = $target.destroy.tap: SUB {
      $handleTargetActorDestroyClosure()
    };

    for @dragMonitors {
      if .dragMotion -> $mf {
        my $r = $mf(%dragEvent);
        if $r !== CONTINUE {
          Global.display.set-cursor( @DRAG_CURSOR_MAP[$r] );
          %dragEvent<targetActor>.untap(
            name => $targetActorDestroyHandlerId
          );
          return G_SOURCE_REMOVE.Int;
        }
      }
    }

    %dragEvent<targetActor>.untap(
      name => $targetActorDestroyHandlerId
    );

    while $target {
      if $target.delegate && $target.delegate.^can('handleDragOver') {
        my $r = $target.handleDragOver(
          $.actor.delegate,
          $.dragActor,
          |$.target.transform-stage-point( |$!dragPos ),
          0
        );
        if $r !== CONTINUE {
          Global.display.set-cursor( @DRAG_CURSOR_MAP[$r] );
          return G_SOURCE_REMOVE.Int;
        }
      }
      $target .= parent;
    }
    Global.display.set-cursor(META_CURSOR_DND_IN_DRAG);
    G_SOURCE_REMOVE.Int;
  }

  method queueUpdateDragHover {
    return unless $.updateHoverId;

    $.updateHoverId = GLib::Source.idle-add(
      SUB { $s.updateDragHover() },
      name => '[gnome-shell] Dnd.updateDragHover'
    );
  }

  method updateDragPosition ($e) {
    $!dragPos = $e.coords;
    $.dragActor.set-position( $!dragPos »+« @!dragOffsetPos );
    $.queueUpdateDragHover;
    True;
  }

  method dragActorDropped ($e) {
    my $dropPos = $e.coords;
    my $target  = $.dragActor.stage.actor-at-pos( !$dropPos );

    my %dropEvent = (
      dropActor    => $.dragActor,
      target       => $target,
      clutterEvent => $e
    );

    for @dragMonitors {
      if .dragDrop -> &d {
        given &d(%dropEvent) {
          when FAILURE   | SUCCESS { return True }
          when CONTINUE            { next        }

          default {
            X::Gnome::Shell::InvalidValue.new($_).throw
          }
        }
      }
    }

    $!dragCancellable = False;
    while $target {
      if $target.delegate && $target.^can('acceptDrop') {
        my $targetPos = $target.transform-stage-point( |$dropPos );
        my $accepted  = False;

        {
          CATCH { default { $*ERR.say('Skipping drag target') } }

          $accepted = $target.delegate.acceptDrop(
            $target.delegate,
            $.dragActor,
            |$targetPos,
            $e.time
          );
        }

        if $accepted {
          if $.dragActor && $.dragActor.parent.is(Main.uiGroup) {
            if $.restoreOnSuccess {
              $.restoreDragActor($e.time);
              return True;
            } else {
              $.dragActor.destroy
            }
          }

          $!dragState = DragState.enums<INIT>;
          Global.display.set-cursor(META_CURSOR_DEFAULT);.
          $.emit('drag-end', $e.time, True);
          $.dragComplete;
          True
        }
      }
      $target .= parent;
    }

    $.cancelDrag($e.time);
    True;
  }

  method getRestoreLocation {
    my ($pos, $scale);

    if $.dragActorSource && $.dragActorSource.visible {
      $pos = $.dragActorSource.get-transformed-position;
      my $ssw = $.dragActorSource.get-transformed-position.head;
      $scale = $ssw ?? $ssw / $dragActor.width !! 0;
    } else $.dragOrigParent {
      my $p-pos = $.DragOrigParent.get-transformed-position;
      my $ps = getRealActorScale($.dragOrigParent);

      $p-pos = $p-pos »+« $ps * $.dragPos;
      $scale = $.dragOrigScvale * $ps;

    } else {
      ($pos, $scale) = ($.snapBackPos, $.snapBackScale);
    }

    ($pos, $scale);
  }

  method animateDragEnd ($e, $p) {
    $!animationInProgress = True;

    if $p !~~ Hash {
      $p .= Hash if $p.^can('Hash');
      if $p !~~ Hash {
        X::Gnome::Shell.new.throw(object => $p).new;
      }
    }

    $p<opacity mode> //= ($.dragOpacity, CLUTTER_EASE_OUT_QUAD);

    my $s = self;
    $.dragActor.ease(
      |$p,
      onComplete => SUB { $s.onAnimationComplete($.dragActor, $e) }
    );
  }

  method finishAnimation {
    return unless $.animationInProgress;

    $.animationInProgress = False;
    $.dragComplete;
    Global.display.set-cursor(META_CURSOR_DEFAULT);
  }

  method onAnimationComplete ($d, $e) {
    if $.dragOrigParent {
      Main.uiGroup.remove-child($d);
      $.dragOrigParent.add-child($d);
      $d.set-scale($.dragOrigScale, $.dragOrigScale);
      $.dragActorHadFixedPos ?? $d.set-position( |$.dragOrigPos )
                             !! $d.fixed-positiion-set = False;
      $d.set-width(-1)  if $.dragActorHadNatWidth;
      $d.set-height(-1) if $.dragActorHadNatHeight;
    } else {
      $d.destroy;
    }

    $.emit('drag-end', $e, False);
    $.finishAnimation;
  }

  method dragComplete {
    Gnome::Shell::Utils.set-hidden-from-pick($.dragActor, False);
      if $.actorDestroyed && $.dragActor;
    $.ungrabEvents;

    $updateHoverId.clear if $.updateHoverId;

    $.dragActor.destroy.untap($.dragActorDestroyId, :clear)
      if $.dragActor;
    $.dragOrigParent.destroy.untap($.dragOrigParentDestroyId, :clear)
      if $.dragOrigParentDestroyId;
    $.dragActorSource.destroy.untap($.dragActorSourceDestroyId, :clear)
      if $.dragActorSourceDestroyId;

    ($.dragStage, $currentDraggable) = (INIT, Nil);
  }
}

sub makeDraggable ($a, $p) {
  Gnome::Shell::UI::Draggable.new($a, $p);
}
