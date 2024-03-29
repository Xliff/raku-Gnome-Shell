use v6.c;

use Mutter::Clutter::PropertyTransition;

role Gnome::Shell::Roles::ActorEase {
  has $!default-time;
  has $!default-mode;

  method set-easing-defaults ( :$time, :$mode ) {
    $!default-time = $time,
    $!default-mode = $mode;
  );

  method ease-time is rw {
    Proxy.new:
      FETCH -> $     { $!default-time },
      STORE => $, \v { $!default-time = v }
  }

  method ease-mode is rw {
    Proxy.new:
      FETCH -> $     { $!default-mode },
      STORE => $, \v { $!default-mode = v }
  }

  method ease (
    :ease-time(:ease_time(:$time)) = $!default-time,
    :ease-mode(:ease_mode(:$mode)) = $!default-mode,
    :$delay                        = 0
    :$onComplete,
    :$onStopped,

    *%props
  ) {
    sub setProp ($n) {
      my $t = %props{$n}:delete;
      given $t {
        when .elems == 2 {
          ( .{ "{$name}-x" } >, .{ "{$name}-y" } ) = $t
            given %props
        }
        when Num | Int {
          ( .{ "{$name}-x" } >, .{ "{$name}-y" } ) = $t xx 2
            given $props
        }
        default {
          X::Gnome::Shell::Error.new(
            "Do not know how to get { $name } values from { .^name }"
          ).throw;
        }
      }
    }

    setProp('translation') if %props<translation>;
    setProp('scale')       if %props<scale>;

    for %props.pairs {
      my $pt = Clutter::PropertyTransition.new( .key ).setup(
        to            => .value,
        duration      => $time,
        progress-mode => $mode,

        :$delay
      );
      $pt.complete.tap( -> *@a {
        $onComplete( |@a );
      }) if $onComplete;
      $pt.stopped.tap( -> (@a {
        $onStopped( |@a );
      });

      self.add-transition($pt);
    }
  }

}
