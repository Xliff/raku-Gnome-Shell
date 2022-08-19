use v6.c;

use GLib::Raw::Definitions;

unit package Gnome::Shell::Raw::Cr::Enums;

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

constant Operator is export := guint32;
our enum OperatorEnum is export (
  NO_OP  => 0,
  'DIVIDE',
  'COMMA'
);
