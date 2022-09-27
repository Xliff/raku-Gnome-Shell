use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;
use Gnome::Shell::Raw::Enums;

unit package Gnome::Shell::Raw::BlurEffect;

### /home/cbwood/Projects/gnome-shell/src/shell-blur-effect.h

sub shell_blur_effect_get_brightness (ShellBlurEffect $self)
  returns gfloat
  is      native(gnome-shell)
  is      export
{ * }

sub shell_blur_effect_get_mode (ShellBlurEffect $self)
  returns ShellBlurMode
  is      native(gnome-shell)
  is      export
{ * }

sub shell_blur_effect_get_sigma (ShellBlurEffect $self)
  returns gint
  is      native(gnome-shell)
  is      export
{ * }

sub shell_blur_effect_new ()
  returns ShellBlurEffect
  is      native(gnome-shell)
  is      export
{ * }

sub shell_blur_effect_set_brightness (
  ShellBlurEffect $self,
  gfloat          $brightness
)
  is native(gnome-shell)
  is export
{ * }

sub shell_blur_effect_set_mode (ShellBlurEffect $self, ShellBlurMode $mode)
  is native(gnome-shell)
  is export
{ * }

sub shell_blur_effect_set_sigma (ShellBlurEffect $self, gint $sigma)
  is native(gnome-shell)
  is export
{ * }
