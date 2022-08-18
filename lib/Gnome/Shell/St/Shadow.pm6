use v6.c;

use Method::Also;

use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::St::Shadow;

use GLib::Roles::Implementor;

# BOXED

class Gnome::Shell::St::Shadow {
  has StShadow $!sts is implementor;

  submethod BUILD ( :$st-shadow ) {
    $!sts = $st-shadow
  }

  method Gnome::Shell::Raw::Structs::StShadow
    is also<StShadow>
  { $!sts }

  method new (
    MutterClutterColor() $color,
    Num()                $xoffset,
    Num()                $yoffset,
    Num()                $blur,
    Num()                $spread,
    Int()                $inset
  ) {
    my gboolean $i = $inset.so.Int;

    my $st-shadow = st_shadow_new(
      $color,
      $xoffset,
      $yoffset,
      $blur,
      $spread,
      $i
    );

    $st-shadow ?? self.bless( :$st-shadow ) !! Nil;
  }

  method equal (StShadow() $other) {
    st_shadow_equal($!sts, $other);
  }

  proto method get_box (|)
    is also<get-box>
  { * }

  multi method get_box (MutterClutterActorBox() $actor_box) {
    samewith($actor_box, Mutter::Clutter::ActorBox.alloc);
  }
  multi method get_box (
    MutterClutterActorBox()  $actor_box,
    MutterClutterActorBox()  $shadow_box,
                            :$raw         = False
  ) {
    st_shadow_get_box($!sts, $actor_box, $shadow_box);

    propReturnObject(
      $shadow_box,
      $raw,
      |Mutter::Clutter::ActorBox.getTypePair
    );
  }

  method get_type is also<get-type> {
    state ($n, $t);

    unstable_get_type( self.^name, &st_shadow_get_type, $n, $t );
  }

  method ref {
    st_shadow_ref($!sts);
    self;
  }

  method unref {
    st_shadow_unref($!sts);
  }

}

# BOXED TOO!

class Gnome::Shell::St::Shadow::Helper {
  has StShadowHelper $!stsh is implementor;

  submethod BUILD ( :$st-shadow-helper ) {
    $!stsh = $st-shadow-helper;
  }

  method Gnome::Shell::Raw::Structs::StShadowHelper
    is also<StShadowHelper>
  { $!stsh }

  method new (StShadow() $shadow) {
    my $st-shadow-helper = st_shadow_helper_new($shadow);

    $st-shadow-helper ?? self.bless( :$st-shadow-helper ) !! Nil;
  }

  method copy {
    st_shadow_helper_copy($!stsh);
  }

  method free {
    st_shadow_helper_free($!stsh);
  }

  method get_type is also<get-type> {
    state ($n, $t);

    unstable_get_type( self.^name, &st_shadow_helper_get_type, $n, $t );
  }

  method paint (
    MutterCoglFramebuffer() $framebuffer,
    MutterClutterActorBox() $actor_box,
    Int()                   $paint_opacity
  ) {
    my guint8 $p = $paint_opacity;

    st_shadow_helper_paint($!stsh, $framebuffer, $actor_box, $p);
  }

  method update (MutterClutterActor() $source) {
    st_shadow_helper_update($!stsh, $source);
  }

}
