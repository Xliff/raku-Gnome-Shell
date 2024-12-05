use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Croco::Raw::Definitions;
use Croco::Raw::Enums;
use Croco::Raw::Structs;
use Gnome::Shell::Raw::Definitions;

unit package Croco::Raw::RGB;

### /home/cbwood/Projects/gnome-shell-st/src/st/croco/cr-rgb.h

sub cr_rgb_compute_from_percentage (CRRgb $a_this)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_rgb_copy (
  CRRgb $a_dest,
  CRRgb $a_src
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_rgb_destroy (CRRgb $a_this)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_rgb_dump (
  CRRgb    $a_this,
  gpointer $a_fp
)
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_rgb_new
  returns CRRgb
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_rgb_new_with_vals (
  gulong   $a_red,
  gulong   $a_green,
  gulong   $a_blue,
  gboolean $a_is_percentage
)
  returns CRRgb
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_rgb_parse_from_buf (
  Str        $a_str,
  CREncoding $a_enc
)
  returns CRRgb
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_rgb_set (
  CRRgb    $a_this,
  gulong   $a_red,
  gulong   $a_green,
  gulong   $a_blue,
  gboolean $a_is_percentage
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_rgb_set_from_hex_str (
  CRRgb $a_this,
  Str   $a_hex_value
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_rgb_set_from_name (
  CRRgb $a_this,
  Str   $a_color_name
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_rgb_set_from_rgb (
  CRRgb $a_this,
  CRRgb $a_rgb
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_rgb_set_from_term (
  CRRgb   $a_this,
  CRTerm  $a_value
)
  returns CRStatus
  is      native(gnome-shell-st)
  is      export
{ * }

sub cr_rgb_to_string (CRRgb $a_this)
  returns Str
  is      native(gnome-shell-st)
  is      export
{ * }

our @croco-css2-colors is export = <
  aliceblue            antiquewhite         aqua
  aquamarine           azure                beige
  bisque               black                blanchedalmond
  blue                 blueviolet           brown
  burlywood            cadetblue            chartreuse
  chocolate            coral                cornflowerblue
  cornsilk             crimson              cyan
  darkblue             darkcyan             darkgoldenrod
  darkgray             darkgreen            darkgrey
  darkkhaki            darkmagenta          darkolivegreen
  darkorange           darkorchid           darkred
  darksalmon           darkseagreen         darkslateblue
  darkslategray        darkslategrey        darkturquoise
  darkviolet           deeppink             deepskyblue
  dimgray              dimgrey              dodgerblue
  firebrick            floralwhite          forestgreen
  fuchsia              gainsboro            ghostwhite
  gold                 goldenrod            gray
  green                greenyellow          grey
  honeydew             hotpink              indianred
  indigo               ivory                khaki
  lavender             lavenderblush        lawngreen
  lemonchiffon         lightblue            lightcoral
  lightcyan            lightgoldenrodyellow lightgray
  lightgreen           lightgrey            lightpink
  lightsalmon          lightseagreen        lightskyblue
  lightslategray       lightslategrey       lightsteelblue
  lightyellow          lime                 limegreen
  linen                magenta              maroon
  mediumaquamarine     mediumblue           mediumorchid
  mediumpurple         mediumseagreen       mediumslateblue
  mediumspringgreen    mediumturquoise      mediumvioletred
  midnightblue         mintcream            mistyrose
  moccasin             navajowhite          navy
  oldlace              olive                olivedrab
  orange               orangered            orchid
  palegoldenrod        palegreen            paleturquoise
  palevioletred        papayawhip           peachpuff
  peru                 pink                 plum
  powderblue           purple               red
  rosybrown            royalblue            saddlebrown
  salmon               sandybrown           seagreen
  seashell             sienna               silver
  skyblue              slateblue            slategray
  slategrey            snow                 springgreen
  steelblue            tan                  teal
  thistle              tomato               turquoise
  violet               wheat                white
  whitesmoke           yellow               yellowgreen
>;
