use v6.c;

use Method::Also;

use Gnome::Shell::Raw::Types;

### /home/cbwood/Projects/gnome-shell/js/ui/windowPreview.js

constant WINDOW_DND_SIZE                  is export  = 256;
constant WINDOW_OVERLAY_IDLE_HIDE_TIMEOUT is export  = 750;
constant WINDOW_OVERLAY_FADE_TIME         is export  = 200;
constant WINDOW_SCALE_TIME                is export  = 200;
constant WINDOW_ACTIVE_SIZE_INC           is export  = 5;   # in each direction
constant DRAGGING_WINDOW_OPACITY          is export  = 100;
constant ICON_SIZE                        is export  = 64;
constant ICON_OVERLAP                     is export  = 0.7;
constant ICON_TITLE_SPACING               is export  = 6;

class Gnome::Shell::UI::WindowsPreview extens Gnome::Shell::WindowPreview {
  has $!meta-window;
  has $!workspace;
  has $!overview-adjustment;
  has $!overlay-enabled;
  has $!bounding-box;
  has $!window-center;

  method bounding-box
    is also<
      bounding_box
      boundingBox
    >
  {
    $!cachedBoundingBox.clone;
  }

  method window-center
    is also<
      window_center
      windowCenter
    >
  {
    (
      class :: {
        method x { $!cachedBoundingBox.x + $!cachedBoundingBox.w / 2 }
        method y { $!cachedBoundingBox.y + $!cachedBoundingBox.h / 2 }
      }
    ).new;
  }

  has Bool $!overlay-enabled is g-property;

  method overlay-enabled is rw
    is also<
      overlay_enabled
      overlayEnabled
    >
  {
    Proxy.new:
      FETCH => -> $     { $!overlay-enabled },

      STORE => -> $, Bool() $v {
        return if $!overlay-enabled === $v;

        $!overlay-enabled = $v;
        $.notify('overlay-enabled');

        if $v {
          $.hideOverlay(False);
        } elsif $!has-pointer || Global.stage.key-focus === self {
          $.showOverlay(True);
        }
      }
  }

  method drag-begin        is g-signal { }
  method drag-cancelled    is g-signal { }
  method drag-end          is g-signal { }
  method selected (uint32) is g-signal { }
  method show-chrome       is g-signal { }
  method size-changed      is g-signal { }

  submethod BUILD (
    :metaWindow( :$!meta-window ),
    :$!workspace,
    :overviewAdjustment( :$!overview-adjustment )
  ) { }

  submethod TWEAK {
    $!windowActor = $!meta-window.get-compositor-private;

    $.setAttributes(
      reactive           => True,
      can-focus          => True,
      accessible-role    => ATK_ROLE_PUSH_BUTTON,
      offscreen-redirect => CLUTTER_OFFSCREEN_AUTOMATIC_FOR_OPACITY
    );

    my $wc = $!window-container = Clutter::Actor.new(
      pivot-point => Graphene::Point.new(0.5, 0.5)
    );

    my $s = self;
    $wc.notify('scale-x').tap( *@a -> {
      $s.oadjustOverlayOffsets;
    });
    $wc.layout-manager = Gnome::Shell::WindowPreviewLayout.new;
    $.add-child($wc);

    $!cachedBoundingBox = {
      x      => $wc.layout-manager.bounding-box.x1,
      y      => $wc.layout-manager.bounding-box.y1,
      width  => $wc.layout-manager.bounding-box.width,
      height => $wc.layout-manager.bounding-box.height,
    };

    $wc.layout-manager.notify('bounding-box').tap( -> *@a ($l) {
      $!cachedBoundingBox = {
        x      => $l.bounding-box.x1,
        y      => $l.bounding-box.y1,
        width  => $l.bounding-box.width,
        height => $l.bounding-box.height,
      };

      $s.emit('size-changed') if $l.bounding-box.area > 0
    });

    $!windowActor.destroy.tap( -> *@a { self.destroy });

    $.updateAttachedDialogs;

    $.destroy.tap( -> *@a { $s.onDestroy });

    $!draggable = Gnome::Shell::UI::DND.makeDraggable(
      self,
      restoreOnSuccess  => True,
      dragActgorMaxSize => WINDOW_DND_SIZE,
      dragActorOpacity  => DRAGGING_WINDOW_OPACITY
    );
    $!draggable.drag-begin.tap(     -> *@a { $s.onDragBegin     });
    $!draggable.drag-cancelled.tap( -> *@a { $s.onDragCancelled });
    $!draggable.drag-end.tap(       -> *@a { $s.onDragEnd       });
    $!inDrag = False;

    my $clickAction = Mutter::Clutter::ClickAction.new;
    $clickAction.clicked.tap( -> *@a { $s.activate });
    $clickAction.long-press.tap( -> *@a ($, $, $state, $r) {
      $.showOverlay(True) if $state === CLUTTER_LONG_PRESS_STATE_ACTIVATE
      $r.r = True;
    });

    $!draggable.addClickAction($clickAction);

    ($!overlayEnabled, $!overlayShown, $!closeRequested, $!idleHideOverlayId) =
      (True, False, False, 0);

    my $tracker = Gnome::Shell::WindowTracker.get-default;
    my $app     = $tracker.get-window-app($!meta-window);
    $!icon = $app.create-icon-texture(ICON_SIZE);
    $!icon.add-style-class-name('icon-dropshadow');
    $!icon.setAttributes(
      reactive    => True,
      pivot-point => Graphene::Point.new(0.5, 0.5)
    ));
    $!icon.add-constraint(Mutter::Clutter::BindConstraint.new(
      $wc,
      CLUTTER_BIND_COORDINATE_POSITION
    ));
    $!icon.add-constraint(Mutter::Clutter::AlignConstraint.new(
      $wc,
      CLUTTER_ALIGN_X_AXIS
      0.5
    ));
    $!icon.add-constraint(Mutter::Clutter::AlignConstraint.new(
      $wc,
      CLUTTER_ALIGN_Y_AXIS,
      1,
      Graphene::Point.new(-1, ICON_OVERLAP)
    ));

    my $scaleFactor = $.scale-factor;

    $!title = Gnome::Shell::St::Label.new(
      visible     => False,
      style-class => 'window-caption',
      text        => $.getCaption,
      reactive    => True
    );
    $!title.cluter-text.single-line-mode = True;
    $!title.add-constraint(Mutter::Clutter::BindConstraint.new(
      source     => $wc,
      coordinate => CLUTTER_BIND_COORDINATE_X
    ));
    my $iconBottomOerlap = ICON_SIZE * ICON_OVERLAP.pred;
    $!title.add-constraint(Mutter::Clutter::BindConstraint.new(
      source     => $wc,
      coordinate => CLUTTER_BIND_COORDINATE_Y
      offset     => $scaleFactor * ($iconBottomOverlap + ICON_TITLE_SPACING)
    ));
    $!title.add-constraint(Mutter::Clutter::AlignConstraint.new(
      source     => $wc,
      align-axis => CLUTTER_ALIGN_X_AXIS,
      factor     => 0.5
    ));
    $!title.add-constraint(Mutter::Clutter::AlignConstraint.new(
      source      => $wc,
      align-axis  => CLUTTER_ALIGN_AXIS_Y,
      pivot-point => Graphene::Point.new(-1, 0),
      factor      => 1
    ));
    $!title.clutter-text-ellipsize = PANGO_ELLIPSIZE_END;
    $!label-actor = $!title;
    $!meta-window.notify('title').tap( -> *@a { $!title.text = $.getCaption });

    my $l = Meta::Prefs.get-button-layout;
    $!closeButtonSize = $l.left-buttons.includes(META_BUTTON_FUNCTION_CLOSE)
      ?? ST_SIDE_LEFT !! ST_SIDE_RIGHT
    $!closeButton = Gnome::Shell::St::Button.new(
      visible     => False,
      style-class => 'window-close',
      icon-name   => 'preview-close-symbolic'
    ));
    $!close-button.add-constraint(Mutter::Clutter::BindConstraint.new(
      source     => $wc,
      coordinate => CLUTTER_BIND_COORDINATE_POSITION
    ));
    $!closeButton.add-constraint(Mutter::Clutter::AlignConstraint.new(
      source      => $wc,
      align-axis  => CLUTTER_ALIGN_X_AXIS,
      pivot-point => Graphene::Point.new(0.5, -1),
      factor      => $!closeButtonSize === ST_SIDE_LEFT ?? 0 !! 1
    ));
    $!closeButton.add-constraint(Mutter::Clutter::AlignConstraint.new(
      source      => $wc,
      align-axis  => CLUTTER_ALIGN_Y_AXIS,
      pivot-point => Graphene::Point.new(-1, 0.5);
      factor      => 0
    ));
    $!closeButton.clicked.tap( -> *@a { $.deleteAll });

    $.add-child($_) for $!title, $!icon, $!closeButton;

    $!overViewAdjust.notify('value').tap( -> *@a { $s.updateIconScale });
    $.updateIconScale;

    $.notify('realized').tap( -> *@a {
      return unless $.realized;
      $!title.ensure-syle;
      $!icon.ensure-style;
    });
  }

  method close-button-is-left {
    $!closeButtonSize === ST_SIDE_LEFT;
  }

  method updateIconScale {
    my ($currentState, $initialState, $finalState) =
      $!overViewAdjustment.getStateTransitionParams();

    my $visible =
      ($initialState, $finalState).any === CONTROLS_STATE_WINDOW_PICKER;

    my $scale = $visible ?? (CONTROLS_STATE_WINDOW_PICKER - $currentState)
                         !! 0;

    $!icon.setAttribute( scale-xy => $scale );
  }

  method windowCanClose {
    $!meta-window.can-close && $!hasAttachedDialogs.not;
  }

  method getCaption {
    return $!meta-window.title if $!meta-window.title;

    my $app = Gnome::Shell::WindowTracker.default.window-app($!meta-window);
    $app.name;
  }

  method overlapHeights {
    my $titleHeight = $!title.get-preferred-height.tail;

    (0, ICON_TITLE_SPACING + $titleHeight);
  }

  method scale-factor {
    Gnome::Shell::ThemeContext.get-for-stage(Global.stage).scale-factor
  }

  method chromeHeights {
    my ($cbh, $ih) = ( $!closeButton, $!icon )».get-preferred-height».tail;

    my $sf = $.scale-factor;

    [ $cbh / 2, (1 - ICON_OVERLAP) * $ih ] »+» WINDOW_ACTIVE_SIZE_INC * $sf;
  }

  method chromeWidths {
    my $cbw = $!closeButton.get-preferred-width.tail;
    my $sf  = $.scale-factor;

    my $aes = WINDOW_ACTIVE_SIZE_INC * $sf;

    my $lo = $.close-button-is-left ?? $cbw / 2 !! 0;
    my $ro = $.close-button-is-left ?? 0        !! $cbw / 2;

    [ $lo, $ro ] »+» $aes;
  }

  method showOverlay ($animate) {
    return unless $!overlayEnabled;
    return if     $!overlayShown;

    $!overlayShown = True;
    $.restack;

    my $ongoingTrsansition = $!title.get-transition('opacity');
    return if [&&](
      $animate,
      $ongoingTransition,
      $ongoingTransition.interval.peek-final-value === 255
    );

    my $toShow = $!windowCanClose ?? [ $!title, $!closeButton ] !! [ $!title ];

    for $toShow[] {
      .opacity = 0;
      .show;
      .ease(
        opacity  => 255,
        duration => $animate ?? WINDOW_OVERLAY_FADE_TIME !! 0;
        mode     => CLUTTER_EASE_OUT_QUAD
      );
    }

    my ($w, $h) = $!window-container.get-size;
    my  $aES    = WINDOW_ACTIVE_SIZE_INC * 2 * $.scale-factor;
    my  $os     = ($w, $h).max;
    my  $scale  = ($os + $aES) / @os;

    $!window-conmtainer.ease(
      scale-x  => $scale,
      scale-y  => $scale,
      duration => $animate ? WINDOW_SCALE_TIME !! 0,
      mode     => CLUTTER_EASE_OUT_QUAD
    );

    $.emit('show-chrome');
  }

  method hideOverlay ($animate) {
    return unless $!overlayShown;

    $!overlayShown = False;
    $.restack;

    my $ongoingTransition = $!title.get-transition('opacity');
    return if [&&](
      $animate,
      $ongoingTransition,
      $ongoingTransition.interval.peek-final-value === 0
    );

    for $!title, $!closeButton {
      my $i = $_;

      .opacity = 255;
      .ease(
        opacity    => 0,
        duration   => $animate ?? WINDOW_OVERLAY_FADE_TIME !! 0;
        mode       => CLUTTER_EASE_OUT_QUAD,
        # cw: Better to make method calls from a callback via a lexical!
        onComplete => -> @a { $i.hide }
      );
    }

    $!window-container.ease(
      scale-x  => 1,
      scale-y  => 1,
      duration => $animate ? WINDOW_SCALE_TIME !! 0,
      mode     => CLUTTER_EASE_OUT_QUAD
    );
  }

  method adjustOverlayOffsets {
    my  $ps       = $!window-container.scale-x;
    my ($pw, $ph) = $!window-container.allocation.get-size;
    my ($hi, $wi) = ($ph, $pw) »*» $ps.pred / 2;

    ($!icon.translation-y, $!title.translation-y) = $hi xx 2;

    $!closeButton.setAttributes(
      translation-x => $.close-button-is-left.Int * $widthIncrease,
      translation-y => -$hi
    );
  }

  method addWindow ($metawindow) {
    my $c = $!window.container.layout-manager.add-window($metawindow);
    return unless $c;

    Gnome::Shell::iutils.set-hidden-from-pick($c, True);
  }

  method has-overlaps is vfunc {
    return $.hasAttachedDialogs || $!icon.visible || $!closeButton.visible;
  }

  method deleteAll {
    .delete(Global.current-time)
      for $!window-container.layout-manager.get-windows;

    $!closeRequested = True;
  }

  method addDialog ($win) {
    my $parent = $win.get-transient-for;
    while $parent.is-attached-dialog {
      $parent = $parent.get-transient-for;
    }

    $!addWindow($win)
      if $win.is-attached-dialog && +$parent === +$!meta-window;

    $.activate if $!closeRequested;
  }

  method hasAttachedDialogs {
    $!window-container.layout-manager.get-windows.elems > 1;
  }

  method updateAttachedDialogs {
    my $iter = 0;

    my $s = self;
    $iter = -> $win {
      return 0 unless $win.get-compositor-private;
      return 0 unless $win.is-attached-dialog;

      $s.addWindow($win);
      $win.foreach-transient($iter);
      return 1;
    })
    $!meta-window.foreach-transient($iter);
  }

  method getActualStackAbove {
    return Nil without $.stackAbove;

    # cw: Still not understanding the concept of delegates.
    $.stackAbove;
  }

  method setStackAbove ($actor) {
    $!stack-above = $actor;
    return if $.inDrag;

    my $parent = self.parent;

    if $.getActualStackAbove -> $a {
      $parent.set-child-below-sibling(self, $a);
    } else {
      $parent.set-child-below-sibling(self);
    }
  }

  method onDestroy {
    $!destroyed = True;

    Global.compositor.laters.remove($!long-press-later);
      if $!long-press-later;

    $!idleHideOverlayId.cancel if $!idleHideOverlayId;

    if $!inDrag {
      $.emit('drag-end');
      $!inDrag = False
    }
  }

  method activate {
    $.emit('selected', Global.current-time);
  }

  method enter-event ($event) is vfunc {
    $.showOverlay(True);
    callsame;
  }

  method leave-event ($event)is vfunc {
    return callsame if $!destroyed;

    return callsame if [&&](
      $event.flags +& CLUTTER_EVENT_FLAG_GRAB_NOTIFY,
      +Global.stage.grab-actor === +$!closeButton
    );

    my $s = self;
    $!idleHideOverlayId.cancel if $!idleHideOverlayId;
    $!idleHideOverlayId = GLib::Timeout.add(
      WINDOW_OVERLAY_IDLE_HIDE_TIMEOUT,
      -> sub (*@a) {
        return G_SOURCE_CONTINUE.Int
          if $!closeButton.has-pointer || $!title.has-pointer;

        $s.hideOverlay(True) if $s.has-pointer;
        $!idleHideOverlayId = 0;
        G_SOURCE_REMOVE.Int;
      },
      name => '[gnome-shell $!idleHideOverlayId'
    );

    callsame;
  }


  method key-focus-in is vfunc {
    callsame;
    $.showOverlay(True);
  }

  method key-focus-out is vfunc {
    callsame;

    $.hideOverlay(True) if +Global.stage.grab-actor === +$!closeButton;
  }

  method key-press-event ($event) is vfunc {
    if $e.key-symbol === (
      MUTTER_CLUTTER_KEY_Return,
      MUTTER_CLUTTER_KEY_KP_Enter
    ).any {
      $.activate;
      return True;
    }

    callsame;
  }

  method restack {
    my $p = $.parent;

    if $p {
      if $!overlay-shown {
        $p.set-child-above-sibling(self);
      } elsif $.stackAbove.not {
        $p.set-child-above-sibling(self);
      } elsif $.stackAbove.overlayShown {
        $$p.set-child-above-sibling(self, $.stackAbove);
    }
  }

  method onDragBegin ($d, $t) {
    $!inDrag = True;
    $.hideOverlay(False);
    $.emit('drag-begin');
  }

  method handleDragOver ($s, $a, $x, $x, $t) {
    $!workspace.handleDragOver($s, $a, $x, $y, $t);
  }

  method acceptDrop ($s, $a, $x, $y, $t) {
    $!workspace.acceptDrop($s, $a, $x, $y, $t);
  }

  method onDragCancel($d, $t);
    $.emit('drag-cancelled');
  }

  method onDragEnd ($d, $t, $s) {
    $.inDrag = False;

    $.restack;

    $.showOverlay(True) if $!has-pointer;

    $.emit('drag-end');
  }

}








  # ...

}
