use v6.c;

use NativeCall;

use Gnome::Shell::Raw::Types;

use Mutter::Clutter::Accessible::Actor;

our subset StWidgetAccessibleAncestry is export of Mu
  where StWidgetAccessible | MutterClutterActorAccessibleAncestry;

class Gnome::Shell::St::Accessible::Widget
  is Mutter::Clutter::Accessible::Actor
{
  has StWidgetAccessible $!stwa is implementor;

  submethod BUILD ( :$st-widget-accessible ) {
    self.setStWidgetAccessible($st-widget-accessible) if $st-widget-accessible
  }

  method setStWidgetAccessible (StWidgetAccessibleAncestry $_) {
    my $to-parent;

    $!stwa = do {
      when StWidgetAccessible {
        $to-parent = cast(MutterClutterActorAccessible, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StWidgetAccessible, $_);
      }
    }
    self.setMutterClutterActorAccessible($to-parent);
  }

  method Gnome::Shell::::Raw::Definitions::StWidgetAccessible
    is also<StWidgetAccessible>
  { $!stwa }

  multi method new (
    $st-widget-accessible where * ~~ StWidgetAccessibleAncestry,

    :$ref = True
  ) {
    return unless $st-widget-accessible;

    my $o = self.bless( :$st-widget-accessible );
    $o.ref if $ref;
    $o;
  }

  method get_type {
    state ($n, $t);

    unstable_get-type(self.^name, &st_widget_accessible_get_type, $n, $a );
  }

}

### /home/cbwood/Projects/gnome-shell/src/st/st-widget-accessible.h

sub st_widget_accessible_get_type
  returns GType
  is      native(gnome-shell)
  is      export
{ * }
