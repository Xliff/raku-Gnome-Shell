use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use GLib::Raw::Structs;
use GIO::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;

### /home/cbwood/Projects/gnome-shell/src/gtkactionmuxer.h

sub gtk_action_muxer_get_parent (GtkActionMuxer $muxer)
  returns GtkActionMuxer
  is      native(gnome-shell)
  is      export
{ * }

sub gtk_action_muxer_get_primary_accel (
  GtkActionMuxer $muxer,
  Str            $action_and_target
)
  returns Str
  is      native(gnome-shell)
  is      export
{ * }

sub gtk_action_muxer_get_type ()
  returns GType
  is      native(gnome-shell)
  is      export
{ * }

sub gtk_print_action_and_target (
  Str      $action_namespace,
  Str      $action_name,
  GVariant $target
)
  returns Str
  is      native(gnome-shell)
  is      export
{ * }

sub gtk_action_muxer_insert (
  GtkActionMuxer $muxer,
  Str            $prefix,
  GActionGroup   $action_group
)
  is native(gnome-shell)
  is export
{ * }

sub gtk_action_muxer_new ()
  returns GtkActionMuxer
  is      native(gnome-shell)
  is      export
{ * }

sub gtk_action_muxer_remove (GtkActionMuxer $muxer, Str $prefix)
  is native(gnome-shell)
  is export
{ * }

sub gtk_action_muxer_set_parent (GtkActionMuxer $muxer, GtkActionMuxer $parent)
  is native(gnome-shell)
  is export
{ * }

sub gtk_action_muxer_set_primary_accel (
  GtkActionMuxer $muxer,
  Str            $action_and_target,
  Str            $primary_accel
)
  is native(gnome-shell)
  is export
{ * }
