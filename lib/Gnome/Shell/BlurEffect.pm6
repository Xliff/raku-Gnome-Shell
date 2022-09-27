use v6.c;

use Method::Also;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::BlurEffect;

use Mutter::Clutter::Effect;

use GLib::Roles::Implementor;

our subset ShellBlurEffectAncestry is export of Mu
  where ShellBlurEffect | MutterClutterEffectAncestry;

class Gnome::Shell::BlurEffect is Mutter::Clutter::Effect {
  has ShellBlurEffect $!sbe is implementor;

  submethod BUILD ( :$shell-blur-effect ) {
    self.setShellBlurEffect($shell-blur-effect) if $shell-blur-effect;
  }

  method setShellBlurEffect (ShellBlurEffectAncestry $_) {
    my $to-parent;

    $!sbe = do {
      when ShellBlurEffect {
        $to-parent = cast(MutterClutterEffect, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellBlurEffect, $_);
      }
    }
    self.setMutterClutterEffect($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::ShellBlurEffect
    is also<ShellBlurEffect>
  { $!sbe }

  multi method new (ShellBlurEffectAncestry $shell-blur-effect, :$ref = True) {
    return unless $shell-blur-effect;

    my $o = self.bless( :$shell-blur-effect );
    $o.ref if $ref;
    $o;
  }
  multi method new {
    my $shell-blur-effect = shell_blur_effect_new();

    $shell-blur-effect ?? self.bless( :$shell-blur-effect ) !! Nil;
  }

  # Type: int
  method sigma is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_INT );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('sigma', $gv);
        $gv.int;
      },
      STORE => -> $, Int() $val is copy {
        $gv.int = $val;
        self.prop_set('sigma', $gv);
      }
    );
  }

  # Type: float
  method brightness is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_FLOAT );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('brightness', $gv);
        $gv.float;
      },
      STORE => -> $, Num() $val is copy {
        $gv.float = $val;
        self.prop_set('brightness', $gv);
      }
    );
  }

  # Type: ShellBlurMode
  method mode is rw  is g-property {
    my $gv = GLib::Value.new( GLib::Value.typeFromEnum(ShellBlurMode) );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('mode', $gv);
        ShellBlurModeEnum( $gv.valueFromEnum(ShellBlurMode) );
      },
      STORE => -> $, Int $val is copy {
        $gv.valueFromEnum(ShellBlurMode) = $val;
        self.prop_set('mode', $gv);
      }
    );
  }

  method get_brightness is also<get-brightness> {
    shell_blur_effect_get_brightness($!sbe);
  }

  method get_mode is also<get-mode> {
    shell_blur_effect_get_mode($!sbe);
  }

  method get_sigma is also<get-sigma> {
    shell_blur_effect_get_sigma($!sbe);
  }

  method set_brightness (Num() $brightness) is also<set-brightness> {
    my gfloat $b = $brightness;

    shell_blur_effect_set_brightness($!sbe, $b);
  }

  method set_mode (Int() $mode) is also<set-mode> {
    my ShellBlurMode $m = $mode;

    shell_blur_effect_set_mode($!sbe, $m);
  }

  method set_sigma (Int() $sigma) is also<set-sigma> {
    my gint $s = $sigma;

    shell_blur_effect_set_sigma($!sbe, $s);
  }

}
