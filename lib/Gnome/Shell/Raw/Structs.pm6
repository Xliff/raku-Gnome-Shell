use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use GLib::Raw::Object;
use GLib::Raw::Structs;
use GDK::Raw::Definitions:ver<4>;
use GDK::Raw::Structs:ver<4>;
use GTK::Raw::Definitions:ver<4>;
use GTK::Raw::Enums:ver<4>;
use GTK::Raw::Structs:ver<4>;
use Mutter::Raw::Definitions;
use Mutter::Raw::Structs;
use Gnome::Shell::Raw::Definitions;
use Gnome::Shell::Raw::Enums;

unit package Gnome::Shell::Raw::Structs;

# class NaTrayChildClass is repr<CStruct> is export {
# 	has GtkSocketClass $!parent_class;
# }

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

# class ShellEmbeddedWindowClass is repr<CStruct> is export {
# 	has GtkWindowClass $!parent_class;
# }
#
# class ShellGtkEmbedClass is repr<CStruct> is export {
# 	has MutterClutterCloneClass $!parent_class;
# }

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
	has  Pointer $!parent_instance; # NMSecretAgentOld
	has  Pointer $!priv           ; # ShellNetworkAgentPrivate
}

# class ShellNetworkAgentClass is repr<CStruct> is export {
# 	has NMSecretAgentOldClass $!parent_class;
# }

class ShellWindowPreviewLayout is repr<CStruct> is export {
	has MutterClutterLayoutManager  $!parent;
	has Pointer                     $!priv  ; # ShellWindowPreviewLayoutPrivate
}

# class StBinClass is repr<CStruct> is export {
# 	has StWidgetClass $!parent_class;
# }

class StBoxLayout is repr<CStruct> is export {
	has StViewport  $!parent;
	has Pointer     $!priv  ; # StBoxLayoutPrivate
}

class StClipboard is repr<CStruct> is export {
	has GObject $!parent;
}

class StFocusManager is repr<CStruct> is export {
	has GObject               $!parent_instance;
	has Pointer $!priv           ; # StFocusManagerPrivate
}

class StWidgetAccessible is repr<CStruct> is export {
	has MutterCallyActor                $!parent;
	has Pointer   $!priv; #= StWidgetAccessible
}

class StGenericAccessible is repr<CStruct> is export {
	has StWidgetAccessible         $!parent;
	has Pointer   $!priv; #= StGenericAccessible
}

# class StGenericAccessibleClass is repr<CStruct> is export {
# 	has StWidgetAccessibleClass $!parent_class;
# }

class StIcon is repr<CStruct> is export {
	has StWidget      $!parent;
	has Pointer   $!priv; #= StIcon
}

class StIconColors is repr<CStruct> is export {
  has guint              $!ref_count;
  has MutterClutterColor $!foreground;
  has MutterClutterColor $!warning;
  has MutterClutterColor $!error;
  has MutterClutterColor $!success;

	method foreground is rw {
		Proxy.new:
			FETCH => -> $                          { $!foreground      },
			STORE => -> $, MutterClutterColor() \c { $!foreground := c };
	}

  method warning is rw {
		Proxy.new:
			FETCH => -> $                          { $!warning      },
			STORE => -> $, MutterClutterColor() \c { $!warning := c };
	}

  method error is rw {
		Proxy.new:
			FETCH => -> $                          { $!error      },
			STORE => -> $, MutterClutterColor() \c { $!error := c };
	}

  method success is rw {
		Proxy.new:
			FETCH => -> $                          { $!success      },
			STORE => -> $, MutterClutterColor() \c { $!success := c };
	}

}

class StLabel is repr<CStruct> is export {
	has StWidget       $!parent_instance;
	has Pointer            $!priv; #= StLabel
}

class StScrollView is repr<CStruct> is export {
	has StBin               $!parent_instance;
	has Pointer            $!priv; #= StScrollView
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
				FETCH => -> $,                         { $!color      },
				STORE => -> $, MutterClutterColor() \v { $!color := v };
	  }
}

class StShadowHelper is repr<CStruct> is export {
  has StShadow           $!shadow;
  has MutterCoglPipeline $!pipeline;

  has gfloat       $.width     is rw;
  has gfloat       $.height    is rw;

	method shadow {
		Proxy.new:
			FETCH => -> $,               { $!shadow      },
			STORE => -> $, StShadow() \s { $!shadow := s }
	}

	method pipeline {
		Proxy.new:
			FETCH => -> $,                         { $!pipeline      },
			STORE => -> $, MutterCoglPipeline() \p { $!pipeline := p }
	}
}

class StTextureCache is repr<CStruct> is export {
	has GObject               $!parent;
	has Pointer   $!priv; #= StTextureCache
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

# class StViewportClass is repr<CStruct> is export {
# 	has StWidgetClass $!parent_class;
# }

# class StWidgetAccessibleClass is repr<CStruct> is export {
# 	has MutterCallyActorClass $!parent_class;
# }
