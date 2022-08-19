use v6.c;

use Method::Also;

use NativeCall;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;

use GLib::Roles::Implementor;
use GLib::Roles::Object;
use Mutter::Clutter::Roles::Content;

our subset StImageContentAncestry is export of Mu
  where StImageContent | GObject;

class Gnome::Shell::St::ImageContent {
  also does GLib::Roles::Object;
  also does Mutter::Clutter::Roles::Content;
  
  has StImageContent $!stic is implementor;

  submethod BUILD ( :$st-image-content ) {
    self.setStImageContent($st-image-content)
      if $st-image-content
  }

  method setStImageContent (StImageContentAncestry $_) {
    my $to-parent;

    $!stic = do {
      when StImageContent {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StImageContent, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Mutter::Cogl::Raw::Definitions::StImageContent
    is also<StImageContent>
  { $!stic }

  method new (StImageContentAncestry $st-image-content, :$ref = True) {
    return unless $st-image-content;

    my $o = self.bless( :$st-image-content );
    $o.ref if $ref;
    $o;
  }

  method new_with_prefered_size (Int() $width, Int() $height)
    is also<new-with-preferred-size>
  {
    my gint ($w, $h) = ($width, $height);

    my $st-image-content = st_image_content_new_with_preferred_size($w, $h);

    $st-image-content ?? self.bless( :$st-image-content ) !! Nil;
  }

  # Type: int
  method preferred-width is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_INT );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('preferred-width', $gv);
        $gv.int;
      },
      STORE => -> $, Int() $val is copy {
        $gv.int = $val;
        self.prop_set('preferred-width', $gv);
      }
    );
  }

  # Type: int
  method preferred-height is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_INT );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('preferred-height', $gv);
        $gv.int;
      },
      STORE => -> $, Int() $val is copy {
        $gv.int = $val;
        self.prop_set('preferred-height', $gv);
      }
    );
  }

}

### /home/cbwood/Projects/gnome-shell/src/st/st-image-content.h

sub st_image_content_new_with_preferred_size (gint $width, gint $height)
  returns MutterClutterContent
  is native(gnome-shell-st)
  is export
{ * }
