use v6.c;

use Method::Also;
use NativeCall;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;

use Mutter::Clutter::Effect;

use GLib::Roles::Implementor;

our subset StScrollViewFadeAncestry is export of Mu
  where StScrollViewFade | MutterClutterEffectAncestry;

class Gnome::Scroll::View::Fade is Mutter::Clutter::Effect {
  has StScrollViewFade $!stsvf is implementor;

  submethod BUILD ( :$st-scroll-view-fade ) {
    self.setStScrollViewFade($st-scroll-view-fade) if $st-scroll-view-fade;
  }

  method setStScrollViewFade (StScrollViewFadeAncestry $_) {
    my $to-parent;

    $!stsvf = do {
      when StScrollViewFade {
        $to-parent = cast(MutterClutterEffect, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StScrollViewFade, $_);
      }
    }
    self.setMutterClutterEffect($to-parent);
  }

  method Mutter::Cogl::Raw::Definitions::StScrollViewFade
    is also<StScrollViewFade>
  { $!stsvf }

  multi method new (
    StScrollViewFadeAncestry  $st-scroll-view-fade,
                             :$ref                  = True
  ) {
    return unless $st-scroll-view-fade;

    my $o = self.bless( :$st-scroll-view-fade );
    $o.ref if $ref;
    $o;
  }

  multi method new {
    my $st-scroll-view-fade = st_scroll_view_fade_new();

    $st-scroll-view-fade ?? self.bless( :$st-scroll-view-fade ) !! Nil;
  }

  # Type: MutterClutterMargin
  method fade-margins is rw  is g-property is also<fade_margins> {
    my $gv = GLib::Value.new( MutterClutterMargin.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('fade-margins', $gv);
        cast(MutterClutterMargin, $gv.pointer);
      },
      STORE => -> $, MutterClutterMargin() $val is copy {
        $gv.pointer = $val;
        self.prop_set('fade-margins', $gv);
      }
    );
  }

  # Type: boolean
  method fade-edges is rw  is g-property is also<fade_edges> {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('fade-edges', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        $gv.boolean = $val;
        self.prop_set('fade-edges', $gv);
      }
    );
  }

  # Type: boolean
  method extend-fade-area is rw  is g-property is also<extend_fade_area> {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('extend-fade-area', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        $gv.boolean = $val;
        self.prop_set('extend-fade-area', $gv);
      }
    );
  }

}


### /home/cbwood/Projects/gnome-shell/src/st/st-scroll-view-fade.h

sub st_scroll_view_fade_new ()
  returns StScrollViewFade
  is native(gnome-shell-st)
  is export
{ * }
