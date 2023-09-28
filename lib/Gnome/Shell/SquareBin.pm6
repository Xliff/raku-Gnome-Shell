use v6.c;

use Method::Also;
use NativeCall;

use Gnome::Shell::Raw::Types;

use Gnome::Shell::St::Bin;

use GLib::Roles::Implementor;

our subset ShellSquareBinAncestry is export of Mu
  where ShellSquareBin | StBinAncestry;

class Gnome::Shell::SquareBin is Gnome::Shell::St::Bin {
  has ShellSquareBin $!ssb is implementor;

  submethod BUILD ( :$shell-square-bin ) {
    self.setShellSquareBin($shell-square-bin)
      if $shell-square-bin
  }

  method setShellSquareBin (ShellSquareBinAncestry $_) {
    my $to-parent;

    $!ssb = do {
      when ShellSquareBin {
        $to-parent = cast(StBin, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellSquareBin, $_);
      }
    }
    self.setStBin($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::ShellSquareBin
    is also<ShellSquareBin>
  { $!ssb }

  multi method new (ShellSquareBinAncestry $shell-square-bin, :$ref = True) {
    return unless $shell-square-bin;

    my $o = self.bless( :$shell-square-bin );
    $o.ref if $ref;
    $o;
  }
  multi method new {
    my $shell-square-bin = GLib::Object.new(self.get_type, :no-bless);

    $shell-square-bin ?? self.bless( :$shell-square-bin ) !! Nil;
  }

  method get_type {
    state ($n, $t);

    unstable_get_type( self.^name, &shell_square_bin_get_type, $n, $t );
  }

}

### /home/cbwood/Projects/gnome-shell/src/shell-square-bin.h

sub shell_square_bin_get_type
  returns GType
  is      export
  is      native(gnome-shell)
{ * }
