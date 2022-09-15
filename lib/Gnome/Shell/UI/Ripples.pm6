use v6.c;

use Gnome::Shell::BoxLayout;

class Gnome::Shell::St::UI::Ripples {
  has $!x;
  has $!y;
  has $!px;
  has $!py;

  has $!ripple1;
  has $!ripple2;
  has $!ripple3;

  has $!stage;

  submethod BUILD ( :$!px, :$!py, :$style-class ) {
    $!x = $!y = 0;

    ($!ripple1, $!ripple2, $!ripple3).map({
      $_ = Gnome::Shell::BoxLayout.new(
        style_class => $style-class,
        opacity     => 0,
        can_focus   => False,
        reactive    => False,
        visible     => False
      )
      .set-pivot-point($!px, $!py);
      $_
    });
  }

  submethod DESTROY {
    ($!ripple1, $!ripple2, $!ripple3)».unref;
  }

  method animRipple (
    $ripple,
    $delay,
    $duration,
    $startScale,
    $startOpacity,
    $finalScale
  ) {
    given $ripple {
      ( .x, .y, .visible, .opacity ) =
        ($!x, $!y, True, 255 * $startOpacity.sqrt);

      .scale-x = .scale-y = $startScale;
      .set-translation( -$!px * .width, -$!py * .height, 0e0 );

      # Transitions need to be converted to proper syntax -- port .setup!
      my $o-t = Mutter::Clutter::PropertyTransition.new(
        'opacity'
        from => .opacity
        to   => 0,
        :$delay,
        :$duration,
        CLUTTER_ANIMATION_MODE_EASE_IN_QUAD
      );

      my $sx-t = Mutter::Clutter::PropertyTransition.new(
        'scale-x',
        from => $startScale,
        to   => $finalScale,
        :$delay,
        :$duration,
        CLUTTER_ANIMATION_MODE_EASE_IN_QUAD
      );
      my $sy-t = Mutter::Clutter::PropertyTransition.new(
        'scale-y',
        from => $startScale,
        to   => $finalScale,
        :$delay,
        :$duration,
        CLUTTER_ANIMATION_MODE_EASE_IN_QUAD
      );
      $sy-t.completed.tap({ $ripple.visible = False });
    }
  }

  method add_to ($stage) {
    die 'Ripples already added' if $!stage;
    $!stage = $stage;
    $!stage.add_child($_) for $!ripple1, $!ripple2, $!ripple3;
  }

  method play ($x, $y) {
    die 'Ripples not added' unless $!stage;

    ($!x, $!y) = ($x, $y);

    for (ClutterActor, $!ripple1, $ripple2, $ripple3).rotor( 2 => -1 ) {
      $!stage.set-child-above-sibling( |.reverse );
    }

    #                          delay  time   scale opacity => scale
    self.animRipple($!ripple1,   0,    830,   0.25,  1.0,     1.5);
    self.animRipple($!ripple2,  50,   1000,   0.0,   0.7,     1.25);
    self.animRipple($!ripple3, 350,   1000,   0.0,   0.3,     1);
  }

}

constant Ripples is export := Gnome::Shell::UI::Ripples;
