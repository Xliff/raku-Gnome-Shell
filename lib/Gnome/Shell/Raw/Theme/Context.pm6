use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;

unit package Gnome::Shell::Raw::Theme::Context;

### /home/cbwood/Projects/gnome-shell/src/st/st-theme-context.h

sub st_theme_context_get_font (StThemeContext $context)
  returns PangoFontDescription
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_context_get_for_stage (MutterClutterStage $stage)
  returns StThemeContext
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_context_get_root_node (StThemeContext $context)
  returns StThemeNode
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_context_get_scale_factor (StThemeContext $context)
  returns gint
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_context_get_theme (StThemeContext $context)
  returns StTheme
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_context_intern_node (StThemeContext $context, StThemeNode $node)
  returns StThemeNode
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_context_new ()
  returns StThemeContext
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_context_set_font (
  StThemeContext       $context,
  PangoFontDescription $font
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_context_set_theme (StThemeContext $context, StTheme $theme)
  is native(gnome-shell-st)
  is export
{ * }
