use v6.c;

use Method::Also;
use NativeCall;

use Gnome::Shell::Raw::Typs;

use GLib::Roles::Implementor;

our subset StGenericAccessibleAncestry is export of Mu
  where StGenericAccessible | AtkObjectAncestry;

class Gnome::Shell::GenericAccessible is ATK::Object {
  has StGenericAccessible $!stga is implementor;

  submethod BUILD ( :$st-generic-acc ) {
    self.setStGenericAccessible($st-generic-acc) if $st-generic-acc;
  }

  method setStGenericAccessible (StGenericAccessibleAncestry $_) {
    my $to-parent;

    $!stga = do {
      when StGenericAccessible {
        $to-parent = cast(AtkObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StGenericAccessible, $_);
      }
    }
    self.setAtkObject($to-parent);
  }

  method Mutter::Clutter::Raw::Definitions::StGenericAccessible
    is also<StGenericAccessible>
  { $!stga }

  multi method new (StGenericAccessibleAncestry $st-generic-acc, :$ref = True) {
    return unless $st-generic-acc;

    my $o = self.bless( :$st-generic-acc );
    $o.ref if $ref;
    $o;
  }

  method new_for_actor (MutterClutterActor() $actor) is also<new-for-actor> {
    my $st-generic-acc = st_generic_accessible_new_for_actor($actor);

    $st-generic-acc ?? self.bless( :$st-generic-acc ) !! Nil;
  }

  method get-current-value is also<get_current_value> {
    self.connect-rdouble($!stga, 'get-current-value');
  }

  method get-maximum-value is also<get_maximum_value> {
    self.connect-rdouble($!stga, 'get-maximum-value');
  }

  method get-minimum-value is also<get_minimum_value> {
    self.connect-rdouble($!stga, 'get-minimum-value');
  }

  method get-minimum-increment is also<get_minimum_increment> {
    self.connect-rdouble($!stga, 'get-minimum-increment');
  }

  method set-current-value is also<set_current_value> {
    self.connect-double($!stga, 'set-current-value');
  }

  method get_type is also<get-type> {
    state ($n, $t);

    unstable_get_type( self.^name, &st_generic_accessible_get_type, $n, $t );
  }

}


### /home/cbwood/Projects/gnome-shell/src/st/st-generic-accessible.h

sub st_generic_accessible_get_type ()
  returns GType
  is native(gnome-shell-st)
  is export
{ * }

sub st_generic_accessible_new_for_actor (MutterClutterActor $actor)
  returns AtkObject
  is native(gnome-shell-st)
  is export
{ * }
