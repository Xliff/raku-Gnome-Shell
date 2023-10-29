#!/usr/bin/env perl6
use v6.c;

use File::Find;
use DOM::Tiny;

my @defined-sigs = (
  [ 'gpointer',        'void', 'connect'       ],
  [ 'guint, gpointer', 'void', 'connect-uint'  ],
);

sub MAIN (
  $control           is copy,
  :$dir,
  :$var              is copy = 'w',
  :$lib              is copy = 'gobject',
  :data(:$user-data)         = True,
) {
  my @files = find(
    :$dir,

    name => *.starts-with("signal.{ $control }")
  ).sort( *.basename );

  my $v = '$!' ~ $var;
  my %signals;
  for @files {
    my $d = DOM::Tiny.parse( .slurp );
    my @n = $d.find("span.n").map( *.text );

    my $rt;
    $rt = @n.shift unless $d.find("pre")[1].children[1]<class> eq "kt";

    (my $mn = @n.shift) ~~ tr/-_/_-/;

    say "Found signal '$mn'...";

    my @s-sig = @n.rotor(2);
    %signals{$mn} = {
      :$rt,
      :$mn,
      :$v,
      :@s-sig,
    };

    %signals{$mn}<udm> = @s-sig.elems == 2 && @s-sig.tail.head eq 'gpointer';
  }


  # Output in-class handlers
  for %signals.pairs {
    my $rt = ( .value<rt> // '' ).trim;
    $rt = $rt ?? " --> { $rt }" !! '';

    given .value {
      say qq:to/METH/;
        # Is originally:
        # { .<s-sig>.join(', ') } { $rt  }
        method { .<mn> } \{
          self.{ .<udm> ?? "connect({ .<v> }, '{ .<mn> }')"
                        !! "connect-{ .<mn> }({ .<v> })" };
        \}
      METH
    }

  }

  # Output role code
  # Handle return type!!
  for %signals.pairs.sort( *.key ) {
    my %vars;
    my @p = .value<s-sig>.skip(1);
    @p = @p.reverse.skip(1).reverse if $user-data;

    my $rt = ( .value<rt> // '' ).trim;
    $rt = $rt ?? " --> { $rt }" !! '';

    my $name = $v.substr(2);

    my $emission;
    my $params = @p.map( '$' ~ *.tail ).join(', ');
    my $s-params = "{ $params ?? ", { $params }" !! ''}";
    if $user-data {
      $params   = $params ?? ", { $params }" !! '';
      $s-params = "self{ $params }, \$ud";
      $params   = "{ $params }, \$ud";
    }
    if $rt.defined && $rt.trim && $rt.trim ne 'void' {
      $emission = qq:to/NONVOID/.chomp;
                my \$r = ReturnedValue.new;
                𝒮.emit( [{ $s-params }, \$r] );
                \$r.r;
      NONVOID
    } else {
      $emission = qq:to/VOID/.chomp;
                𝒮.emit( [{ $s-params }] );
      VOID
    }

    # We use 𝒮 as opposed to 's' to prevent a naming collision.
    # between the Supplier and the parameters in the pointy block.
    # my $ud = $user-data ?? ', $ud' !! '';
    say qq:to/METH/;
  # { @p.join(', ') }{ $rt }
  method connect-{ .value<mn> } (
    \$obj,
    \$signal = '{ .value<mn> }',
    \&handler?
  ) \{
    my \$hid;
    \%!signals-{ $name }\{\$signal\} //= do \{
      my \\𝒮 = Supplier.new;
      \$hid = g-connect-{ .value<mn> }(\$obj, \$signal,
        -> \${ $params } \{
          CATCH \{
            default \{ 𝒮.note(\$_) \}
          \}

{ $emission }
        \},
        Pointer, 0
      );
      [ 𝒮.Supply, \$obj, \$hid ];
    \};
    \%!signals-{ $name }\{\$signal\}[0].tap(\&handler) with \&handler;
    \%!signals-{ $name }\{\$signal\}[0];
  \}
METH

  }

  # Emit non-default nativecall defs
  for %signals.pairs.sort( *.key ) {
    my $rt = ( .value<rt> // '' ).trim;
    $rt = $rt ?? " --> { $rt }" !! '';
    my @s-sig = .value<s-sig>;
    my $c = +@s-sig ?? ', ' !! ' ';

    say qq:to/NC/;
# { .value<s-sig>.join(', ') }{ $rt }
sub g-connect-{ .value<mn> } (
  Pointer \$app,
  Str \$name,
  \&handler ({ .value<s-sig>.map({ ' ' ~ .split(' ').head }).join(', ').trim }{
  $rt }),
  Pointer \$data,
  uint32 \$flags
)
  returns uint64
  is native({ $lib })
  is symbol('g_signal_connect_object')
\{ \* \}
NC

  }

}
