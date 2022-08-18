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

constant CRFontSizeAdjustType is export := guint32;
our enum CRFontSizeAdjustTypeEnum is export (
  FONT_SIZE_ADJUST_NONE    => 0,
  'FONT_SIZE_ADJUST_NUMBER',
  'FONT_SIZE_ADJUST_INHERIT'
);

constant CRFontSizeType is export := guint32;
our enum CRFontSizeTypeEnum is export <
  PREDEFINED_ABSOLUTE_FONT_SIZE
  ABSOLUTE_FONT_SIZE
  RELATIVE_FONT_SIZE
  INHERITED_FONT_SIZE
  NB_FONT_SIZE_TYPE
>;

constant CRFontStretch is export := guint32;
our enum CRFontStretchEnum is export (
  FONT_STRETCH_NORMAL          => 0,
  'FONT_STRETCH_WIDER',
  'FONT_STRETCH_NARROWER',
  'FONT_STRETCH_ULTRA_CONDENSED',
  'FONT_STRETCH_EXTRA_CONDENSED',
  'FONT_STRETCH_CONDENSED',
  'FONT_STRETCH_SEMI_CONDENSED',
  'FONT_STRETCH_SEMI_EXPANDED',
  'FONT_STRETCH_EXPANDED',
  'FONT_STRETCH_EXTRA_EXPANDED',
  'FONT_STRETCH_ULTRA_EXPANDED',
  'FONT_STRETCH_INHERIT'
);

constant CRFontStyle is export := guint32;
our enum CRFontStyleEnum is export (
  FONT_STYLE_NORMAL  => 0,
  'FONT_STYLE_ITALIC',
  'FONT_STYLE_OBLIQUE',
  'FONT_STYLE_INHERIT'
);

constant CRFontVariant is export := guint32;
our enum CRFontVariantEnum is export (
  FONT_VARIANT_NORMAL     => 0,
  'FONT_VARIANT_SMALL_CAPS',
  'FONT_VARIANT_INHERIT'
);

constant CRFontWeight is export := guint32;
our enum CRFontWeightEnum is export (
  FONT_WEIGHT_NORMAL  =>       1,
  FONT_WEIGHT_BOLD    =>  1 +< 1,
  FONT_WEIGHT_BOLDER  =>  1 +< 2,
  FONT_WEIGHT_LIGHTER =>  1 +< 3,
  FONT_WEIGHT_100     =>  1 +< 4,
  FONT_WEIGHT_200     =>  1 +< 5,
  FONT_WEIGHT_300     =>  1 +< 6,
  FONT_WEIGHT_400     =>  1 +< 7,
  FONT_WEIGHT_500     =>  1 +< 8,
  FONT_WEIGHT_600     =>  1 +< 9,
  FONT_WEIGHT_700     => 1 +< 10,
  FONT_WEIGHT_800     => 1 +< 11,
  FONT_WEIGHT_900     => 1 +< 12,
  FONT_WEIGHT_INHERIT => 1 +< 13,
  'NB_FONT_WEIGHTS'
);

constant CRNumType is export := guint32;
our enum CRNumTypeEnum is export (
  NUM_AUTO         => 0,
  'NUM_GENERIC',
  'NUM_LENGTH_EM',
  'NUM_LENGTH_EX',
  'NUM_LENGTH_PX',
  'NUM_LENGTH_IN',
  'NUM_LENGTH_CM',
  'NUM_LENGTH_MM',
  'NUM_LENGTH_PT',
  'NUM_LENGTH_PC',
  'NUM_ANGLE_DEG',
  'NUM_ANGLE_RAD',
  'NUM_ANGLE_GRAD',
  'NUM_TIME_MS',
  'NUM_TIME_S',
  'NUM_FREQ_HZ',
  'NUM_FREQ_KHZ',
  'NUM_PERCENTAGE',
  'NUM_INHERIT',
  'NUM_UNKNOWN_TYPE',
  'NB_NUM_TYPE'
);

constant CRParsingLocationSerialisationMask is export := guint32;
our enum CRParsingLocationSerialisationMaskEnum is export (
  DUMP_LINE        =>        1,
  DUMP_COLUMN      => 1  +<  1,
  DUMP_BYTE_OFFSET => 1  +<  2,
);

constant CRPredefinedAbsoluteFontSize is export := guint32;
our enum CRPredefinedAbsoluteFontSizeEnum is export (
  FONT_SIZE_XX_SMALL                => 0,
  'FONT_SIZE_X_SMALL',
  'FONT_SIZE_SMALL',
  'FONT_SIZE_MEDIUM',
  'FONT_SIZE_LARGE',
  'FONT_SIZE_X_LARGE',
  'FONT_SIZE_XX_LARGE',
  'FONT_SIZE_INHERIT',
  'NB_PREDEFINED_ABSOLUTE_FONT_SIZES'
);

constant CRPseudoType is export := guint32;
our enum CRPseudoTypeEnum is export (
  IDENT_PSEUDO    => 0,
  'FUNCTION_PSEUDO'
);

constant CRRelativeFontSize is export := guint32;
our enum CRRelativeFontSizeEnum is export <
  FONT_SIZE_LARGER
  FONT_SIZE_SMALLER
  NB_RELATIVE_FONT_SIZE
>;

constant CRSeekPos is export := guint32;
our enum CRSeekPosEnum is export <
  CR_SEEK_CUR
  CR_SEEK_BEGIN
  CR_SEEK_END
>;

constant CRStatementType is export := guint32;
our enum CRStatementTypeEnum is export (
  AT_RULE_STMT           => 0,
  'RULESET_STMT',
  'AT_IMPORT_RULE_STMT',
  'AT_MEDIA_RULE_STMT',
  'AT_PAGE_RULE_STMT',
  'AT_CHARSET_RULE_STMT',
  'AT_FONT_FACE_RULE_STMT'
);

constant CRStatus is export := guint32;
our enum CRStatusEnum is export <
  CR_OK
  CR_BAD_PARAM_ERROR
  CR_INSTANCIATION_FAILED_ERROR
  CR_UNKNOWN_TYPE_ERROR
  CR_UNKNOWN_PROP_ERROR
  CR_UNKNOWN_PROP_VAL_ERROR
  CR_UNEXPECTED_POSITION_SCHEME
  CR_START_OF_INPUT_ERROR
  CR_END_OF_INPUT_ERROR
  CR_OUTPUT_TOO_SHORT_ERROR
  CR_INPUT_TOO_SHORT_ERROR
  CR_OUT_OF_BOUNDS_ERROR
  CR_EMPTY_PARSER_INPUT_ERROR
  CR_ENCODING_ERROR
  CR_ENCODING_NOT_FOUND_ERROR
  CR_PARSING_ERROR
  CR_SYNTAX_ERROR
  CR_NO_ROOT_NODE_ERROR
  CR_NO_TOKEN
  CR_OUT_OF_MEMORY_ERROR
  CR_PSEUDO_CLASS_SEL_HANDLER_NOT_FOUND_ERROR
  CR_BAD_PSEUDO_CLASS_SEL_HANDLER_ERROR
  CR_ERROR
  CR_FILE_NOT_FOUND_ERROR
  CR_VALUE_NOT_FOUND_ERROR
>;

constant CRStyleOrigin is export := guint32;
our enum CRStyleOriginEnum is export (
  ORIGIN_UA     => 0,
  'ORIGIN_USER',
  'ORIGIN_AUTHOR',
  'NB_ORIGINS'
);

constant CRTermType is export := guint32;
our enum CRTermTypeEnum is export (
  TERM_NO_TYPE      => 0,
  'TERM_NUMBER',
  'TERM_FUNCTION',
  'TERM_STRING',
  'TERM_IDENT',
  'TERM_URI',
  'TERM_RGB',
  'TERM_UNICODERANGE',
  'TERM_HASH'
);

constant CRTokenExtraType is export := guint32;
our enum CRTokenExtraTypeEnum is export (
  NO_ET         => 0,
  'LENGTH_PX_ET',
  'LENGTH_CM_ET',
  'LENGTH_MM_ET',
  'LENGTH_IN_ET',
  'LENGTH_PT_ET',
  'LENGTH_PC_ET',
  'ANGLE_DEG_ET',
  'ANGLE_RAD_ET',
  'ANGLE_GRAD_ET',
  'TIME_MS_ET',
  'TIME_S_ET',
  'FREQ_HZ_ET',
  'FREQ_KHZ_ET'
);

constant CRTokenType is export := guint32;
our enum CRTokenTypeEnum is export <
  NO_TK
  S_TK
  CDO_TK
  CDC_TK
  INCLUDES_TK
  DASHMATCH_TK
  COMMENT_TK
  STRING_TK
  IDENT_TK
  HASH_TK
  IMPORT_SYM_TK
  PAGE_SYM_TK
  MEDIA_SYM_TK
  FONT_FACE_SYM_TK
  CHARSET_SYM_TK
  ATKEYWORD_TK
  IMPORTANT_SYM_TK
  EMS_TK
  EXS_TK
  LENGTH_TK
  ANGLE_TK
  TIME_TK
  FREQ_TK
  DIMEN_TK
  PERCENTAGE_TK
  NUMBER_TK
  RGB_TK
  URI_TK
  FUNCTION_TK
  UNICODERANGE_TK
  SEMICOLON_TK
  CBO_TK
  CBC_TK
  PO_TK
  PC_TK
  BO_TK
  BC_TK
  DELIM_TK
>;

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

constant Operator is export := guint32;
our enum OperatorEnum is export (
  NO_OP  => 0,
  'DIVIDE',
  'COMMA'
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
