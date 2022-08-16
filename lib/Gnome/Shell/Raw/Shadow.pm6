use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;

unit package Gnome::Shell::Raw::Shadow;

### /home/cbwood/Projects/gnome-shell/src/st/st-shadow.h

sub st_shadow_equal (StShadow $shadow, StShadow $other)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_shadow_get_box (
  StShadow              $shadow,
  MutterClutterActorBox $actor_box,
  MutterClutterActorBox $shadow_box
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_shadow_get_type ()
  returns GType
  is native(gnome-shell-st)
  is export
{ * }

sub st_shadow_helper_copy (StShadowHelper $helper)
  returns StShadowHelper
  is native(gnome-shell-st)
  is export
{ * }

sub st_shadow_helper_free (StShadowHelper $helper)
  is native(gnome-shell-st)
  is export
{ * }

sub st_shadow_helper_get_type ()
  returns GType
  is native(gnome-shell-st)
  is export
{ * }

sub st_shadow_helper_new (StShadow $shadow)
  returns StShadowHelper
  is native(gnome-shell-st)
  is export
{ * }

sub st_shadow_helper_paint (
  StShadowHelper        $helper,
  MutterCoglFramebuffer $framebuffer,
  MutterClutterActorBox $actor_box,
  guint8                $paint_opacity
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_shadow_helper_update (
  StShadowHelper     $helper,
  MutterClutterActor $source
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_shadow_new (
  MutterClutterColor $color,
  gdouble            $xoffset,
  gdouble            $yoffset,
  gdouble            $blur,
  gdouble            $spread,
  gboolean           $inset
)
  returns StShadow
  is native(gnome-shell-st)
  is export
{ * }

sub st_shadow_ref (StShadow $shadow)
  returns StShadow
  is native(gnome-shell-st)
  is export
{ * }

sub st_shadow_unref (StShadow $shadow)
  is native(gnome-shell-st)
  is export
{ * }
