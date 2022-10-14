use v6.c;

use Gnome::Shell::Raw::Types;
use GTK::Raw::ActionObserver;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

role GTK::Roles::ActionObserver {
  has GtkActionObserver $!ao is implementor;

  method roleInit-GtkActionObserver {
    return if $!ao;

    my \i = findProperImplementor(self.^attributes);
    $!ao  = cast( GtkActionObserver, i.get_value(self) );
  }

  method Gnome::Shell::Raw::Definitions::GtkActionObserver
  { self.GtkActionObserver }

  method GtkActionObserver { $!ao }

  method action_added (
    GtkActionObservable() $observable,
    Str()                 $action_name,
    GVariantType()        $parameter_type,
    Int()                 $enabled,
    GVariant()            $state
  ) {
    my gboolean $e = $enabled.so.Int;

    gtk_action_observer_action_added(
      $!ao,
      $observable,
      $action_name,
      $parameter_type,
      $e,
      $state
    );
  }

  method action_enabled_changed (
    GtkActionObservable() $observable,
    Str()                 $action_name,
    Int()                 $enabled
  ) {
    my gboolean $e = $enabled.so.Int;

    gtk_action_observer_action_enabled_changed(
      $!ao,
      $observable,
      $action_name,
      $e
    );
  }

  method action_removed (
    GtkActionObservable() $observable,
    Str()                 $action_name
  ) {
    gtk_action_observer_action_removed($!ao, $observable, $action_name);
  }

  method action_state_changed (
    GtkActionObservable() $observable,
    Str()                 $action_name,
    GVariant()            $state
  ) {
    gtk_action_observer_action_state_changed(
      $!ao,
      $observable,
      $action_name,
      $state
    );
  }

  method gtkactionobserver_get_type {
    state ($n, $t);

    unstable_get_type( self.^name, &gtk_action_observer_get_type, $n, $t );
  }

  method primary_accel_changed (
    GtkActionObservable() $observable,
    Str()                 $action_name,
    Str()                 $action_and_target
  ) {
    gtk_action_observer_primary_accel_changed(
      $!ao,
      $observable,
      $action_name,
      $action_and_target
    );
  }

}

our subset GtkActionObserverAncestry is export of Mu
  where GtkActionObserver | GObject;

class GTK::ActionObserver {
  also does GLib::Roles::Object;
  also does GTK::Roles::ActionObserver;

  submethod BUILD ( :$gtk-action-observer ) {
    self.setGtkActionObserver($gtk-action-observer) if $gtk-action-observer
  }

  method setGtkActionMuxer (GtkActionObserverAncestry $_) {
    my $to-parent;

    $!ao = do {
      when GtkActionObserver {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(GtkActionObserver, $_);
      }
    }
    self!setObject($to-parent);
  }

  multi method new (
    GtkActionObserverAncestry  $gtk-action-observer,
                              :$ref                  = True
  ) {
    return unless $gtk-action-observer;

    my $o = self.bless( :$gtk-action-observer );
    $o.ref if $ref;
    $o;
  }

}
