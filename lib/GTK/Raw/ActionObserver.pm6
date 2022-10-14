use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use GLib::Raw::Structs;
use Gnome::Shell::Raw::Definitions;

unit package GTK::Raw::ActionObserver;

### /home/cbwood/Projects/gnome-shell/src/gtkactionobserver.h

sub gtk_action_observer_action_added (
  GtkActionObserver   $observer,
  GtkActionObservable $observable,
  Str                 $action_name,
  GVariantType        $parameter_type,
  gboolean            $enabled,
  GVariant            $state
)
  is native(gnome-shell)
  is export
{ * }

sub gtk_action_observer_action_enabled_changed (
  GtkActionObserver   $observer,
  GtkActionObservable $observable,
  Str                 $action_name,
  gboolean            $enabled
)
  is native(gnome-shell)
  is export
{ * }

sub gtk_action_observer_action_removed (
  GtkActionObserver   $observer,
  GtkActionObservable $observable,
  Str                 $action_name
)
  is native(gnome-shell)
  is export
{ * }

sub gtk_action_observer_action_state_changed (
  GtkActionObserver   $observer,
  GtkActionObservable $observable,
  Str                 $action_name,
  GVariant            $state
)
  is native(gnome-shell)
  is export
{ * }

sub gtk_action_observer_primary_accel_changed (
  GtkActionObserver   $observer,
  GtkActionObservable $observable,
  Str                 $action_name,
  Str                 $action_and_target
)
  is native(gnome-shell)
  is export
{ * }

sub gtk_action_observer_get_type ()
  returns GType
  is      native(gnome-shell)
  is      export
{ * }
