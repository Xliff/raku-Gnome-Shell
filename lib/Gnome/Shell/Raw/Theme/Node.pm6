use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;
use Gnome::Shell::Raw::Enums;

unit package Gnome::Shell::Raw::Theme::Node;

### /home/cbwood/Projects/gnome-shell/src/st/st-theme-node.h

sub st_theme_node_adjust_for_height (
  StThemeNode $node,
  gfloat      $for_height is rw
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_adjust_for_width (
  StThemeNode $node,
  gfloat      $for_width is rw
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_adjust_preferred_height (
  StThemeNode $node,
  gfloat      $min_height_p     is rw,
  gfloat      $natural_height_p is rw
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_adjust_preferred_width (
  StThemeNode $node,
  gfloat      $min_width_p     is rw,
  gfloat      $natural_width_p is rw
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_equal (StThemeNode $node_a, StThemeNode $node_b)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_geometry_equal (StThemeNode $node, StThemeNode $other)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_background_color (
  StThemeNode        $node,
  MutterClutterColor $color
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_background_gradient (
  StThemeNode        $node,
  StGradientType     $type   is rw,
  MutterClutterColor $start,
  MutterClutterColor $end
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_background_image (StThemeNode $node)
  returns GFile
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_background_image_shadow (StThemeNode $node)
  returns StShadow
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_background_paint_box (
  StThemeNode           $node,
  MutterClutterActorBox $allocation,
  MutterClutterActorBox $paint_box
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_border_color (
  StThemeNode        $node,
  StSide             $side,
  MutterClutterColor $color
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_border_image (StThemeNode $node)
  returns StBorderImage
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_border_radius (StThemeNode $node, StCorner $corner)
  returns gint
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_border_width (StThemeNode $node, StSide $side)
  returns gint
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_box_shadow (StThemeNode $node)
  returns StShadow
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_color (
  StThemeNode        $node,
  Str                $property_name,
  MutterClutterColor $color
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_content_box (
  StThemeNode           $node,
  MutterClutterActorBox $allocation,
  MutterClutterActorBox $content_box
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_double (StThemeNode $node, Str $property_name)
  returns gdouble
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_element_classes (StThemeNode $node)
  returns GStrv
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_element_id (StThemeNode $node)
  returns Str
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_element_type (StThemeNode $node)
  returns GType
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_font (StThemeNode $node)
  returns PangoFontDescription
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_font_features (StThemeNode $node)
  returns Str
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_foreground_color (
  StThemeNode        $node,
  MutterClutterColor $color
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_height (StThemeNode $node)
  returns gint
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_horizontal_padding (StThemeNode $node)
  returns double
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_icon_colors (StThemeNode $node)
  returns StIconColors
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_icon_style (StThemeNode $node)
  returns StIconStyle
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_length (StThemeNode $node, Str $property_name)
  returns gdouble
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_letter_spacing (StThemeNode $node)
  returns double
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_margin (StThemeNode $node, StSide $side)
  returns double
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_max_height (StThemeNode $node)
  returns gint
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_max_width (StThemeNode $node)
  returns gint
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_min_height (StThemeNode $node)
  returns gint
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_min_width (StThemeNode $node)
  returns gint
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_outline_color (
  StThemeNode        $node,
  MutterClutterColor $color
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_outline_width (StThemeNode $node)
  returns gint
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_padding (StThemeNode $node, StSide $side)
  returns double
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_paint_box (
  StThemeNode           $node,
  MutterClutterActorBox $allocation,
  MutterClutterActorBox $paint_box
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_parent (StThemeNode $node)
  returns StThemeNode
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_pseudo_classes (StThemeNode $node)
  returns GStrv
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_shadow (StThemeNode $node, Str $property_name)
  returns StShadow
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_text_align (StThemeNode $node)
  returns StTextAlign
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_text_decoration (StThemeNode $node)
  returns StTextDecoration
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_text_shadow (StThemeNode $node)
  returns StShadow
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_theme (StThemeNode $node)
  returns StTheme
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_transition_duration (StThemeNode $node)
  returns gint
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_url (StThemeNode $node, Str $property_name)
  returns GFile
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_vertical_padding (StThemeNode $node)
  returns double
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_get_width (StThemeNode $node)
  returns gint
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_hash (StThemeNode $node)
  returns guint
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_invalidate_background_image (StThemeNode $node)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_invalidate_border_image (StThemeNode $node)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_lookup_color (
  StThemeNode        $node,
  Str                $property_name,
  gboolean           $inherit,
  MutterClutterColor $color
)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_lookup_double (
  StThemeNode $node,
  Str         $property_name,
  gboolean    $inherit,
  gdouble     $value is rw
)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_lookup_length (
  StThemeNode $node,
  Str         $property_name,
  gboolean    $inherit,
  gdouble     $length is rw
)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_lookup_shadow (
  StThemeNode      $node,
  Str              $property_name,
  gboolean         $inherit,
  CArray[StShadow] $shadow
)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_lookup_time (
  StThemeNode $node,
  Str         $property_name,
  gboolean    $inherit,
  gdouble     $value is rw
)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_lookup_url (
  StThemeNode   $node,
  Str           $property_name,
  gboolean      $inherit,
  CArray[GFile] $file
)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_new (
  StThemeContext $context,
  StThemeNode    $parent_node,
  StTheme        $theme,
  GType          $element_type,
  Str            $element_id,
  Str            $element_class,
  Str            $pseudo_class,
  Str            $inline_style
)
  returns StThemeNode
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_paint (
  StThemeNode           $node,
  StThemeNodePaintState $state,
  MutterCoglFramebuffer $framebuffer,
  MutterClutterActorBox $box,
  guint8                $paint_opacity,
  gfloat                $resource_scale
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_paint_equal (StThemeNode $node, StThemeNode $other)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_paint_state_copy (
  StThemeNodePaintState $state,
  StThemeNodePaintState $other
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_paint_state_free (StThemeNodePaintState $state)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_paint_state_init (StThemeNodePaintState $state)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_paint_state_invalidate (StThemeNodePaintState $state)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_paint_state_invalidate_for_file (
  StThemeNodePaintState $state,
  GFile                 $file
)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_paint_state_set_node (
  StThemeNodePaintState $state,
  StThemeNode           $node
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_to_string (StThemeNode $node)
  returns Str
  is native(gnome-shell-st)
  is export
{ * }
