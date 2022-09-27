use v6.c;

use Method::Also;

use NativeCall;

use Gnome::Shell::Raw::Types;

use Mutter::Clutter::OffscreenEffect;

use GLib::Roles::Implementor;

our subset ShellGLSLEffectAncestry is export of Mu
  where ShellGLSLEffect | MutterClutterOffscreenEffectAncestry;

class Gnome::Shell::GLSLEffect is Mutter::Clutter::OffscreenEffect {
  has ShellGLSLEffect $!sge is implementor;

  submethod BUILD ( :$shell-glsl-effect ) {
    self.setShellGLSLEffect($shell-glsl-effect) if $shell-glsl-effect
  }

  method setShellGLSLEffect (ShellGLSLEffectAncestry $_) {
    my $to-parent;

    $!sge = do {
      when ShellGLSLEffect {
        $to-parent = cast(MutterClutterOffscreenEffect, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellGLSLEffect, $_);
      }
    }
    self.setMutterClutterOffscreenEffect($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::ShellGLSLEffect
    is also<ShellGLSLEffect>
  { $!sge }

  multi method new (ShellGLSLEffectAncestry $shell-glsl-effect, :$ref = True) {
    return unless $shell-glsl-effect;

    my $o = self.bless( :$shell-glsl-effect );
    $o.ref if $ref;
    $o;
  }

  method add_glsl_snippet (
    ShellSnippetHook() $hook,
    Str()              $declarations,
    Str()              $code,
    Int()              $is_replace
  )
    is also<add-glsl-snippet>
  {
    my gboolean $i = $is_replace;

    shell_glsl_effect_add_glsl_snippet($!sge, $hook, $declarations, $code, $i);
  }

  method get_uniform_location (Str() $name) is also<get-uniform-location> {
    shell_glsl_effect_get_uniform_location($!sge, $name);
  }

  proto method set_uniform_float (|)
    is also<set-uniform-float>
  { * }

  multi method set_uniform_float (
    Int()  $uniform,
    Int()  $total_count,
           @value,
          :$size         = @value.elems
  ) {
    samewith(
      $uniform,
      $size,
      $total_count,
      ArrayToCArray(gfloat, @value, :$size)
    );
  }
  multi method set_uniform_float (
    Int()          $uniform,
    Int()          $n_components,
    Int()          $total_count,
    CArray[gfloat] $value
  ) {
    my gint ($y, $n, $t) = ($uniform, $n_components, $total_count);

    shell_glsl_effect_set_uniform_float(
      $!sge,
      $uniform,
      $n_components,
      $total_count,
      $value
    );
  }

  proto method set_uniform_matrix (|)
    is also<set-uniform-matrix>
  { * }

  multi method set_uniform_matrix (
    Int()  $uniform,
    Int()  $transpose,
    Int()  $dimensions,
           @value,
    Int() :total_count(:total-count(:$size)) = @value.elems
  ) {
    samewith(
      $uniform,
      $transpose,
      $dimensions,
      $size,
      ArrayToCArray(gfloat, @value, :$size)
    )
  }
  multi method set_uniform_matrix (
    Int() $uniform,
    Int() $transpose,
    Int() $dimensions,
    Int() $total_count,
    Pointer $value
  ) {
    my gint     ($u, $d, $t) = ($uniform, $dimensions, $total_count);
    my gboolean  $tr         =  $transpose.so.Int;

    shell_glsl_effect_set_uniform_matrix($!sge, $u, $tr, $d, $t, $value);
  }

}

### /home/cbwood/Projects/gnome-shell/src/shell-glsl-effect.h

sub shell_glsl_effect_add_glsl_snippet (
  ShellGLSLEffect  $effect,
  ShellSnippetHook $hook,
  Str              $declarations,
  Str              $code,
  gboolean         $is_replace
)
  is native(gnome-shell)
  is export
{ * }

sub shell_glsl_effect_get_uniform_location (ShellGLSLEffect $effect, Str $name)
  returns gint
  is native(gnome-shell)
  is export
{ * }

sub shell_glsl_effect_set_uniform_float (
  ShellGLSLEffect $effect,
  gint            $uniform,
  gint            $n_components,
  gint            $total_count,
  gfloat          $value          is rw
)
  is native(gnome-shell)
  is export
{ * }

sub shell_glsl_effect_set_uniform_matrix (
  ShellGLSLEffect $effect,
  gint            $uniform,
  gboolean        $transpose,
  gint            $dimensions,
  gint            $total_count,
  gfloat          $value is rw
)
  is native(gnome-shell)
  is export
{ * }
