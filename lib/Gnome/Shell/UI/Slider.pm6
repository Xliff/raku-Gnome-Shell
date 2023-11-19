use v6.c;

use NativeCall;

use Gnome::Shell::UI::BarLevel;

### /home/cbwood/Projects/gnome-shell/js/ui/slider.js

class GnomeShellUISlider is repr<CStruct>
  does GObjectDerived[GnomeShellUIBarLevel]
{
  HAS GnomeShellUIBarLevel $.parent;

  has gint             $.releaseId       is gattribute;
  has bool             $.dragging        is gattribute;
  has GdkDevice        $!grabbedDevice   is gattribute;
  has GdkEventSequence $!grabbedSequence is gattribute;

  method drag-begin is g-signal { }
  method drag-end   is g-signal { }
}

class Gnome::Shell::UI::Slider is Gnome::Shell::UI::BarLevel {
  has GnomeShellUISlider $!s is implementor handles<releaseId dragging>;

  submethod BUILD ( :$value ) {
    self.setAttribute(
      :$value,
      style-class     => 'slider',

      can-focus       => True,
      reactive        => True,
      accessible-role => ATK_ROLE_SLIDER,
      x-expand        => True
    );

    .releaseId, .dragging = (0, False) given self;

    self.Custom-Accessible.tap( -> *@a {
      self.getMinimumIncrement( |@a );
    });
  }

  method repaint is vfunc {
    self::Gnome::Shell::UI::BarLevel::repaint;

    my ($cr, $themeNode) = ( .get-context, .get-theme-node ) given self;

    my ($width, $height) = self.get-surface-size;

    my $handleRadius = $themeNode.get-length('-slider-handle-radius');

    my ($hasHandleColor, $handleBorderColor) =
      $themeNode.lookup_color('-slider-handle-border-color', False);

    my $ceilHandleRadius = ($handleRadius + $handleBorderWidth).ceiling;

    my $handleX = $ceilHandleRadius + ($width - 2 * $ceilHandleRadius) *
      self.value / self.max-value;

    my $handleY = $height / 2;

    $cr.set-source-color($themeNode.get-foreground-color);
    $cr.arc($handleX, $handleY, $handleRadius, 0, 2 * π);
    $cr.fillPreserve;
    if $hasHandleColor && $handleBorderWidth {
      $cr.set-source-color($handleBorderColor);
      $cr.line-width = $handleBorderWidth;
      $cr.stroke
    }
    $cr.dispose
  }

  method button-press-event is vfunc {
    self.startDragging(Clutter::Event.get-current-event);
  }

  method startDragging ($event) {
    return CLUTTER_EVENT_PROPAGATE if $!dragging;

    $!dragging = True;

    self.grab = UI<Global>.stage.grab(self);

    ($!grabbedDevice, $!grabbedSequence) = ( .device, .event-sequence)
      given $event;

    self.emit('drag-begin');

    self.moveHandle( |$event.get-coords );
    CLUTTER_EVENT_STOP;
  }

  # cw: -YYY- STOPPED 2023-04-25 -- pick
  method end-dragging {
    if $!dragging {
      self.disconnect($!releaseId) if $!releaseId;

      if $!grab {
        $!grab.dismiss;
        $!grab = Nil;
      }

      $!grabbedSequence = $!grabbedDevice = $!dragging = Nil;

      self.emit('drag-end');
    }
    return CLUTTER_EVENT_STOP;
  }

  method touch-event is vfunc {
    my $event    = Clutter::Event.get-current-event;
    my $sequence = $event.get-event-sequence;

    if $!dragging && $event.type == CLUTTER_EVENT_TOUCH_BEGIN {
      self.startDragging($event);
      return CLUTTER_EVENT_STOP;
    } elsif $!grabbedSequence  &&
            $sequence.get-slot == $!grabbedSequence.get-slot
    {
      if $event.type == CLUTTER_EVENT_TOUCH_UPDATE {
        return $!motionEvent(self, $event);
      } elsif $event.type == CLUTTER_EVENT_TOUCH_END {
        return self.endDragging
      }
    }

    return CLUTTER_EVENT_PROPAGATE
  }

  method scroll ($event) {
    my $delta;
    my $direction = $event.get-scroll-direction;

    return CLUTTER_EVENT_PROPAGATE if $event.is-pointer-emulated;

    given $direction {
      when CLUTTER_SCROLL_DIRECTION_DOWN   { $delta = -SLIDER_SCROLL_STEP }
      when CLUTTER_SCROLL_DIRECTION_UP     { $delta =  SLIDER_SCROLL_STEP }

      when CLUTTER_SCROLL_DIRECTION_SMOOTH {
        my ($, $dy) = $event.get-scroll-delta;

        # even though the slider is horizontal, use $dy to match the
        # UP/DOWN above.
        $delta = -$dy * SLIDER_SCROLL_STEP;
      }

      self.value = min( max(0, self.value + $delta), self.max-value );

      return CLUTTER_EVENT_STOP;
    }
  }

  method scroll-event is vfunc {
    self.scroll(Clutter::Event.get-current-event);
  }

  method motionEvent ($actor, $event) {
    self.moveHandle( |$event.get-coords );

    return CLUTTER_EVENT_STOP
  }

  method key-press-event ($keyPressEvent) is vfunc {
    my $key = $keyPressEvent.keyval;

    if $key == (CLUTTER_KEY_Right, CLUTTER_KEY_Left).any {
      my $delta = $key == CLUTTER_KEY_Right ?? 0.1 !! - 0.1
      self.value = max( 0, min(self.value + delta, self.max-value) )
      return CLUTTER_EVENT_STOP
    }

    nextsame;
  }

  method moveHandle ($absX, $absY) {
    my $sliderX = self.get-transformed-position;
    my $relX    = $absX - $sliderX;

    my $width        = self.barLevelWidth;
    my $handleRadius = self.get-theme-node.get-length('-slider-handle-radius');

    my $newvalue = do if $relX < $handleRadius {
      0;
    } else if $relX > $width - $handleRadius {
      1;
    } else {
      ( $relX - $handleRadius ) / ($width - 2 * $handleRadius);
    }

    $self.value = $newvalue * self.max-value;
  }

  method getMinimumIncrement {
    0.1;
  }

}
