use v6.c;

use GLib::Raw::Definitions;
use GLib::Raw::Enums;
use Pango::Raw::Enums;

unit package Gnome::Shell::Raw::Enums;

constant AddSelectorType is export := guint32;
our enum AddSelectorTypeEnum is export (
  NO_ADD_SELECTOR           =>        0,
  CLASS_ADD_SELECTOR        =>        1,
  PSEUDO_CLASS_ADD_SELECTOR => 1  +<  1,
  ID_ADD_SELECTOR           => 1  +<  3,
  ATTRIBUTE_ADD_SELECTOR    => 1  +<  4,
);

constant AttrMatchWay is export := guint32;
our enum AttrMatchWayEnum is export (
  NO_MATCH  => 0,
  'SET',
  'EQUALS',
  'INCLUDES',
  'DASHMATCH'
);

constant Combinator is export := guint32;
our enum CombinatorEnum is export <
  NO_COMBINATOR
  COMB_WS
  COMB_PLUS
  COMB_GT
>;

constant DisplayFormat is export := guint32;
our enum DisplayFormatEnum is export <
  DISPLAY_ONELINE
  DISPLAY_DETAILED
>;

constant ExtensionState is export := guint32;
our enum ExtensionStateEnum is export (
  STATE_ENABLED     =>  1,
  'STATE_DISABLED',
  'STATE_ERROR',
  'STATE_OUT_OF_DATE',
  'STATE_DOWNLOADING',
  'STATE_INITIALIZED',
  STATE_UNINSTALLED => 99,
);

constant ExtensionType is export := guint32;
our enum ExtensionTypeEnum is export (
  TYPE_SYSTEM => 1,
  'TYPE_USER'
);

constant ShellAppLaunchGpu is export := guint32;
our enum ShellAppLaunchGpuEnum is export (
  SHELL_APP_LAUNCH_GPU_APP_PREF => 0,
  'SHELL_APP_LAUNCH_GPU_DISCRETE',
  'SHELL_APP_LAUNCH_GPU_DEFAULT'
);

constant ShellAppState is export := guint32;
our enum ShellAppStateEnum is export <
  SHELL_APP_STATE_STOPPED
  SHELL_APP_STATE_STARTING
  SHELL_APP_STATE_RUNNING
>;

constant ShellBlurMode is export := guint32;
our enum ShellBlurModeEnum is export <
  SHELL_BLUR_MODE_ACTOR
  SHELL_BLUR_MODE_BACKGROUND
>;

constant ShellNetworkAgentResponse is export := guint32;
our enum ShellNetworkAgentResponseEnum is export <
  SHELL_NETWORK_AGENT_CONFIRMED
  SHELL_NETWORK_AGENT_USER_CANCELED
  SHELL_NETWORK_AGENT_INTERNAL_ERROR
>;

constant ShellSnippetHook is export := guint32;
our enum ShellSnippetHookEnum is export (
  SHELL_SNIPPET_HOOK_VERTEX                  =>    0,
  'SHELL_SNIPPET_HOOK_VERTEX_TRANSFORM',
  SHELL_SNIPPET_HOOK_FRAGMENT                => 2048,
  SHELL_SNIPPET_HOOK_TEXTURE_COORD_TRANSFORM => 4096,
  SHELL_SNIPPET_HOOK_LAYER_FRAGMENT          => 6144,
  'SHELL_SNIPPET_HOOK_TEXTURE_LOOKUP'
);

constant SimpleSelectorType is export := guint32;
our enum SimpleSelectorTypeEnum is export (
  NO_SELECTOR_TYPE   =>        0,
  UNIVERSAL_SELECTOR =>        1,
  TYPE_SELECTOR      => 1  +<  1,
);

constant StAlign is export := guint32;
our enum StAlignEnum is export <
  ST_ALIGN_START
  ST_ALIGN_MIDDLE
  ST_ALIGN_END
>;

constant StBackgroundSize is export := guint32;
our enum StBackgroundSizeEnum is export <
  ST_BACKGROUND_SIZE_AUTO
  ST_BACKGROUND_SIZE_CONTAIN
  ST_BACKGROUND_SIZE_COVER
  ST_BACKGROUND_SIZE_FIXED
>;

constant StButtonMask is export := guint32;
our enum StButtonMaskEnum is export (
  ST_BUTTON_ONE   => (1  +<  0),
  ST_BUTTON_TWO   => (1  +<  1),
  ST_BUTTON_THREE => (1  +<  2),
);

constant StClipboardType is export := guint32;
our enum StClipboardTypeEnum is export <
  ST_CLIPBOARD_TYPE_PRIMARY
  ST_CLIPBOARD_TYPE_CLIPBOARD
>;

constant StCorner is export := guint32;
our enum StCornerEnum is export <
  ST_CORNER_TOPLEFT
  ST_CORNER_TOPRIGHT
  ST_CORNER_BOTTOMRIGHT
  ST_CORNER_BOTTOMLEFT
>;

constant StDirectionType is export := guint32;
our enum StDirectionTypeEnum is export <
  ST_DIR_TAB_FORWARD
  ST_DIR_TAB_BACKWARD
  ST_DIR_UP
  ST_DIR_DOWN
  ST_DIR_LEFT
  ST_DIR_RIGHT
>;

constant StGradientType is export := guint32;
our enum StGradientTypeEnum is export <
  ST_GRADIENT_NONE
  ST_GRADIENT_VERTICAL
  ST_GRADIENT_HORIZONTAL
  ST_GRADIENT_RADIAL
>;

constant StIconStyle is export := guint32;
our enum StIconStyleEnum is export <
  ST_ICON_STYLE_REQUESTED
  ST_ICON_STYLE_REGULAR
  ST_ICON_STYLE_SYMBOLIC
>;

constant StPolicyType is export := guint32;
our enum StPolicyTypeEnum is export <
  ST_POLICY_ALWAYS
  ST_POLICY_AUTOMATIC
  ST_POLICY_NEVER
  ST_POLICY_EXTERNAL
>;

constant StSide is export := guint32;
our enum StSideEnum is export <
  ST_SIDE_TOP
  ST_SIDE_RIGHT
  ST_SIDE_BOTTOM
  ST_SIDE_LEFT
>;

constant StTextAlign is export := guint32;
our enum StTextAlignEnum is export (
  ST_TEXT_ALIGN_LEFT    =>   PANGO_ALIGN_LEFT,
  ST_TEXT_ALIGN_CENTER  => PANGO_ALIGN_CENTER,
  ST_TEXT_ALIGN_RIGHT   =>  PANGO_ALIGN_RIGHT,
  'ST_TEXT_ALIGN_JUSTIFY'
);

constant StTextDecoration is export := guint32;
our enum StTextDecorationEnum is export (
  ST_TEXT_DECORATION_UNDERLINE    => 1  +<  0,
  ST_TEXT_DECORATION_OVERLINE     => 1  +<  1,
  ST_TEXT_DECORATION_LINE_THROUGH => 1  +<  2,
  ST_TEXT_DECORATION_BLINK        => 1  +<  3,
);

constant StTextureCachePolicy is export := guint32;
our enum StTextureCachePolicyEnum is export <
  ST_TEXTURE_CACHE_POLICY_NONE
  ST_TEXTURE_CACHE_POLICY_FOREVER
>;

constant UnaryOperator is export := guint32;
our enum UnaryOperatorEnum is export (
  NO_UNARY_UOP    => 0,
  'PLUS_UOP',
  'MINUS_UOP',
  'EMPTY_UNARY_UOP'
);
