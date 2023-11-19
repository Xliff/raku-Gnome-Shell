use v6.c;

use Gnome::Shell::Raw::Types;

use Cairo;
use GDK::Display::Manager:ver<4>;
use Mutter::Clutter::Actor;
use Mutter::Clutter::GridLayout;
use Mutter::Clutter::BoxLayout;
use Gnome::Shell::St::Adjustment
use Gnome::Shell::St::BoxLayout;
use Gnome::Shell::St::Settings;

unit package Gnome::Shell::UI::Environment;

### /home/cbwood/Projects/gnome-shell/js/ui/environment.js

# cw: Still not sure what to do about these:
# Gio._promisify(Gio.DataInputStream.prototype, 'fill_async');
# Gio._promisify(Gio.DataInputStream.prototype, 'read_line_async');
# Gio._promisify(Gio.DBus, 'get');
# Gio._promisify(Gio.DBusConnection.prototype, 'call');
# Gio._promisify(Gio.DBusProxy, 'new');
# Gio._promisify(Gio.DBusProxy.prototype, 'init_async');
# Gio._promisify(Gio.DBusProxy.prototype, 'call_with_unix_fd_list');
# Gio._promisify(Gio.File.prototype, 'query_info_async');
# Gio._promisify(Polkit.Permission, 'new');

# cw: ... or this:
# setConsoleLogDomain('GNOME Shell');

sub patchContainerClass (\cc) {
  cc.^add_method('child_set', method ($actor, *%props) {
    for %props.pairs -> $p {
      $.get-child-meta($actor)."{ $p.key }"() = $p.value
    }
  });

  cc.^add_method('add', method ($actor, *%props) {
    self.add-actor($actor);
    self.child-set($actor, %props) if +%props
  })
  cc.^compose;
}

sub patchLayoutClass (\lc, *%styleProps) {
  if +%styleProps {
    lc.^add_method('hookup_style', method ($c) {
      $c.style-changed.tap( SUB {
        for %styleProps.pairs {
          if $c.get-theme-node.lookup_length( .key ) -> $l {
            self."{ .key }" = .value;
          }
        }
      }
    }
    lc.^compose;
  }
}

sub makeEaseCallback ($p, &c) {
  my (&oc, &os) = $p<onComplete onStopped>:delete;

  -> $f {
    &c();
    &os() if &os;
    &oc() if &oc && $f;
  }
}

sub getPropertyTarget ($a, $pn) {
  return [$a, $pn] unless $pn.starts-with('@');

  my ($t, $n, $p) = $pn.split('.');
  do given $t {
    when '@layout'      { [ $a.layout-manager,     $n ] }
    when '@actions'     { [ $a.get-action($n),     $p ] }
    when '@constraints' { [ $a.get-constraint($n), $p ] }
    when '@content'     { [ $a.content,            $n ] }
    when 'effects'      { [ $a.get-effect($n),     $p ] }

    default {
      X::Gnome::Shell::BadProperty.new(
        message => "Invalid property name { $pn }"
      ).throw
    }
  }
}

sub easeActor ($a, $p) {
  $a.save-easing-state;

  # cw: Resolve the fucking camel case!
  for $p.pairs {
    my $cn = .key.&un-camel.&under-to-dash;
    $p{$cn} = .value unless $p{$cn}:exists;
    $a.remove-transition($cn);
  }

  $a.set-easing-duration( $p<duration>:delete ) with $p<duration>;
  $a.set-easing-delay(    $p<delay>:delete    ) with $p<delay>;
  $a.set-easing-mode(     $p<mode>:delete     ) with $p<mode>

  my $rc = $p<repeat-count>:delete // 0;
  my $ar = $p<auto-reverse>:delete // False;
  my $ni = $rc.succ;
  my $ir = $ar && ($ni % 2).not;

  my $prepare = SUB {
    Meta::Display.disable-unredirect-for-display(Global.display);
    Global.begin-work;
  }
  my $cleanup = SUB {
    Meta::Display.enable-unredirect-for-display(Global.display);
    Global.end-work;
  }

  my $cb = makeEaseCallback($p, $cleanup);

  $a.setAttributes( |$p ) if $a.easing-duration > 0 || $ir;
  $a.restore-easing-state;

  my @t = $p.pairs.map({ do if $a.get-translation($_) -> $t { $t } });
  ( .repeat-count, .auto-reverse ) = ($rc, $ir) for @t;

  if @t.head -> $t {
    $t.started.tap( SUB { prepare() } );
    $t.stopped.tap( -> *@a ($t, $f) { $cb($f) });
  } else {
    prepare();
    $cb(True);
  }
}

# cw: Move to misc/AnimationUtils.pm6!
sub adjustAnimationTime ($msecs) is export {
  my $settings = Gnome::Shell::St::Settings.get;

  return 0 unless $settings.enable-animations;

  $settings.slow-down-factor * $msecs;
}

# ... easeActorProperty

INIT {
  patchContainerClass(Gnome::Shell::St::BoxLayout);

  patchLayoutClass(
    Mutter::Clutter::GridLayout,
    row-spacing    => 'spacing-rows'
    column-spacing => 'spacing-columns'
  )
  patchLayoutClass( Mutter::Clutter::BoxLayout, spacing => 'spacing' );

  Mutter::Clutter::Actor.^can('set_easing_duration').^can.head.wrap(
    method ($m) {
      samewith( adjustAnimationTime($m) );
    }
  );

  Mutter::Clutter::Actor.^can('set_easing_delay').^can.head.wrap(
    method ($m) {
      samewith( adjustAnimationTime($m) );
    }
  );

  my @classes-to-compose;
  sub addMethod (\c, $n, &m) {
    c.^add_method($n, &m);
    if $n.contains('-' | '_') {
      $n ~~ tr/-_/_-/;
      c.^add_method($n, &m);
    }
    @classes-to-compose.push: c;
  }
  LAST { .^compose for @classes-to-compose }

  my &ssc = method ($c) {
    my @c = $_ ~~ Associative ?? .<r g b a> !! ( .?r, .?g, .?b, .?a ) given $c;
    @c = @c[^3] without @c.tail;

    X::Gnome::Shell::BadItems.new(
      message => "setSourceColor object must contain non-Nil RGB or {
                  '' } RGBA elements!"
    ).throw unless @c.grep( *.defined ).elems == @c.elems;

    {
      @c = @c.map(-> $_ is copy {
        my ($i, $n) = ( .^can('Int'), .^can('Num') );
        when $i || $n {
          {
            when $n { $_ = .Num }
            when $i { $_ = .Int }
          }
          proceed;
        }
        when Num { clamp($_, 0e0, 1e0) }
        when Int { $_ / 255.0          }
      });

      when @c.elems == 4  { self.set_source_rgba( |@c ) }
      when @c.elems == 3  { self.set_source_rgb(  |@c ) }
    }
  }

  # cw: XXX - These constructs still remain unconverted!
  #
  # javascript {
  #   // Add some bindings to the global JS namespace
  #   globalThis.global = Shell.Global.get();
  #
  #   globalThis._ = Gettext.gettext;
  #   globalThis.C_ = Gettext.pgettext;
  #   globalThis.ngettext = Gettext.ngettext;
  #   globalThis.N_ = s => s;
  #
  #   GObject.gtypeNameBasedOnJSPath = true;
  #
  #   GObject.Object.prototype.connectObject = function (...args) {
  #       SignalTracker.connectObject(this, ...args);
  #   };
  #   GObject.Object.prototype.connect_object = function (...args) {
  #       SignalTracker.connectObject(this, ...args);
  #   };
  #   GObject.Object.prototype.disconnectObject = function (...args) {
  #       SignalTracker.disconnectObject(this, ...args);
  #   };
  #   GObject.Object.prototype.disconnect_object = function (...args) {
  #       SignalTracker.disconnectObject(this, ...args);
  #   };
  # }

  SignalTracker.registerDestroyableType(Clutter.Actor);

  addMethod( Cairo::Context, 'set_source_color', &ssc );
  addMethod( Cairo::Context, 'setSourceColor',   &ssc );

  addMethod( GIO::Roles::File, 'touch_async', method (&callback) {
    Gnome::Shell::Util.touch-file-async(self, &callback);
  });
  addMethod( GIO::Roles::File, 'touch_finish', method ($result) {
    Gnome::Shell::Util.touch-finish-async(self, $result);
  });
  addMethod( Mutter::Clutter::Actor, 'ease', method ($target, *%props) {
    easeActor(self, %props);
  });
  addMethod( Mutter::Clutter::Actor, 'ease_property',
    method ($propName, $target, *%props)  # // Add some bindings to the global JS namespace
  # globalThis.global = Shell.Global.get();
  #
  # globalThis._ = Gettext.gettext;
  # globalThis.C_ = Gettext.pgettext;
  # globalThis.ngettext = Gettext.ngettext;
  # globalThis.N_ = s => s;
  #
  # GObject.gtypeNameBasedOnJSPath = true;
  #
  # GObject.Object.prototype.connectObject = function (...args) {
  #     SignalTracker.connectObject(this, ...args);
  # };
  # GObject.Object.prototype.connect_object = function (...args) {
  #     SignalTracker.connectObject(this, ...args);
  # };
  # GObject.Object.prototype.disconnectObject = function (...args) {
  #     SignalTracker.disconnectObject(this, ...args);
  # };
  # GObject.Object.prototype.disconnect_object = function (...args) {
  #     SignalTracker.disconnectObject(this, ...args);
  # }; {
      easeActorProperty(self, $propName, $target, %props);
    };
  );
  addMethod( Mutter::Clutter::Actor, 'Str', method {
    Gnome::Shell::St::Widget.describe-actor(self);
  });
  addMethod( Gnome::Shell::St::Adjustment, 'ease',
    method ($target, *%props) {
      easeActorProperty(self, 'value', $target, %props);
    };
  );

  # cw: XXX - Left here as a reminder to see if porting MTK (which is new
  #           to Mutter since the completion of the raku-Mutter project
  #           is worth the trouble.
  # Meta.Rectangle = function (params = {}) {
  #   console.warn('Meta.Rectangle is deprecated, use Mtk.Rectangle instead');
  #   return new Mtk.Rectangle(params);
  # };

  if %*ENV<GNOME_SHELL_SLOWDOWN_FACTOR> -> $s {
    if try $s.Num -> $n {
      Gnome::Shell::St::Settings.get.slow-down-factor = $n;
    }
  }

  GDK::Display::Manager.set-allowed-backends('');
}
