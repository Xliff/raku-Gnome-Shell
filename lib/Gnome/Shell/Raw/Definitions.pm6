use v6.c;

use NativeCall;

use Cairo;

use GLib::Raw::Definitions;

use GLib::Roles::Object;

unit package Gnome::Shell::Raw::Definitions;

# cw: This project has sub-class, so must use the GLib::Object::Registrar mechanism
our $gnome-shell-registrar
  is   export
  does GLib::Roles::Object::Registrar['Gnome-Shell'];

BEGIN add-object-registrar($gnome-shell-registrar);

# cw: This will need to be replaced with something more robust!
our constant gnome-shell       is export := '/usr/lib/gnome-shell/lib-gnome-shell';
our constant gnome-shell-st    is export := '/usr/lib/gnome-shell/libst-1.0';

our constant cairo_surface_t   is export := Cairo::cairo_surface_t;
our constant Atom              is export := guint32;

class StAdjustment               is repr<CPointer> does GLib::Roles::Pointers is export { }
class StBorderImage              is repr<CPointer> does GLib::Roles::Pointers is export { }
class StBin                      is repr<CPointer> does GLib::Roles::Pointers is export { }
#class StBoxLayout                is repr<CPointer> does GLib::Roles::Pointers is export { }
class StButton                   is repr<CPointer> does GLib::Roles::Pointers is export { }
class StDrawingArea              is repr<CPointer> does GLib::Roles::Pointers is export { }
class StEntry                    is repr<CPointer> does GLib::Roles::Pointers is export { }
#class StGenericAccessible        is repr<CPointer> does GLib::Roles::Pointers is export { }
#class StIcon                     is repr<CPointer> does GLib::Roles::Pointers is export { }
#class StIconColors               is repr<CPointer> does GLib::Roles::Pointers is export { }
class StImageContent             is repr<CPointer> does GLib::Roles::Pointers is export { }
#class StLabel                    is repr<CPointer> does GLib::Roles::Pointers is export { }
class StPasswordEntry            is repr<CPointer> does GLib::Roles::Pointers is export { }
class StScrollable               is repr<CPointer> does GLib::Roles::Pointers is export { }
class StScrollBar                is repr<CPointer> does GLib::Roles::Pointers is export { }
class StScrollViewFade           is repr<CPointer> does GLib::Roles::Pointers is export { }
class StSettings                 is repr<CPointer> does GLib::Roles::Pointers is export { }
#class StShadow                   is repr<CPointer> does GLib::Roles::Pointers is export { }
#class StShadowHelper             is repr<CPointer> does GLib::Roles::Pointers is export { }
class StTheme                    is repr<CPointer> does GLib::Roles::Pointers is export { }
class StThemeContext             is repr<CPointer> does GLib::Roles::Pointers is export { }
class StThemeNode                is repr<CPointer> does GLib::Roles::Pointers is export { }
class StThemeNodeTransition      is repr<CPointer> does GLib::Roles::Pointers is export { }
#class StThemeNodePaintState      is repr<CPointer> does GLib::Roles::Pointers is export { }
class StViewport                 is repr<CPointer> does GLib::Roles::Pointers is export { }
class StWidget                   is repr<CPointer> does GLib::Roles::Pointers is export { }

class ShellApp                   is repr<CPointer> does GLib::Roles::Pointers is export { }
class ShellBlurEffect            is repr<CPointer> does GLib::Roles::Pointers is export { }
class ShellGtkEmbed              is repr<CPointer> does GLib::Roles::Pointers is export { }
class ShellEmbeddedWindow        is repr<CPointer> does GLib::Roles::Pointers is export { }
class ShellGlobal                is repr<CPointer> does GLib::Roles::Pointers is export { }
class ShellGLSLEffect            is repr<CPointer> does GLib::Roles::Pointers is export { }
class ShellInvertLightnessEffect is repr<CPointer> does GLib::Roles::Pointers is export { }
class ShellKeyringPrompt         is repr<CPointer> does GLib::Roles::Pointers is export { }
class ShellMimeSniffer           is repr<CPointer> does GLib::Roles::Pointers is export { }
class ShellMountOperation        is repr<CPointer> does GLib::Roles::Pointers is export { }
class ShellPerfLog               is repr<CPointer> does GLib::Roles::Pointers is export { }
class ShellScreenshot            is repr<CPointer> does GLib::Roles::Pointers is export { }
class ShellSecureTextBuffer      is repr<CPointer> does GLib::Roles::Pointers is export { }
class ShellSquareBin             is repr<CPointer> does GLib::Roles::Pointers is export { }
class ShellStack                 is repr<CPointer> does GLib::Roles::Pointers is export { }
class ShellTrayManager           is repr<CPointer> does GLib::Roles::Pointers is export { }
class ShellTrayIcon              is repr<CPointer> does GLib::Roles::Pointers is export { }
class ShellWorkspaceBackground   is repr<CPointer> does GLib::Roles::Pointers is export { }
class ShellWindowPreview         is repr<CPointer> does GLib::Roles::Pointers is export { }
class ShellWindowTracker         is repr<CPointer> does GLib::Roles::Pointers is export { }
class ShellWM                    is repr<CPointer> does GLib::Roles::Pointers is export { }

class ShellPolkitAuthenticationAgent is repr<CPointer> does GLib::Roles::Pointers is export { }

class CRAdditionalSel            is repr<CPointer> does GLib::Roles::Pointers is export { }
class CREncoding                 is repr<CPointer> does GLib::Roles::Pointers is export { }
class CRStatement                is repr<CPointer> does GLib::Roles::Pointers is export { }
class CRTerm                     is repr<CPointer> does GLib::Roles::Pointers is export { }

class GtkActionMuxer             is repr<CPointer> does GLib::Roles::Pointers is export { }
class GtkActionObserver          is repr<CPointer> does GLib::Roles::Pointers is export { }
class GtkActionObservable        is repr<CPointer> does GLib::Roles::Pointers is export { }

class MethodStub {
  method FALLBACK ( *@a ) { }
  method say              { }
  method WHERE            { }
}

multi sub postfix:<?> ($o) is export {
  $o.defined ?? $o !! MethodStub.new
}
