use v6.c;

use Method::Also;
use NativeCall;

use Gnome::Shell::Raw::Types;

use Mutter::Clutter::TextBuffer;

use GLib::Roles::Implementor;

our subset ShellSecureTextBufferAncestry is export of Mu
  where ShellSecureTextBuffer | MutterClutterTextBufferAncestry;

class Gnome::Shell::SecureTextBuffer is Mutter::Clutter::TextBuffer {
  has ShellSecureTextBuffer $!sstb is implementor;

  submethod BUILD ( :$shell-secure-text-buffer ) {
    self.setShellSecureTextBuffer($shell-secure-text-buffer)
      if $shell-secure-text-buffer
  }

  method setShellSecureTextBuffer (ShellSecureTextBufferAncestry $_) {
    my $to-parent;

    $!sstb = do {
      when ShellSecureTextBuffer {
        $to-parent = cast(MutterClutterTextBuffer, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellSecureTextBuffer, $_);
      }
    }
    self.setMutterClutterTextBuffer($to-parent);
  }

  method Mutter::Cogl::Raw::Definitions::ShellSecureTextBuffer
    is also<ShellSecureTextBuffer>
  { $!sstb }

  multi method new (
    ShellSecureTextBufferAncestry  $shell-secure-text-buffer,
                                  :$ref                       = True
  ) {
    return unless $shell-secure-text-buffer;

    my $o = self.bless( :$shell-secure-text-buffer );
    $o.ref if $ref;
    $o;
  }
  multi method new {
    my $shell-secure-text-buffer = shell_secure_text_buffer_new();

    $shell-secure-text-buffer ?? self.bless( :$shell-secure-text-buffer )
                              !! Nil;
  }

  method get_type is also<get-type> {
    state ($n, $t);

    unstable_get_type(self.^name, &shell_secure_text_buffer_new, $n, $t );
  }

}


### /home/cbwood/Projects/gnome-shell/src/shell-secure-text-buffer.h

sub shell_secure_text_buffer_new ()
  returns ShellSecureTextBuffer
  is      native(gnome-shell)
  is      export
{ * }

sub shell_secure_text_buffer_get_type
  returns GType
  is      native(gnome-shell)
  is      export
{ * } 
