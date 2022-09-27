use v6.c;

use NativeCall;
use Method::Also;

use Gnome::Shell::Raw::Types;

use Mutter::Clutter::Effect;

use GLib::Roles::Implementor;

our subset ShellInvertLightnessEffectAncestry is export of Mu
  where ShellInvertLightnessEffect | MutterClutterEffectAncestry;

class Gnome::Shell::InvertLightnessEffect is Mutter::Clutter::Effect {
  has ShellInvertLightnessEffect $!sile is implementor;

  submethod BUILD ( :$shell-invert-light ) {
    self.setShellInvertLightnessEffect($shell-invert-light)
      if $shell-invert-light
  }

  method setShellInvertLightnessEffect (
    ShellInvertLightnessEffectAncestry $_
  ) {
    my $to-parent;

    $!sile = do {
      when ShellInvertLightnessEffect {
        $to-parent = cast(MutterClutterEffect, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellInvertLightnessEffect, $_);
      }
    }
    self.setMutterClutterEffect($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::ShellInvertLightnessEffect
    is also<ShellInvertLightnessEffect>
  { $!sile }

  multi method new (
    ShellInvertLightnessEffectAncestry  $shell-invert-light,
                                       :$ref                 = True
  ) {
    return unless $shell-invert-light;

    my $o = self.bless( :$shell-invert-light );
    $o.ref if $ref;
    $o;
  }
  multi method new {
    my $shell-invert-light = shell_invert_lightness_effect_new();

    $shell-invert-light ?? self.bless( :$shell-invert-light ) !! Nil;
  }

  method get_type {
    state ($n, $t);

    unstable_get_type(
      self.^name,
      &shell_invert_lightness_effect_get_type(),
      $n,
      $t
    );
  }

}

### /home/cbwood/Projects/gnome-shell/src/shell-invert-lightness-effect.h

sub shell_invert_lightness_effect_get_type ()
  returns GType
  is native(gnome-shell)
  is export
{ * }

sub shell_invert_lightness_effect_new ()
  returns MutterClutterEffect
  is native(gnome-shell)
  is export
{ * }
