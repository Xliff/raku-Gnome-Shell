use v6.c;

use Method::Also;

use NativeCall;

use Cairo;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::St::TextureCache;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

my $singleton;

our subset StTextureCacheAncestry is export of Mu
  where StTextureCache | GObject;

class Gnome::Shell::St::TextureCache is GLib::Roles::Object {
  also does GLib::Roles::Object;
  
  has StTextureCache $!sttc is implementor;

  submethod BUILD ( :$st-texture-cache ) {
    self.setStTextureCache($st-texture-cache) if $st-texture-cache;
  }

  method setStTextureCache (StTextureCacheAncestry $_) {
    my $to-parent;

    $!sttc = do {
      when StTextureCache {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StTextureCache, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Mutter::Cogl::Raw::Definitions::StTextureCache
    is also<StTextureCache>
  { $!sttc }

  multi method new (StTextureCacheAncestry $st-texture-cache, :$ref = True) {
    return unless $st-texture-cache;

    unless $singleton {
      my $o = self.bless( :$st-texture-cache );
    }

    $singleton;
  }
  multi method new is static {
    self.get_default;
  }

  method get_default is also<get-default> is static {
    unless $singleton {
      my $st-texture-cache = st_texture_cache_get_default();

      $singleton = $st-texture-cache ?? self.bless( :$st-texture-cache ) !! Nil;
    }
    $singleton;
  }

  method bind_cairo_surface_property (
    GObject()  $object,
    Str()      $property_name,
              :$raw            = False
  )
    is also<bind-cairo-surface-property>
  {
    propReturnObject(
      st_texture_cache_bind_cairo_surface_property(
        $!sttc,
        $object,
        $property_name
      ),
      $raw,
      |GIO::Icon.getTypePair
    );
  }

  method load (
    Str()                    $key,
    StTextureCachePolicy     $policy,
                             &load,
    gpointer                 $data    = gpointer,
    CArray[Pointer[GError]]  $error   = gerror,
                            :$raw     = False
  ) {
    clear_error;
    my $t = st_texture_cache_load(
      $!sttc,
      $key,
      $policy,
      &load,
      $data,
      $error
    );
    set_error($error);
    propReturnObject($t, $raw, |Mutter::COGL::Texture.getTypePair);
  }

  method load_cairo_surface_to_gicon (
    cairo_surface_t()  $surface,
                      :$raw       = False
   )
    is also<load-cairo-surface-to-gicon>
  {
    propReturnObject(
      st_texture_cache_load_cairo_surface_to_gicon($!sttc, $surface),
      $raw,
      |GIO::Icon.getTypePair
    );
  }

  method load_file_async (
    GFile()  $file,
    Int()    $available_width,
    Int()    $available_height,
    Int()    $paint_scale,
    Num()    $resource_scale,
            :$raw               = False
  )
    is also<load-file-async>
  {
    my gint ($w, $h, $s) = ($available_width, $available_height, $paint_scale);

    my gfloat $r = $resource_scale;

    propReturnObject(
      st_texture_cache_load_file_async($!sttc, $file, $w, $h, $s, $r),
      $raw,
      |Mutter::Clutter::Actor.getTypePair
    )
  }

  method load_file_to_cairo_surface (
    GFile()  $file,
    Int()    $paint_scale,
    Num()    $resource_scale,
            :$raw             = False
  )
    is also<load-file-to-cairo-surface>
  {
    my gint   $ps = $paint_scale;
    my gfloat $rs = $resource_scale;

    propReturnObject(
      st_texture_cache_load_file_to_cairo_surface($!sttc, $file, $ps, $rs),
      $raw,
      cairo_surface_t,
      Cairo::Surface
    );
  }

  method load_file_to_cogl_texture (
    GFile()  $file,
    Int()    $paint_scale,
    Num()    $resource_scale,
            :$raw             = False
  )
    is also<load-file-to-cogl-texture>
  {
    my gint   $ps = $paint_scale;
    my gfloat $rs = $resource_scale;

    propReturnObject(
      st_texture_cache_load_file_to_cogl_texture($!sttc, $file, $ps, $rs),
      $raw,
      |Mutter::COGL::Texture.getTypePair
    );
  }

  method load_gicon (
    StThemeNode()  $theme_node,
    GIcon()        $icon,
    Int()          $size,
    Int()          $paint_scale,
    Num()          $resource_scale,
                  :$raw             = False
  )
    is also<load-gicon>
  {
    my gint   ($s, $ps) = ($size, $paint_scale);
    my gfloat  $rs      = $resource_scale;

    propReturnObject(
      st_texture_cache_load_gicon($!sttc, $theme_node, $icon, $s, $rs, $ps),
      $raw,
      |Mutter::Clutter::Actor.getTypePair
    );
  }

  method load_sliced_image (
    GFile()   $file,
    Int()     $grid_width,
    Int()     $grid_height,
    Int()     $paint_scale,
    Num()     $resource_scale,
              &load_callback,
    gpointer  $user_data       = gpointer,
             :$raw             = False
  )
    is also<load-sliced-image>
  {
    my gint   ($w, $h, $s, $ps) = ($grid_width, $grid_height, $paint_scale);
    my gfloat  $rs              = $resource_scale;

    propReturnObject(
      st_texture_cache_load_sliced_image($!sttc, $file, $w, $h, $s, $ps, $rs),
      $raw,
      |Mutter::Clutter::Actor.getTypePair
    );
  }

  method rescan_icon_theme is also<rescan-icon-theme> {
    so st_texture_cache_rescan_icon_theme($!sttc);
  }

}
