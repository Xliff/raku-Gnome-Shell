use v6.c;

use NativeCall;

use Gnome::Shell::Raw::Types;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

role GTK::Roles::ActionObservable {
  has GtkActionObservable $!aob is implementor;

  method roleInit-GtkActionObservable {
    return if $!aob;

    my \i = findProperImplementor(self.^attributes);
    $!aob  = cast( GtkActionObservable, i.get_value(self) );
  }

  method Gnome::Shell::Raw::Definitions::GtkActionObservable
  { self.GtkActionObservable }

  method GtkActionObservable { $!aob }

  method gtkactionobservable_get_type {
    state ($n, $t);

    unstable_get_type( self.^name, &gtk_action_observable_get_type, $n, $t );
  }

  method register_observer (
    Str()               $action_name,
    GtkActionObservable() $observer
  ) {
    gtk_action_observable_register_observer($!aob, $action_name, $observer);
  }

  method unregister_observer (
    Str()               $action_name,
    GtkActionObservable() $observer
  ) {
    gtk_action_observable_unregister_observer($!aob, $action_name, $observer);
  }

}

our subset GtkActionObservableAncestry is export of Mu
  where GtkActionObservable | GObject;

class GTK::ActionObserver {
  also does GLib::Roles::Object;
  also does GTK::Roles::ActionObservable;

  submethod BUILD ( :$gtk-action-observable ) {
    self.setGtkActionObservable($gtk-action-observable)
      if $gtk-action-observable
  }

  method setGtkActionMuxer (GtkActionObservableAncestry $_) {
    my $to-parent;

    $!aob = do {
      when GtkActionObservable {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(GtkActionObservable, $_);
      }
    }
    self!setObject($to-parent);
  }

  multi method new (
    GtkActionObservableAncestry  $gtk-action-observable,
                                :$ref                  = True
  ) {
    return unless $gtk-action-observable;

    my $o = self.bless( :$gtk-action-observable );
    $o.ref if $ref;
    $o;
  }

}

### /home/cbwood/Projects/gnome-shell/src/gtkactionobservable.h

sub gtk_action_observable_get_type ()
  returns GType
  is native(gnome-shell)
  is export
{ * }

sub gtk_action_observable_register_observer (
  GtkActionObservable $observable,
  Str                 $action_name,
  GtkActionObservable   $observer
)
  is native(gnome-shell)
  is export
{ * }

sub gtk_action_observable_unregister_observer (
  GtkActionObservable $observable,
  Str                 $action_name,
  GtkActionObservable $observer
)
  is native(gnome-shell)
  is export
{ * }
