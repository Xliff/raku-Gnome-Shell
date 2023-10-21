use v6.c;

use Gnome::Shell::Raw::Types;

constant ANIMATED_ICON_UPDATE_TIMEOUT is export = 16;
constant SPINNER_ANIMATION_TIME       is export = 300;
constant SPINNER_ANIMATION_DELAY      is export = 1000;

### /home/cbwood/Projects/gnome-shell/js/ui/animation.js

class Gnome::Shell::UI::Animation is Gnome::Shell::St::Bin {
  has $!speed;
  has $!isLoaded;
  has $!isPlaying;
  has $!timeoutId;
  has $!frame;

  submethod BUILD ( :$width, :$height, :$file, :$!speed ) {
    my $themeContext = Gnome::Shell::UI::ThemeContext.get-for-stage(
      global.stage
    );

    self.style = "width: { $width }px; height: { $height }px";
    self.destroy.tap( -> *@a { self.onDestroy( |@a ) });
    self.resource-scale-changed.tap( -> *@a {
      self.loadFile($file, $width, $height)
    }):

    $themeContext.notify('scale-factor').tap( -> *@a {
      self.loadFile($file, $width, $height);
      self.set-size(
        $width  * $themeContext.scale-factor,
        $height * $themeContext.scale-factor
      );

      ( .isLoaded, .isPlaying ) = False xx 2 given self;
      ( .timeoutId, .frame )    = 0 xx 2     given self;

      self.loadFile($!file, $width, $height);
    });
  }

  method play {
    if $!isLoaded && $!timeoutId.not {
      self.showFrame(0) if $frame.not;

      $!timeoutId = GLib::Timeout.add(G_PRIORITY_LOW, $!speed, -> *@a {
        self.update( |@a )
      });
      GLib::Source.set-name-by-id(
        $!timeoutId,
        '[raku-gnome-shell]  self.update'
      );
    }

    $!isPlaying = True;
  }

  method stop {
    if $!timeoutId > 0 {
      GLib::Source.remove($!timeoutId);
      $!timeoutId = 0;
    }

    $!isPlaying = False;
  }

  method loadFile ($file, $width, $height) {
    my $resourceScale = self.get-resource-scale;
    my $wasPlaying = $!isPlaying;

    self.stop if $!isPlaying;
    $!isLoaded = False;
    self.destroy-all-children;

    my $textureCache = Gnome::Shell::St::TextureCache.get-default;
    my $scaleFactor  = Gnome::Shell::St::ThemeContext.get-for-stage(
      global.stage
    ).scale-factor;

    $!animations = $textureCache.load-sliced-image(
      $!file,
      $width,
      $height,
      $scaleFactor,
      $resourceScale,
      -> *@a {
        self.animationsLoaded( |@a )
      }
    });

    $!animations.set(
      x-align => CLUTTER_ACTOR_ALIGN_CENTER,
      y-align => CLUTTER_ACTOR_ALIGN_CENTER
    );
    self.set-child($!animations);

    self.play if $wasPlaying;
  }

  method showFrame ($frame) {
    my $oldFrameActor = $!animations.get-child-at-index($!frame);
    $oldFrameActor.hide if $oldFrameActor;
    $!frame %= $!animations.elems;

    my $newFrameActor = $!animations.get-child-at-index($!frame);
    $newFrameActor.show if $!newFrameActor;
  }

  method update {
    self.showFrame($frame.succ);
    return G_SOURCE_CONTINUE;
  }

  method syncAnimationSize {
    return unless self.isLoaded;

    my ($width, $height) = self.get-size;
    .set-size($width, $height) for $!animations.get-children;
  }

  method animationsLoaded {
    $!isLoaded = $!animations.elems.so;
    self.syncAnimationSize;
    self.play if $!isPlaying;
  }

  method onDestroy {
    self.stop
  }

}

class Gnome::Shell::UI::Animations::Icon
  is Gnome::Shell::UI::Animation
{
  submethod BUILD ( :$file, :$size ) {
    ( .width, .height ) = $size xx 2;
  }

  method new ($file, $size, $speed ) {
    self.bless( :$file,  :$size, :$speed )
  }
}

class Gnome::Shell::UI::Animations::Spinner
  is Gnome::Shell::UI::Animations::Icon
{
  has $!animate    is built;
  has $!hideOnStop is built;

  submethod BUILD ( :$size, :$params, :$!animate, :$!hideOnStop ) {
    $params<animate>    //= False;
    $params<hideOnStop> //= False;

    my $file = GIO::File.new-for-uri(
      'resource:///org/gnome/shell/theme/process-working.svg'
    );

    self.opacity = 0;
    self.visible = $hideOnStop.not;
  }

  method DESTROY {
    $!animate = False;
    self.onDestroy;
  }

  method play {
    self.remove-all-transitions;
    self.show;
    if $!animate {
      self.play;
      self.ease(
        opacity  => 255,
        delay    => SPINNER_ANIMATION_DELAY,
        duration => SPINNER_ANIMATION_TIME,
        mode     => CLUTTER_LINEAR
      );
    } else {
      self.opacity = 255;
      self.play;
    }
  }

  method stop {
    self.remove-all-transitions;
    if $!animate {
      self.ease(
        opacity  => 0,
        duration => SPINNER_ANIMATION_TIME,
        mode     => CLUTTER_LINEAR,
        onComplete => -> *@a {
          self.stop;
          self.hide if $!hideOnStop;
        }
      );
    } else {
      self.opacity = 0;
      self.stop
    }
  }

}
