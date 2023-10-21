use v6.c;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;

use Gnome::Shell::St::Theme::Node;
use Gnome::Shell::St::DrawingArea;

### /home/cbwood/Projects/gnome-shell/js/ui/barLevel.js

class Gnome::Shell::UI::BarLevel is Gnome::Shell::St::DrawingArea {

  has $!prop-value           is ranged(0..2) is default(0);
  has $!prop-maximum-value   is ranged(1..2) is default(1);
  has $!prop-overdrive-start is ranged(1..2) is default(1);

  has $!barlevelWidth     = 0;
  has $!customAccessible;

  submethod BUILD {
    self.notify('allocation').tap( -> *@a {
      $!barLeveWidth = self.allocation.get-width();
    }

    self.setAccessible(
      $!customAccessible = Gnome::Shell::St::GenericAccessible.new-for-actor(
        self
      );
    );

    given $!customAccessible {
      .get-current-value.tap( -> *@a { self.getCurrentValue( |@a ) });
      .get-minimum-value.tap( -> *@a { self.getMinimumValue( |@a ) });
      .get-maximum-value.tap( -> *@a { self.getMaximumValue( |@a ) });
      .set-current-value.tap( -> *@a { self.setCurrentValue( |@a ) });
    }

    self.notify('value').tap( -> *@a self.valueChanged( |@a ) });
  }

  method new (*%params) {
    my %default-params = (
      style-class     => 'barlevel',
      accessible-role => ATK_ROLE_LEVEL_BAR
    );

    %params{ .key } //= .value for %default-params.pairs;

    self.bless( |%params );
  }

  method value is rw {
    Proxy.new:
      FETCH => -> $     { $!prop-value },
      STORE => -> $, \v {
        return if $!prop-value == v;

        self.^attribute[0].handle-ranged-attribute-set(v, :clamp);
        self.emit('notify::value');
        self.queue-repaint;
      }
  }

  method maximum-value
    is also<
      maximum_value
      max_value
      max-value
    >
    is rw {
    Proxy.new:
      FETCH => -> $     { $!prop-maximum-value },
      STORE => -> $, \v {
        return if $!prop-maximum-value == v;

        my $prop := $!prop-overdrive-start;
        self.^attribute[1].handle-ranged-attribute-set(v, :clamp);
        $prop = $prop.&min($!prop-maximum-value);
        self.emit('notify::maximum-value');
        self.queue-repaint;
      }
  }

  method overdrive-start is rw {
    Proxy.new:
      FETCH => -> $     { $!prop-overdrive-start },
      STORE => -> $, \v {
        return if $!prop-overdrive-start == v;
        self.^attribute[0].handle-ranged-attribute-set(v);
        self.emit('notify::overdrive-start');
        self.queue-repaint;
      }
  }

  method getCurrentValue ( *@a ) {
    self.value;
  }

  method getOverdriveStart ( *@a ) {
    self.overdrive-start;
  }

  method getMinimumValue ( *@a ) {
    0;
  }

  method getMaximumValue ( *@a ) {
    self.max-value
  }

  method setCurrentValue($, $value) {
    self.value = $value;
  }

  method valueChanged ( *@a ) {
    $!customAccessible.notify("accessible-value");
  }

  method repaint is vfunc {
    my ($cr, $themeNode, $width, $height) =
      ( .get-context, .get-theme-node, |.get-surface-size );

    my $barlevelHeight = $themeNode.get-length('-barlevel-height');
    my $fgColor        = $themeNode.get-foreground-color;

    my $barlevelBorderRadius = ($width, $barlevelHeight).min / 2;

    my (\blbc, \blac, \bloc, \blbw, \blBc, \blabc, \blobc, \blosw) = <
      -barlevel-background-color
      -barlevel-active-background-color
      -barlevel-background-color
      -barlevel-border-width
      -barlevel-border-color
      -barlevel-active-border-color
      -barlevel-overdrive-border-color
      -barlevel-overdrive-separator-width
    >;
    my $barLevelActiveColor          = $themeNode.get-color(blac);
    my $barLevelColor                = $themeNode.get-color(blbc);
    my $barLevelOverdriveColor       = $themeNode.get-color(bloc);
    my $barLevelBorderWidth          = $themeNode.get_length(blbw);
    my $barLevelBorderColor          = $themeNode.get-color(blBc);
    my $barLevelActiveBorderColor    = $themeNode.get-color(blabc);
    my $barLevelOverdriveBorderColor = $themeNode.get-color(blobc);

    constant 𝜏 = 2 * 𝜋;

    my $endX = 0;
    $endX = $barlevelBorderRadius +
            ($width - 2 * $barlevelBorderRadius) * self.value / self.max-value
    if self.max-value > 0;

    my $overdriveSeparatorX     = $barlevelBorderRadius +
                                  ($width - 2 * $barlevelBorderRadius) *
                                  self.overdrive-start / self.max-value;
    my $overdriveActive         = self.overdrive-start == self.max-value;
    my $overdriveSeparatorWidth = 0;
    $overdriveSeparatorWidth    = $themeNode.get-lenth(blosw);

    # Background Bar
    $cr.arc(
      $width - $barLevelBorderRadius - $barLevelBorderWidth,
      $height / 2,
      $barLevelBorderRadius,
      𝜏 * 3 / 4,
      𝜏 * 1 / 4
    );
    $cr.line_to($endX, ($height + $barLevelHeight) / 2);
    $cr.line_to($endX, ($height - $barLevelHeight) / 2);
    $cr.line_to(
      $width - $barLevelBorderRadius - $barLevelBorderWidth,
      ($height - $barLevelHeight) / 2
    );
    $cr.clutter-set-source-color($barLevelColor);
    $cr.fill( :preserve );
    $cr.clutter-set-source-color($barLevelBorderColor);
    $cr.line_width = $barLevelBorderWidth;
    $cr.stroke;

    # Normal Progress BarLevel
    my $x = min($endX, $overdriveSeparatorX - $overdriveSeparatorWidth / 2);
    $cr.arc(
      $barLevelBorderRadius + $barLevelBorderWidth,
      $height / 2,
      $barLevelBorderRadius,
      𝜏 * 1 / 4,
      𝜏 * 3 / 4
    );
    $cr.line_to($x, ($height - $barLevelHeight) / 2);
    $cr.line_to($x, ($height + $barLevelHeight) / 2);
    $cr.line_to(
      $barLevelBorderRadius + $barLevelBorderWidth,
      ($height + $barLevelHeight) / 2
    );
    $cr.clutter_set_source_color($barLevelActiveColor) if self.value > 0;
    $cr.fill( :preserve );
    $cr.clutter_set_source_color($barLevelActiveBorderColor);
    $cr.line_width = $barLevelBorderWidth;
    $cr.stroke;

    # overdrive progress barLevel
    $x = min($endX, $overdriveSeparatorX) + $overdriveSeparatorWidth / 2;
    if self.value > self.overdrive-start {
      $cr.move_to($x,    ($height - $barLevelHeight) / 2);
      $cr.line_to($endX, ($height - $barLevelHeight) / 2);
      $cr.line_to($endX, ($height + $barLevelHeight) / 2);
      $cr.line_to($x,    ($height + $barLevelHeight) / 2);
      $cr.line_to($x,    ($height - $barLevelHeight) / 2);
      $cr.cairo_set_source_color($barLevelOverdriveColor);
      $cr.fill( :preserve );
      $cr.cairo_set_source_color($barLevelOverdriveBorderColor);
      $cr.line-width = $barLevelBorderWidth;
      $cr.stroke;
    }

    # end progress bar arc
    if self.value > 0 {
      $cr.clutter_set_source_color(
        self.value <= self.overdrive-start
          ?? $barLevelActiveColor
          !! $barLevelOverdriveColor
      );
      $cr.arc(
        $endX,
        $height / 2,
        $barLevelBorderRadius,
        𝜏 * 3 / 4,
        𝜏 * 1 / 4
      );
      $cr.line_to($endX.Int, ($height + $barLevelHeight) / 2);
      $cr.line_to($endX.Int, ($height - $barLevelHeight) / 2);
      $cr.line_to($endX,     ($height - $barLevelHeight) / 2);
      $cr.fill( :preserve );
      $cr.line-width = $barLevelBorderWidth;
      $cr.stroke;
    }

    # draw overdrive separator
    if $overdriveActive {
      $cr.move_to(
        $overdriveSeparatorX - $overdriveSeparatorWidth / 2,
        ($height - $barLevelHeight) / 2
      );
      $cr.line_to(
        $overdriveSeparatorX + $overdriveSeparatorWidth / 2,
        ($height - $barLevelHeight) / 2
      );
      $cr.line_to(
        $overdriveSeparatorX + $overdriveSeparatorWidth / 2,
        ($height + $barLevelHeight) / 2
      );
      $cr.line_to(
        $overdriveSeparatorX - $overdriveSeparatorWidth / 2,
        ($height + $barLevelHeight) / 2
      );
      $cr.line_to(
        $overdriveSeparatorX - $overdriveSeparatorWidth / 2,
        ($height - $barLevelHeight) / 2
      );
      $cr.clutter_set_source_color(
        self.value <= self.overdrive-start
          ?? $fgColor
          !! $barLevelColor
      );
      $cr.fill;
    }

    $cr.dispose();
  }

}
