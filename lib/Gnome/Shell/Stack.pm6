use v6.c;

use Method::Also;
use NativeCall;

use Gnome::Shell::Raw::Types;

use Gnome::Shell::St::Widget;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

our subset ShellStackAncestry is export of Mu
  where ShellStack | StWidgetAncestry;

class Gnome::Shell::Stack is Gnome::Shell::St::Widget {
  has ShellStack $!ssb is implementor;

  submethod BUILD ( :$shell-stack ) {
    self.setShellStack($shell-stack) if $shell-stack
  }

  method setShellStack (ShellStackAncestry $_) {
    my $to-parent;

    $!ssb = do {
      when ShellStack {
        $to-parent = cast(StWidget, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellStack, $_);
      }
    }
    self.setStWidget($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::ShellStack
    is also<ShellStack>
  { $!ssb }

  multi method new (ShellStackAncestry $shell-stack, :$ref = True) {
    return unless $shell-stack;

    my $o = self.bless( :$shell-stack );
    $o.ref if $ref;
    $o;
  }
  multi method new {
    my $shell-stack = GLib::Object.new(self.get_type, :no-bless);

    $shell-stack ?? self.bless( :$shell-stack ) !! Nil;
  }

  method get_type {
    state ($n, $t);

    unstable_get_type( self.^name, &shell_square_bin_get_type, $n, $t );
  }

}

### /home/cbwood/Projects/gnome-shell/src/shell-stack.h

sub shell_square_bin_get_type
  returns GType
  is      export
  is      native(gnome-shell)
{ * }
