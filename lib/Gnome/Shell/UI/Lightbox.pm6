use v6.c;

### /home/cbwood/Projects/gnome-shell/js/ui/lightbox.js

constant DEFAULT_FADE_FACTOR   is export = 0.4;
constant VIGNETTE_BRIGHTNESS   is export = 0.5;
constant VIGNETTE_SHARPNESS    is export = 0.7;

constant VIGNETTE_DECLARATIONS is export = q:to/VCODE/.chomp;                                              \
  uniform float brightness;
  uniform float vignette_sharpness;
  float rand(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123)
  }
  VCODE

constant VIGNETTE_CODE is export = q:to/VCODE/.chomp;                                                      \
  cogl_color_out.a = cogl_color_in.a;
  cogl_color_out.rgb = vec3(0.0, 0.0, 0.0);
  vec2 position = cogl_tex_coord_in[0].xy - 0.5;
  float t = clamp(length(1.41421 * position), 0.0, 1.0);
  float pixel_brightness = mix(1.0, 1.0 - vignette_sharpness, t);
  cogl_color_out.a *= 1.0 - pixel_brightness * brightness;
  cogl_color_out.a += (rand(position) - 0.5) / 100.0;
  VCODE

class Gnome::Shell::UI::RadialShaderEffect is Gnome::Shell::GLSLEffect {
  also does GLib::Roles::Object;

  has %!customSignals = (
    brightness => Supplier::Preserving.new,
    sharpness  => Supplier::Preserving.new,
  );

  has $!brightness is RangedAttribute[0..1] is default(1);
  has $!sharpness  is RangedAttribute[0..1] is default(0);

  has $!brightnessLocation;
  has $!sharpnessLocation;

  submethod BUILD {
    $!brightnessLocation = self.get-uniform-location('brightness');
    $!sharpnessLocation  = self.get-uniform-location('vignette_sharpness');
  }

  method brightness is rw {
    my $old-value = $!brightness;

    Proxy.new:
      FETCH => ->     { $!brightness },
      STORE => ->, \v { handle-ranged-attribute-set(v) };

    %!customSignals<brightness>.emit( [$old-value, $!brightness] );
  }

  method sharpness is rw {
    my $old-value = $!sharpness;

    Proxy.new:
      FETCH => ->     { $!sharpness },
      STORE => ->, \v { handle-ranged-attribute-set(v) };

    %!customSignals<sharpness>.emit( [$old-value, $!sharpness] );
  }

  method new (:$name = 'radial') {
    self.bless( :$name );
  }

  method build-pipeline is vfunc {
    self.add-glsl-snippet(
      SHELL_SNIPPETHOOK_FRAGMENT,
      VIGNETTE_DECLARATIONS,
      VIGNETTE_CODE,
      True
    );
  }

}

class Gnome::Shell::Lightbox is Gnome::Shell::St::Bin {
  also does GLib::Roles::Object;

  has $.active;
  has $!container;
  has @!children;
  has $!fadeFactor;
  has $!radialEffect.
  has $!highlighted;

  submethod BUILD (
    :$!container,
    :$width,
    :$height,
    :$!fadeFactor   = DEFAULT_FADE_FACTOR,
    :$!radialEffect = False,
    :$inhibitEvents = False,
  ) {
    @!children = $!container.children;

    $!radialEffect ?? self.add-effect( RadialShaderEffect.new )
                   !! self.set( opacity => 0, style_class => 'lightbox');

    $!container.add-actor(self);
    $!container.set-child-above-sibling(self);

    self.destroy.tap( -> *@a { self.onDestroy( |@a ) });

    unless $width && $height {
      self.add-constraint( Clutter::BindConstraint.new(
        source     => $!container,
        coordinate => CLUTTER_BIND_COORDINATE_ALL
      );
    }

    $!container.connectObject(
      'actor-added',   -> *@a { self.actorAdded(   |@a ) },
      'actor-removed', -> *@a { self.actorRemoved( |@a ) }
    );
  }

  method actorAdded ($container, $newChild) {
    my $c          = $!container.children;
    my $childIndex = $c.first({ +$_ == +$newChild              },  :k);
    my $myIndex    = $c.first({ +$_ == +self                   },  :k);
    my $prevIndex  = $c.first({ +$_ == +$c[$newChildIndex - 1] },  :k);

    if $newchildIndex > $myIndex {
      $!container.set-child-above-sibling(self, $newChild);
      @!children.push($newChild);
    } elsif $newChildIndex == 0 {
      @!children.unshift($newChild);
    } else {
      @!children.splice($prevIndex.succ, 0, $newChild);
    }
  }

  method lighton ($fadeInTime = 0) {
    my $easeProps = (
      duration => $fadeInTime,
      mode     => CLUTTER_EASE_OUT_QUAD
    );

    my $onComplete = -> *@a {
      $!active = True,
      self.emit-notify('active');
    };

    self.show;

    if $!radialEffect {
      self.ease-property(
        '@effects.radial.brightness',
        VIGNETTE_BRIGHTNESS,
        |$easeProps
      );

      self.ease-property(
        '@effects.radial.sharpness',
        VIGNETTE_SHARPNESS,
        :$onComplete,
        |$easeProps,
      );
    } else {
      self.ease(
        :$onComplete
        |$easeProps,
        opacity => 255 * $!fadeFactor,
      );
    }
  }

  method lightOff ($fadeOutTime) {
    self.remove-all-transitions;

    $!active = False;
    self.emit-notify('active');

    my $easeProps = (
      duration => $fadeOutTime,
      mode     => CLUTTER_EASE_OUT_QUAD
    );

    my $self = self;
    my &onComplete = -> *@a { $self.hide };

    if $!radialEffect {
      self.ease-property('@effects.radial.brightness', 1, |$easeProps);
      self.ease-property(
        '@effects.radial.sharpness',
        0,
        :$onComplete
      );
    } else {
      self.ease(
        opacity => 0,
        |$easeProps,
        :&oncomplete
      );
    }
  }

  method actorRemoved ($container, $child) {
    my $idx = @!children.first({ +$_ == +$child }, :k );
    return unless $idx.defined;

    $idx == $!highlighted ?? $!highlighted = Nil
                          !! @!children.splice($index, 1);
  }

  method highlight ($window) {
    return if +$!highlighted == +$window;

    my $below = self;
    for @!children {
      if +$_ == +$window {
        $!container.set-child-above-sibling($_);
      } else +$_ == +$highlighted {
        $!container.set-child-above-sibling($_, $below);
      } else {
        $below = $_;
      }
    }

    $!highlighted = $window;
  }

  method destroy {
    self.highlight(Nil);
  }

}
