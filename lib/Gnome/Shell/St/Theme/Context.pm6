use v6.c;

use Method::Also;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::St::Theme::Context;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

our subset StThemeContextAncestry is export of Mu
  where StThemeContext | GObject;

class Gnome::Shell::St::Theme::Context {
  also does GLib::Roles::Object;

  has StThemeContext $!sttc is implementor;

  submethod BUILD ( :$st-theme-context ) {
    self.setStThemeContext($st-theme-context) if $st-theme-context
  }

  method setStThemeContext (StThemeContextAncestry $_) {
    my $to-parent;

    $!sttc = do {
      when StThemeContext {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StThemeContext, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::StThemeContext
    is also<StThemeContext>
  { $!sttc }

  multi method new (StThemeContextAncestry $st-theme-context, :$ref = True) {
    return unless $st-theme-context;

    my $o = self.bless( :$st-theme-context );
    $o.ref if $ref;
    $o;
  }
  multi method new is static {
    my $st-theme-context = st_theme_context_new();

    $st-theme-context ?? self.bless( :$st-theme-context ) !! Nil;
  }

  method get_for_stage ( MutterClutterStage() $stage )
    is static
    is also<get-for-stage>
  {
    my $st-theme-context = st_theme_context_get_for_stage($stage);

    $st-theme-context ?? self.bless( :$st-theme-context ) !! Nil;
  }

  # Type: int
  method scale-factor is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_INT );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('scale-factor', $gv);
        $gv.int;
      },
      STORE => -> $, Int() $val is copy {
        $gv.int = $val;
        self.prop_set('scale-factor', $gv);
      }
    );
  }

  # cw: Until a more definite signature is obtained.
  method changed ($detail = '') {
    self.connect($!sttc, $detail ?? 'changed' !! "changed::{ $detail }" );
  }

  method get_font ( :$raw = False ) is also<get-font> {
    propReturnObject(
      st_theme_context_get_font($!sttc),
      $raw,
      |Pango::Font::Description.getTypePair
    );
  }

  method get_root_node ( :$raw = False ) is also<get-root-node> {
    propReturnObject(
      st_theme_context_get_root_node($!sttc),
      $raw,
      |Gnome::Shell::Theme::Node.getTypePair
    );
  }

  method get_scale_factor is also<get-scale-factor> {
    st_theme_context_get_scale_factor($!sttc);
  }

  method get_theme ( :$raw = False) is also<get-theme> {
    propReturnObject(
      st_theme_context_get_theme($!sttc),
      $raw,
      |Gnome::Shell::Theme.getTypePair
    );
  }

  method intern_node (StThemeNode() $node) is also<intern-node> {
    st_theme_context_intern_node($!sttc, $node);
  }

  method set_font (PangoFontDescription() $font) is also<set-font> {
    st_theme_context_set_font($!sttc, $font);
  }

  method set_theme (StTheme() $theme) is also<set-theme> {
    st_theme_context_set_theme($!sttc, $theme);
  }

}
