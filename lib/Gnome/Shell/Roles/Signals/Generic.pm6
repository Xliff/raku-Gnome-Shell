use v6.c;

use NativeCall;

use Gnome::Shell::Raw::Types;

role Gnome::Shell::Roles::Signals::Generic {
  has %!signals-gsg;

  # ShellApp
  method connect-shell-app (
    $obj,
    $signal,
    &handler?
  ) {
    my $hid;
    %!signals-gsg{$signal} //= do {
      my \𝒮 = Supplier.new;
      $hid = g-connect-shell-app($obj, $signal,
        -> $, $sa {
          CATCH {
            default { 𝒮.note($_) }
          }

          𝒮.emit( [self, $sa] );
        },
        Pointer, 0
      );
      [ 𝒮.Supply, $obj, $hid ];
    };
    %!signals-gsg{$signal}[0].tap(&handler) with &handler;
    %!signals-gsg{$signal}[0];
  }

}

# ShellApp
sub g-connect-shell-app (
 Pointer $app,
 Str     $name,
         &handler (ShellAppSystem, ShellApp),
 Pointer $data,
 uint32  $flags
)
  returns uint64
  is native(gobject)
  is symbol('g_signal_connect_object')
{ * }
