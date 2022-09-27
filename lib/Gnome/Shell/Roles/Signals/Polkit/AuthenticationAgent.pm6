use v6.c;

use NativeCall;

use Gnome::Shell::Raw::Types;

role Gnome::Shell::Roles::Signals::Polkit::AuthenticationAgent {
  has %!signals-spaa;

  # Str, Str, Str, Str, GStrV
  method connect-initiate (
    $obj,
    $signal = 'initiate',
    &handler?
  ) {
    my $hid;
    %!signals-spaa{$signal} //= do {
      my \𝒮 = Supplier.new;
      $hid = g-connect-initiate($obj, $signal,
        -> $, $s1, $s2, $s3, $s4, $sv {
          CATCH {
            default { 𝒮.note($_) }
          }

          𝒮.emit( [$s1, $s2, $s3, $s4, $sv] );
        },
        Pointer, 0
      );
      [ 𝒮.Supply, $obj, $hid ];
    };
    %!signals-spaa{$signal}[0].tap(&handler) with &handler;
    %!signals-spaa{$signal}[0];
  }

}

# Str, Str, Str, Str, GStrV
sub g-connect-initiate (
 Pointer $app,
 Str     $name,
         &handler (Str, Str, Str, Str, GStrv),
 Pointer $data,
 uint32  $flags
)
  returns uint64
  is native(gobject)
  is symbol('g_signal_connect_object')
{ * }
