use v6.c;

use Method::Also;

use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::IconColors;

# BOXED

use GLib::Roles::Implementor;

class Gnome::Shell::IconColors {
  also does GLib::Roles::Implementor;

  has StIconColors $!stic is implementor handles <
    foreground
    warning
    error
    success
  >;

  submethod BUILD ( :$st-icon-colors ) {
    $!stic = $st-icon-colors;
  }

  method Gnome::Shell::Raw::StructS::StIconColors
    is also<StIconColors>
  { $!stic }

  method new {
    my $st-icon-colors = st_icon_colors_new();

    $st-icon-colors ?? self.bless( :$st-icon-colors ) !! Nil;
  }

  method copy ( :$raw = False ) {
    propReturnObject(
      st_icon_colors_copy($!stic),
      $raw,
      |self.getTypePair
    );
  }

  method equal (StIconColors() $other) {
    so st_icon_colors_equal($!stic, $other);
  }

  method get_type is also<get-type> {
    state ($n, $t);

    unstable_get_type( self.^name, &st_icon_colors_get_type, $n, $t );
  }

  method ref {
    st_icon_colors_ref($!stic);
    self;
  }

  method unref {
    st_icon_colors_unref($!stic);
  }

}
