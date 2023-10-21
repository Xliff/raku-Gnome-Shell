use v6.c;

use Cairo;

use Mutter::Clutter::Cairo;
#use Gnome::Shell::UI::DrawingArea;
use Gnome::Shell::UI::Main;

use GLib::Roles::Object;

### /home/cbwood/Projects/gnome-shell/js/ui/pointerA11yTimeout.js

class Gnome::Shell::UI::PieTimer is Gnome::Shell::UI::DrawingArea {
  has $!angle;

  submethod BUILD {
    $!angle = 0;
    ( .style-class, .opacity ) = ( 'pie-timer', 0 ) given self;
    .visible = .can-focus = .reactive = False       given self;
    self.set-pivot-point(0.5, 0.5);
  }

  method angle is rw {
    Proxy.new:
      FETCH => -> $ { $!angle },
      STORE => -> $, Num \a {
        return unless $!angle != a;

        if a ~~ 0 .. 2 * π {
          $!angle = a;
          self.emit('notify::angle');
          self.queue-repaint;
        } else {
          warn 'angle attribute only accepts values from 0 to 2π'
        }
      }
  }

  method repaint is vfunc {
    my $node = self.get-theme-node;

    my  $backgroundColor = $node.get-color('-pie-background-color');
    my  $borderColor     = $node.get-color('-pie-border-color');
    my  $borderWidth     = $node.get-length('-pie-border-width');
    my ($w, $h)          = self.get-surface-size;
    my  $radius          = ($w, $h).min / 2;

    my $startAngle = 3 * π / 2;
    my $endAngle   = $startAngle + $!angle;

    my $cr = self.get-context();
    $cr.set_line_cap(CAIRO_LINE_CAP_ROUND);
    $cr.set_line_join(CAIRO_LINE_JOIN_ROUND);
    $cr.translate($w / 2, $h / 2);

    $cr.move_to(0, 0) if $!angle < 2 * π;
    $cr.arc(0, 0, $radius - $borderWidth, $startAngle, $endAngle);
    $cr.line_to(0, 0) if $!angle < 2 * π;

    $cr.close_path;

    $cr.set_line_width(0);
    $cr.clutter_set_source_color($backgroundColor);
    $cr.fill( :preserve );

    $cr.set_line_width($borderWidth);
    $cr.clutter_set_source_color($borderColor);
    $cr.stroke;

    $cr.dispose
  }

  method start ($x, $y, $duration) {
      $!x = $!x - $!width  / 2;
    $!y = $!y - $!height / 2;
    self.show;

    self.ease(
      opacity => 255,
      $duration / 4,
      CLUTTER_EASE_IN_QUAD
    );

    # See if there is a way to ease arbitrary value and not a g-property!
    self.ease_property(
      'angle',
      2 * π,
      $duration,
      CLUTTER_EASE_IN_QUAD,
      -> *@a { self.onTransitionComplete }
    );
  }

  method onTransitionComplete {
    self.ease(
      scale-x => 2,
      scale-y => 2,
      opacity => 0,
      SUCCESS_ZOOM_OUT_DURATION,
      CLUTTER_EASE_IN_QUAD,
      onStopped => { self.destroy }
    )
  }
}

class Gnome::Shell::UI::PointerA11yTimeout {d
  has $!pieTimer;

  submethod BUILD {
    my $seat = Mutter::Clutter::Backend.get-default-backend.get-default-seat;

    my $pt := $!pieTimer;
    $seat.ptr-a11y-timeout-started.tap( -> *@a ($, $, $type, $timeout) {
      my ($x, $y) = global.get-pointer;

      $pt = Gnome::Shell::UI::PieTimer.new;
      UI<uiGroup>.add-actor($pt);
      UI<uiGroup>.set-child-above-sibling($pt);
      $pt.start($x, $y, $timeout);
      global.display.set-cursor(META_CURSOR_CROSSHAIR)
        if $type == CLUTTER_POINTER_A11Y_TIMEOUT_TYPE_GESTURE;
    });

    $seat.ptr-a11y-timeout-stopped.tap( -> *@a ($, $, $type, $clicked) {
      $pt.destroy unless $clicked;

      global.display.set-cursor(META_CURSOR_DEFAULT)
        if $type == CLUTTER_POINTER_A11Y_TIMEOUT_TYPE_GESTURE;
    });
  }
}
