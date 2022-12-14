use v6.c;

use NativeCall;

use GLib::Raw::Definitions;

unit package Gnome::Shell::Raw::Definitions;

# cw: This will need to be replaced with something more robust!
our constant gnome-shell-st is export := '/usr/lib/gnome-shell/libst-1.0';

our constant Atom is export := guint32;

class StAdjustment          is repr<CPointer> does GLib::Roles::Pointers is export { }
class StBorderImage         is repr<CPointer> does GLib::Roles::Pointers is export { }
class StBin                 is repr<CPointer> does GLib::Roles::Pointers is export { }
#class StBoxLayout           is repr<CPointer> does GLib::Roles::Pointers is export { }
class StButton              is repr<CPointer> does GLib::Roles::Pointers is export { }
class StDrawingArea         is repr<CPointer> does GLib::Roles::Pointers is export { }
class StEntry               is repr<CPointer> does GLib::Roles::Pointers is export { }
#class StGenericAccessible   is repr<CPointer> does GLib::Roles::Pointers is export { }
#class StIcon                is repr<CPointer> does GLib::Roles::Pointers is export { }
#class StIconColors          is repr<CPointer> does GLib::Roles::Pointers is export { }
class StImageContent        is repr<CPointer> does GLib::Roles::Pointers is export { }
#class StLabel               is repr<CPointer> does GLib::Roles::Pointers is export { }
class StPasswordEntry       is repr<CPointer> does GLib::Roles::Pointers is export { }
class StScrollable          is repr<CPointer> does GLib::Roles::Pointers is export { }
class StScrollBar           is repr<CPointer> does GLib::Roles::Pointers is export { }
class StScrollViewFade      is repr<CPointer> does GLib::Roles::Pointers is export { }
class StSettings            is repr<CPointer> does GLib::Roles::Pointers is export { }
#class StShadow              is repr<CPointer> does GLib::Roles::Pointers is export { }
#class StShadowHelper        is repr<CPointer> does GLib::Roles::Pointers is export { }
class StTheme               is repr<CPointer> does GLib::Roles::Pointers is export { }
class StThemeContext        is repr<CPointer> does GLib::Roles::Pointers is export { }
class StThemeNode           is repr<CPointer> does GLib::Roles::Pointers is export { }
#class StThemeNodePaintState is repr<CPointer> does GLib::Roles::Pointers is export { }
class StViewport            is repr<CPointer> does GLib::Roles::Pointers is export { }
class StWidget              is repr<CPointer> does GLib::Roles::Pointers is export { }

class CRAdditionalSel       is repr<CPointer> does GLib::Roles::Pointers is export { }
class CREncoding            is repr<CPointer> does GLib::Roles::Pointers is export { }
class CRStatement           is repr<CPointer> does GLib::Roles::Pointers is export { }
class CRTerm                is repr<CPointer> does GLib::Roles::Pointers is export { }
