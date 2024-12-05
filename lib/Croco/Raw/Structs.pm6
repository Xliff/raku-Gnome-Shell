use v6.c;

use NativeCall;
use Method::Also;

use GLib::Raw::Definitions;
use GLib::Raw::Structs;
use Croco::Raw::Definitions;
use Croco::Raw::Enums;

use GLib::Roles::Pointers;

unit package Croco::Raw::Structs;

class CRParsingLocation is repr<CStruct> is export {
	has guint $.line        is rw;
	has guint $.column      is rw;
	has guint $.byte_offset is rw;
}

class CRNum is repr<CStruct> is export {
	has CRNumType         $!type    ;
	has gdouble           $!val     ;
	has CRParsingLocation $!location;
}

class CRString is repr<CStruct> is export {
	has GString           $!stryng  ;
	has CRParsingLocation $.location is rw;

  method stryng is rw is also<string> {
    Proxy.new:
      FETCH => -> $     { $!stryng }
      STORE => -> $, \v { $!stryng := v }
  }
}

class CRRgb is repr<CStruct> does GLib::Roles::Pointers is export {
  has Str               $!name;
  has glong             $.red           is rw;
  has glong             $.green         is rw;
  has glong             $.blue          is rw;
  has gboolean          $.is_percentage is rw;
  has CRParsingLocation $.location      is rw;

  method name is rw {
    Proxy.new:
      FETCH => -> $     { $!name }
      STORE => -> $, \v { $!name := v }
  }

  method gist {
    qq:to/GIST/.chomp;
      CRRgb.new( name => '{ $!name }', red => { $!red }, green => {
        $!green }, blue => { $!blue }, is_percentage => {
        $!is_percentage }, location => {
        do with $!location { .gist } else { '(CRParsingLocation)' } } )
      GIST
  }

}

class CRContent is repr<CUnion> {
  has CRNum    $!num;
  has CRString $!str;
  has CRRgb    $!rgb;

  method num is rw {
    Proxy.new:
      FETCH => -> $     { $!num      },
      STORE => -> $, \v { $!num := v };
  }

  method str is rw {
    Proxy.new:
      FETCH => -> $     { $!str       },
      STORE => -> $, \v { $!str := v };
  }

  method rgb is rw {
    Proxy.new:
      FETCH => -> $     { $!rgb      },
      STORE => -> $, \v { $!rgb := v };
  }

}

class CRTerm is repr<CStruct> { ... }

class CRExtContent is repr<CUnion> {
  has CRTerm $!func_param;

  method func_param is rw {
    Proxy.new:
      FETCH => -> $     { $!func_param      },
      STORE => -> $, \v { $!func_param := v };
  }

}

class CRTerm does GLib::Roles::Pointers is export {
  has CRTermType        $.type         is rw;
  has CRUnaryOperator   $.unary_op     is rw;
  has CROperator        $.the_operator is rw;
  HAS CRContent         $!content;
  HAS CRExtContent      $!ext_content;
  has gpointer          $!app_data;
  has glong             $.ref_count;
  has CRTerm            $!next;
  has CRTerm            $!prev;
  has CRParsingLocation $.location     is rw;

  method content is rw {
    Proxy.new:
      FETCH => -> $     { $!content      },
      STORE => -> $, \v { $!content := v }
  }

  method ext_content is rw {
    Proxy.new:
      FETCH => -> $     { $!ext_content      },
      STORE => -> $, \v { $!ext_content := v }
  }

  method app_data is rw {
    Proxy.new:
      FETCH => -> $     { $!app_data      },
      STORE => -> $, \v { $!app_data := v }
  }

  method next is rw {
    Proxy.new:
      FETCH => -> $     { $!next      },
      STORE => -> $, \v { $!next := v }
  }

  method prev is rw {
    Proxy.new:
      FETCH => -> $     { $!prev      },
      STORE => -> $, \v { $!prev := v }
  }

}

class CRRuleSet        is repr<CPointer> is export { }
class CRAtImportRule   is repr<CPointer> is export { }
class CRAtMediaRule    is repr<CPointer> is export { }
class CRAtPageRule     is repr<CPointer> is export { }
class CRAtCharsetRule  is repr<CPointer> is export { }
class CRAtFontFaceRule is repr<CPointer> is export { }
class CRStyleSheet     is repr<CPointer> is export { }

class CRKind is repr<CUnion> {
  has CRRuleSet        $!ruleset        ;
  has CRAtImportRule   $!import_rule    ;
  has CRAtMediaRule    $!media_rule     ;
  has CRAtPageRule     $!page_rule      ;
  has CRAtCharsetRule  $!charset_rule   ;
  has CRAtFontFaceRule $!font_face_rule ;
}

class CRStatement is repr<CStruct> does GLib::Roles::Pointers is export {
  has CRStatementType   $.type         is rw;
  HAS CRKind            $!kind              ;
  has gulong            $.specificity  is rw;
  has CRStyleSheet      $!parent_sheet      ;
  has CRStatement       $!next              ;
  has CRStatement       $!prev              ;
  has CRParsingLocation $.location     is rw;
  has gpointer          $!app_data          ;
  has gpointer          $!croco_data        ;
}

#
# class CRAtCharsetRule is repr<CStruct> is export {
# 	has CRString $!charset;
# }
#
# class CRAtMediaRule is repr<CStruct> is export {
# 	has GList       $!media_list;
# 	has CRStatement $!rulesets  ;
# }
#
# class CRAttrSel is repr<CStruct> is export {
# 	has CRString          $!name     ;
# 	has CRString          $!value    ;
# 	has AttrMatchWay      $!match_way;
# 	has CRAttrSel         $!next     ;
# 	has CRAttrSel         $!prev     ;
# 	has CRParsingLocation $!location ;
# }
#
# class CRCascade is repr<CStruct> is export {
# 	has Pointer $!priv; #= CRCascadePriv
# }
#
# class CRDeclaration is repr<CStruct> is export {
# 	has CRString          $!property        ;
# 	has CRTerm            $!value           ;
# 	has CRStatement       $!parent_statement;
# 	has CRDeclaration     $!next            ;
# 	has CRDeclaration     $!prev            ;
# 	has gboolean          $!important       ;
# 	has glong             $!ref_count       ;
# 	has CRParsingLocation $!location        ;
# 	has gpointer          $!rfu0            ;
# 	has gpointer          $!rfu1            ;
# 	has gpointer          $!rfu2            ;
# 	has gpointer          $!rfu3            ;
# }
#
# class CRAtFontFaceRule is repr<CStruct> is export {
# 	has CRDeclaration $!decl_list;
# }
#
# class CRAtPageRule is repr<CStruct> is export {
# 	has CRDeclaration $!decl_list;
# 	has CRString      $!name     ;
# 	has CRString      $!pseudo   ;
# }
#
# class CREncHandler is repr<CStruct> is export {
# 	has CREncoding                  $!encoding           ;
# 	has Pointer $!decode_input                     ; #= CREncInputFunc
# 	has Pointer $!encode_output                    ; #= CREncInputFunc
# 	has Pointer $!enc_str_len_as_utf8  ; #= CREncInputStrLenAsUtf8Func
# 	has Pointer $!utf8_str_len_as_enc ; #= CREncUtf8StrLenAsOutputFunc
# }
#
# class CRFontSizeAdjust is repr<CStruct> is export {
# 	has CRFontSizeAdjustType $!type;
# 	has CRNum                $!num ;
# }
#
# class CRInput is repr<CStruct> is export {
# 	has Pointer $!priv; # CRInputPriv
# }
#
# class CRInputPos is repr<CStruct> is export {
# 	has glong    $!line           ;
# 	has glong    $!col            ;
# 	has gboolean $!end_of_file    ;
# 	has gboolean $!end_of_line    ;
# 	has glong    $!next_byte_index;
# }
#
# class CROMParser is repr<CStruct> is export {
# 	has Pointer $!priv; # CROMParserPriv
# }
#
# class CRParser is repr<CStruct> is export {
# 	has Pointer $!priv; # CRParserPriv
# }
#
# class CRPropList is repr<CStruct> is export {
# 	has Pointer $!priv; # CRPropListPriv
# }
#
# class CRPseudo is repr<CStruct> is export {
# 	has CRPseudoType      $!type    ;
# 	has CRString          $!name    ;
# 	has CRString          $!extra   ;
# 	has CRParsingLocation $!location;
# }
#
# class CRRgb is repr<CStruct> is export {
# 	has guchar            $!name         ;
# 	has glong             $!red          ;
# 	has glong             $!green        ;
# 	has glong             $!blue         ;
# 	has gboolean          $!is_percentage;
# 	has CRParsingLocation $!location     ;
# }
#
# class CRSimpleSel is repr<CStruct> is export {
# 	has SimpleSelectorType $!type_mask      ;
# 	has gboolean           $!is_case_sentive;
# 	has CRString           $!name           ;
# 	has Combinator         $!combinator     ;
# 	has CRAdditionalSel    $!add_sel        ;
# 	has gulong             $!specificity    ;
# 	has CRSimpleSel        $!next           ;
# 	has CRSimpleSel        $!prev           ;
# 	has CRParsingLocation  $!location       ;
# }
#
# class CRSelector is repr<CStruct> is export {
# 	has CRSimpleSel       $!simple_sel;
# 	has CRSelector        $!next      ;
# 	has CRSelector        $!prev      ;
# 	has CRParsingLocation $!location  ;
# 	has glong             $!ref_count ;
# }
#
# class CRRuleSet is repr<CStruct> is export {
# 	has CRSelector    $!sel_list         ;
# 	has CRDeclaration $!decl_list        ;
# 	has CRStatement   $!parent_media_rule;
# }
#
# class CRStyleSheet is repr<CStruct> is export {
# 	has CRStatement   $!statements        ;
# 	has CRStyleOrigin $!origin            ;
# 	has CRStatement   $!parent_import_rule;
# 	has gpointer      $!croco_data        ;
# 	has gpointer      $!app_data          ;
# 	has gulong        $!ref_count         ;
# }
#
# class CRAtImportRule is repr<CStruct> is export {
# 	has CRString     $!url       ;
# 	has GList        $!media_list;
# 	has CRStyleSheet $!sheet     ;
# }
#
# class CRTknzr is repr<CStruct> is export {
# 	has Pointer $!priv; #= CRTknzrPriv
# }
