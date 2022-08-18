use v6.c;

use Method::Also;
use NativeCall;

use Gnome::Shell::Raw::Types;

use Gnome::Shell::St::Widget;

use GLib::Roles::Implementor;

our subset StBinAncestry is export of Mu
  where StBin | StWidgetAncestry;

class Gnome::Shell::St::Bin is Gnome::Shell::St::Widget {
  has StBin $!stb is implementor;

  submethod BUILD ( :$st-bin ) {
    self.setStBin($st-bin) if $st-bin
  }

  method setStBin (StBinAncestry $_) {
    my $to-parent;

    $!stb = do {
      when StBin {
        $to-parent = cast(StWidget, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StBin, $_);
      }
    }
    self.setStWidget($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::StBin
    is also<StBin>
  { $!stb }

  multi method new (StBinAncestry $st-bin, :$ref = True) {
    return unless $st-bin;

    my $o = self.bless( :$st-bin );
    $o.ref if $ref;
    $o;
  }

  multi method new {
    my $st-bin = st_bin_new();

    $st-bin ?? self.bless( :$st-bin ) !! Nil;
  }

  method get_child ( :$raw = False ) is also<get-child> {
    propReturnObject(
      st_bin_get_child($!stb),
      $raw,
      |Mutter::Clutter::Actor.getTypePair
    );
  }

  method set_child (MutterClutterActor() $child) is also<set-child> {
    st_bin_set_child($!stb, $child);
  }

}


### /home/cbwood/Projects/gnome-shell/src/st/st-bin.h

sub st_bin_get_child (StBin $bin)
  returns MutterClutterActor
  is native(gnome-shell-st)
  is export
{ * }

sub st_bin_new ()
  returns StBin
  is native(gnome-shell-st)
  is export
{ * }

sub st_bin_set_child (StBin $bin, MutterClutterActor $child)
  is native(gnome-shell-st)
  is export
{ * }
