use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use GLib::Raw::Structs;
use Mutter::Clutter::Raw::Definitions;
use Mutter::Clutter::Raw::Structs;
use Gnome::Shell::Raw::Definitions;

class CRAtCharsetRule is repr<CStruct> is export {
	has CRString $!charset;
}

class CRAtFontFaceRule is repr<CStruct> is export {
	has CRDeclaration $!decl_list;
}

class CRAtImportRule is repr<CStruct> is export {
	has CRString     $!url       ;
	has GList        $!media_list;
	has CRStyleSheet $!sheet     ;
}

class CRAtMediaRule is repr<CStruct> is export {
	has GList       $!media_list;
	has CRStatement $!rulesets  ;
}

class CRAtPageRule is repr<CStruct> is export {
	has CRDeclaration $!decl_list;
	has CRString      $!name     ;
	has CRString      $!pseudo   ;
}

class CRAttrSel is repr<CStruct> is export {
	has CRString          $!name     ;
	has CRString          $!value    ;
	has AttrMatchWay      $!match_way;
	has CRAttrSel         $!next     ;
	has CRAttrSel         $!prev     ;
	has CRParsingLocation $!location ;
}

class CRCascade is repr<CStruct> is export {
	has CRCascadePriv $!priv;
}

class CRDeclaration is repr<CStruct> is export {
	has CRString          $!property        ;
	has CRTerm            $!value           ;
	has CRStatement       $!parent_statement;
	has CRDeclaration     $!next            ;
	has CRDeclaration     $!prev            ;
	has gboolean          $!important       ;
	has glong             $!ref_count       ;
	has CRParsingLocation $!location        ;
	has gpointer          $!rfu0            ;
	has gpointer          $!rfu1            ;
	has gpointer          $!rfu2            ;
	has gpointer          $!rfu3            ;
}

class CREncHandler is repr<CStruct> is export {
	has CREncoding                  $!encoding           ;
	has CREncInputFunc              $!decode_input       ;
	has CREncInputFunc              $!encode_output      ;
	has CREncInputStrLenAsUtf8Func  $!enc_str_len_as_utf8;
	has CREncUtf8StrLenAsOutputFunc $!utf8_str_len_as_enc;
}

class CRFontSizeAdjust is repr<CStruct> is export {
	has CRFontSizeAdjustType $!type;
	has CRNum                $!num ;
}

class CRInput is repr<CStruct> is export {
	has CRInputPriv $!priv;
}

class CRInputPos is repr<CStruct> is export {
	has glong    $!line           ;
	has glong    $!col            ;
	has gboolean $!end_of_file    ;
	has gboolean $!end_of_line    ;
	has glong    $!next_byte_index;
}

class CRNum is repr<CStruct> is export {
	has CRNumType         $!type    ;
	has gdouble           $!val     ;
	has CRParsingLocation $!location;
}

class CROMParser is repr<CStruct> is export {
	has CROMParserPriv $!priv;
}

class CRParser is repr<CStruct> is export {
	has CRParserPriv $!priv;
}

class CRParsingLocation is repr<CStruct> is export {
	has guint $!line       ;
	has guint $!column     ;
	has guint $!byte_offset;
}

class CRPropList is repr<CStruct> is export {
	has CRPropListPriv $!priv;
}

class CRPseudo is repr<CStruct> is export {
	has CRPseudoType      $!type    ;
	has CRString          $!name    ;
	has CRString          $!extra   ;
	has CRParsingLocation $!location;
}

class CRRgb is repr<CStruct> is export {
	has guchar            $!name         ;
	has glong             $!red          ;
	has glong             $!green        ;
	has glong             $!blue         ;
	has gboolean          $!is_percentage;
	has CRParsingLocation $!location     ;
}

class CRRuleSet is repr<CStruct> is export {
	has CRSelector    $!sel_list         ;
	has CRDeclaration $!decl_list        ;
	has CRStatement   $!parent_media_rule;
}

class CRSelector is repr<CStruct> is export {
	has CRSimpleSel       $!simple_sel;
	has CRSelector        $!next      ;
	has CRSelector        $!prev      ;
	has CRParsingLocation $!location  ;
	has glong             $!ref_count ;
}

class CRSimpleSel is repr<CStruct> is export {
	has SimpleSelectorType $!type_mask      ;
	has gboolean           $!is_case_sentive;
	has CRString           $!name           ;
	has Combinator         $!combinator     ;
	has CRAdditionalSel    $!add_sel        ;
	has gulong             $!specificity    ;
	has CRSimpleSel        $!next           ;
	has CRSimpleSel        $!prev           ;
	has CRParsingLocation  $!location       ;
}

class CRString is repr<CStruct> is export {
	has GString           $!stryng  ;
	has CRParsingLocation $!location;
}

class CRStyleSheet is repr<CStruct> is export {
	has CRStatement   $!statements        ;
	has CRStyleOrigin $!origin            ;
	has CRStatement   $!parent_import_rule;
	has gpointer      $!croco_data        ;
	has gpointer      $!app_data          ;
	has gulong        $!ref_count         ;
}

class CRTknzr is repr<CStruct> is export {
	has CRTknzrPriv $!priv;
}

class NaTrayChildClass is repr<CStruct> is export {
	has GtkSocketClass $!parent_class;
}

class NaTrayManager is repr<CStruct> is export {
	has GObject        $!parent_instance  ;
	has GdkAtom        $!selection_atom   ;
	has Atom           $!opcode_atom      ;
	has Atom           $!message_data_atom;
	has GtkWidget      $!invisible        ;
	has GdkScreen      $!screen           ;
	has GtkOrientation $!orientation      ;
	has MutterClutterColor   $!fg               ;
	has MutterClutterColor   $!error            ;
	has MutterClutterColor   $!warning          ;
	has MutterClutterColor   $!success          ;
	has GList          $!messages         ;
	has GHashTable     $!socket_table     ;
}

class ShellEmbeddedWindowClass is repr<CStruct> is export {
	has GtkWindowClass $!parent_class;
}

class ShellGtkEmbedClass is repr<CStruct> is export {
	has MutterClutterCloneClass $!parent_class;
}

class ShellMemoryInfo is repr<CStruct> is export {
	has guint $!glibc_uordblks     ;
	has guint $!js_bytes           ;
	has guint $!gjs_boxed          ;
	has guint $!gjs_gobject        ;
	has guint $!gjs_function       ;
	has guint $!gjs_closure        ;
	has guint $!last_gc_seconds_ago;
}

class ShellNetworkAgent is repr<CStruct> is export {
	has NMSecretAgentOld         $!parent_instance;
	has ShellNetworkAgentPrivate $!priv           ;
}

class ShellNetworkAgentClass is repr<CStruct> is export {
	has NMSecretAgentOldClass $!parent_class;
}

class ShellWindowPreviewLayout is repr<CStruct> is export {
	has MutterClutterLayoutManager            $!parent;
	has ShellWindowPreviewLayoutPrivate $!priv  ;
}

class StBinClass is repr<CStruct> is export {
	has StWidgetClass $!parent_class;
}

class StBoxLayout is repr<CStruct> is export {
	has StViewport         $!parent;
	has StBoxLayoutPrivate $!priv  ;
}

class StClipboard is repr<CStruct> is export {
	has GObject $!parent;
}

class StFocusManager is repr<CStruct> is export {
	has GObject               $!parent_instance;
	has StFocusManagerPrivate $!priv           ;
}

class StGenericAccessible is repr<CStruct> is export {
	has StWidgetAccessible         $!parent;
	has StGenericAccessiblePrivate $!priv  ;
}

class StGenericAccessibleClass is repr<CStruct> is export {
	has StWidgetAccessibleClass $!parent_class;
}

class StIcon is repr<CStruct> is export {
	has StWidget      $!parent;
	has StIconPrivate $!priv  ;
}

class StIconColors is repr<CStruct> is export {
  has guint              $!ref_count;
  has MutterClutterColor $!foreground;
  has MutterClutterColor $!warning;
  has MutterClutterColor $!error;
  has MutterClutterColor $!success;

	method foreground is rw {
		Proxy.new:
			FETCH => $                          { $!foreground      },
			STORE => $, MutterClutterColor() \c { $!foreground := c };
	}

  method warning is rw {
		Proxy.new:
			FETCH => $                          { $!warning      },
			STORE => $, MutterClutterColor() \c { $!warning := c };
	}

  method error is rw {
		Proxy.new:
			FETCH => $                          { $!error      },
			STORE => $, MutterClutterColor() \c { $!error := c };
	}

  method success is rw {
		Proxy.new:
			FETCH => $                          { $!success      },
			STORE => $, MutterClutterColor() \c { $!success := c };
	}
	
}

class StLabel is repr<CStruct> is export {
	has StWidget       $!parent_instance;
	has StLabelPrivate $!priv           ;
}

class StScrollView is repr<CStruct> is export {
	has StBin               $!parent_instance;
	has StScrollViewPrivate $!priv           ;
}

class StShadow is repr<CStruct> is export {
    HAS MutterClutterColor $!color;
    has gdouble            $.xoffset   is rw;
    has gdouble            $.yoffset   is rw;
    has gdouble            $.blur      is rw;
    has gdouble            $.spread    is rw;
    has gboolean           $.inset     is rw;
    has gint               $.ref_count is rw;

		method color {
			Proxy.new:
				FETCH => $,                         { $!color      },
				STORE => $, MutterClutterColor() \v { $!color := v };
	  }
}

class StShadowHelper is repr<CStruct> is export {
  has StShadow           $!shadow;
  has MutterCoglPipeline $!pipeline;

  has gfloat       $.width     is rw;
  has gfloat       $.height    is rw;

	method shadow {
		Proxy.new:
			FETCH => $,               { $!shadow      },
			STORE => $, StShadow() \s { $!shadow := s }
	}

	method pipeline {
		Proxy.new:
			FETCH => $,                         { $!pipeline      },
			STORE => $, MutterCoglPipeline() \p { $!pipeline := p }
	}
}

class StTextureCache is repr<CStruct> is export {
	has GObject               $!parent;
	has StTextureCachePrivate $!priv  ;
}

class StThemeNodePaintState is repr<CStruct> is export {
	has StThemeNode  $!node                ;
	has gfloat        $!alloc_width         ;
	has gfloat        $!alloc_height        ;
	has gfloat        $!box_shadow_width    ;
	has gfloat        $!box_shadow_height   ;
	has gfloat        $!resource_scale      ;
	has MutterCoglPipeline $!box_shadow_pipeline ;
	has MutterCoglPipeline $!prerendered_texture ;
	has MutterCoglPipeline $!prerendered_pipeline;
	has MutterCoglPipeline $!corner_material     ;
}

class StViewportClass is repr<CStruct> is export {
	has StWidgetClass $!parent_class;
}

class StWidgetAccessible is repr<CStruct> is export {
	has MutterCallyActor                $!parent;
	has StWidgetAccessiblePrivate $!priv  ;
}

class StWidgetAccessibleClass is repr<CStruct> is export {
	has MutterCallyActorClass $!parent_class;
}
