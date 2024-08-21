use v6.c;

use Method::Also;
use NativeCall;

use GLib::Raw::Traits;
use GDK::Pixbuf::Raw::Definitions;
use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::St::IconTheme;

use GLib::GList;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

our subset StIconThemeAncestry is export of Mu
  where StIconTheme | GObject;

class Gnome::Shell::St::IconTheme {
  also does GLib::Roles::Object;

  has StIconTheme $!stit is implementor;

  submethod BUILD ( :$st-icon-info ) {
    self.setStIconTheme($st-icon-info) if $st-icon-info
  }

  method setStIconTheme (StIconThemeAncestry $_) {
    my $to-parent;

    $!stit = do {
      when StIconTheme {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StIconTheme, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::StIconTheme
    is also<StIconTheme>
  { $!stit }

  multi method new (
    $st-icon-info where * ~~ StIconThemeAncestry,

    :$ref = True
  ) {
    return unless $st-icon-info;

    my $o = self.bless( :$st-icon-info );
    $o.ref if $ref;
    $o;
  }
  multi method new {
    my $st-icon-theme = st_icon_theme_new();

    $st-icon-theme ?? self.bless( :$st-icon-theme ) !! Nil;
  }

  method add_resource_path (Str() $path) is also<add-resource-path> {
    st_icon_theme_add_resource_path($!stit, $path);
  }

  method append_search_path (Str() $path) is also<append-search-path> {
    st_icon_theme_append_search_path($!stit, $path);
  }

  method choose_icon (
    Str() $icon_names,
    Int() $size,
    Int() $flags       = 0
  )
    is also<choose-icon>
  {
    my gint              $s = $size;
    my StIconLookupFlags $f = $flags;

    st_icon_theme_choose_icon($!stit, $icon_names, $size, $flags);
  }

  method choose_icon_for_scale (
    Str() $icon_names,
    Int() $size,
    Int() $scale,
    Int() $flags       = 0
  )
    is also<choose-icon-for-scale>
  {
    my gint              ($si, $sc) = ($size, $scale);
    my StIconLookupFlags  $f        =  $flags;

    st_icon_theme_choose_icon_for_scale($!stit, $icon_names, $size, $scale, $flags);
  }

  method error_quark is static is also<error-quark> {
    st_icon_theme_error_quark;
  }

  method get_icon_sizes (Str() $icon_name)
    is also<get-icon-sizes>
  {
    st_icon_theme_get_icon_sizes($!stit, $icon_name);
  }

  proto method get_search_path (|)
    is also<
      get-search-path
      search_path
      seatch-path
    >
  { * }

  multi method get_search_path {
    samewith( newCArray(Str) );
  }
  multi method get_search_path (
    CArray[Str]  $path,
                 $n_elements is rw,
                :$raw               = False
  ) {
    my gint $n = 0;

    st_icon_theme_get_search_path($!stit, $path, $n);
    $n_elements = $n;
    return $path if $raw;
    CArrayToArray($path);
  }

  method has_icon (Str() $icon_name) is also<has-icon> {
    so st_icon_theme_has_icon($!stit, $icon_name);
  }

  method list_contexts ( :$raw = False, :gslist(:$glist) = False ) is also<list-contexts> {
    returnGList(
      st_icon_theme_list_contexts($!stit),
      $raw,
      $glist,
      Str
    );
  }

  method list_icons (
    Str()  $context,
          :$raw            = False,
          :gslist(:$glist) = False
  )
    is also<list-icons>
  {
    returnGList(
      st_icon_theme_list_icons($!stit, $context);
      $raw,
      $glist,
      Str
    );
  }

  method load_icon (
    Str()                    $icon_name,
    Int()                    $size,
    Int()                    $flags      = 0,
    CArray[Pointer[GError]]  $error      = gerror,
                            :$raw        = False
  )
    is also<load-icon>
  {
    my gint              $s = $size;
    my StIconLookupFlags $f = $flags;

    clear_error;
    my $r = st_icon_theme_load_icon(
      $!stit,
      $icon_name,
      $s,
      $f,
      $error
    );
    set_error($error);
    propReturnObject($r, $raw, GDK::Pixbuf.geTypePair)
  }

  method load_icon_for_scale (
    Str()                    $icon_name,
    Int()                    $size,
    Int()                    $scale,
    Int()                    $flags      = 0,
    CArray[Pointer[GError]]  $error      = gerror,
                            :$raw        = False
  )
    is also<load-icon-for-scale>
  {
    my gint              ($si, $sc) = ($size, $scale);
    my StIconLookupFlags  $f        =  $flags;

    clear_error;
    my $i = st_icon_theme_load_icon_for_scale(
      $!stit,
      $icon_name,
      $si,
      $sc,
      $f,
      $error
    );
    set_error($error);
    propReturnObject($i, $raw, GDK::Pixbuf.geTypeaPair)
  }

  method lookup_by_gicon (
    GIcon()  $icon,
    Int()    $size,
    Int()    $flags  = 0,
            :$raw    = False
  )
    is also<lookup-by-gicon>
  {
    my gint              $s = $size;
    my StIconLookupFlags $f = $flags;

    propReturnObject(
      st_icon_theme_lookup_by_gicon($!stit, $icon, $s, $f),
      $raw,
      |GDK::Pixbuf.getTypePair
    );
  }

  method lookup_by_gicon_for_scale (
    GIcon() $icon,
    Int()   $size,
    Int()   $scale,
    Int()   $flags   = 0,
           :$raw     = False
  )
    is also<lookup-by-gicon-for-scale>
  {
    my gint              ($si, $sc) = ($size, $scale);
    my StIconLookupFlags  $f        =  $flags;

    propReturnObject(
      st_icon_theme_lookup_by_gicon_for_scale(
        $!stit,
        $icon,
        $si,
        $sc,
        $f
      ),
      $raw,
      |Gnome::Shell::St::Info.getTypePair
    );
  }

  method lookup_icon (
    Str()  $icon_name,
    Int()  $size,
    Int()  $flags,
          :$raw        = False
  )
    is also<lookup-icon>
  {
    my gint              $s = $size;
    my StIconLookupFlags $f = $flags;

    propReturnObject(
      st_icon_theme_lookup_icon(
        $!stit,
        $icon_name,
        $s,
        $f
      ),
      $raw,
      |Gnome::Shell::St::Icon.getTypePair
    );
  }

  method lookup_icon_for_scale (
    Str()  $icon_name,
    Int()  $size,
    Int()  $scale,
    Int()  $flags      = 0,
          :$raw        = False
  )
    is also<lookup-icon-for-scale>
  {
    my gint              ($si, $sc) = ($size, $scale);
    my StIconLookupFlags  $f        =  $flags;

    propReturnObject(
      st_icon_theme_lookup_icon_for_scale(
        $!stit,
        $icon_name,
        $si,
        $sc,
        $f
      ),
      $raw,
      |Gnome::Shell::St::Icon.getTypePair
    );
  }

  method prepend_search_path (Str() $path) is also<prepend-search-path> {
    st_icon_theme_prepend_search_path($!stit, $path);
  }

  method rescan_if_needed is also<rescan-if-needed> {
    st_icon_theme_rescan_if_needed($!stit);
  }

  proto method set_search_path (|)
    is also<set-search-path>
  { * }

  multi method set_search_path (@elements) {
    samewith( newCArray(Str, @elements), @elements.elems );
  }
  multi method set_search_path (
    CArray[Str] $path,
    Int()       $n_elements
  ) {
    my gint $n;

    st_icon_theme_set_search_path($!stit, $path, $n);
  }

}



our subset StIconInfoAncestry is export of Mu
  where StIconInfo | GObject;

class Gnome::Shell::St::Icon::Info {
  has StIconInfo $!stii is implementor;

  submethod BUILD ( :$st-icon-info ) {
    self.setStIconInfo($st-icon-info) if $st-icon-info
  }

  method setStIconInfo (StIconInfoAncestry $_) {
    my $to-parent;

    $!stii = do {
      when StIconInfo {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StIconInfo, $_);
      }
    }
    self.setObject($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::StIconInfo
    is also<StIconInfo>
  { $!stii }

  method new (
    $st-icon-info where * ~~ StIconInfoAncestry,

    :$ref = True
  ) {
    return unless $st-icon-info;

    my $o = self.bless( :$st-icon-info );
    $o.ref if $ref;
    $o;
  }

  method new_for_pixbuf (
    StIconTheme() $icon_theme,
    GdkPixbuf()   $pixbuf
  )
    is also<new-for-pixbuf>
  {
    my $st-icon-info = st_icon_info_new_for_pixbuf($!stii, $pixbuf);

    $st-icon-info ?? self.bless( :$st-icon-info ) !! Nil;
  }

  method get_base_scale is also<
    get-base-scale
    base_scale
    base-scale
  > {
    st_icon_info_get_base_scale($!stii);
  }

  method get_base_size
    is also<
      get-base-size
      base_size
      base-size
    >
  {
    st_icon_info_get_base_size($!stii);
  }

  method get_filename
    is also<
      get-filename
      filename
    >
  {
    st_icon_info_get_filename($!stii);
  }

  method is_symbolic is also<is-symbolic> {
    so st_icon_info_is_symbolic($!stii);
  }

  method load_icon (CArray[Pointer[GError]] $error = gerror, :$raw = False) is also<load-icon> {
    propReturnObject(
      st_icon_info_load_icon($!stii, $error),
      $raw,
      |GDK::Pixbuf.getTypePair
    );
  }

  method load_icon_async (
    GCancellable() $cancellable,
                   &callback,
    gpointer       $user_data     = gpointer
  )
    is also<load-icon-async>
  {
    st_icon_info_load_icon_async($!stii, $cancellable, &callback, $user_data);
  }

  method load_icon_finish (
    GAsyncResult()           $res,
    CArray[Pointer[GError]]  $error = gerror,
                            :$raw  = False
  )
    is also<load-icon-finish>
  {
    propReturnObject(
      st_icon_info_load_icon_finish($!stii, $res, $error),
      $raw,
      |GDK::Pixbuf.getTypePair
    );
  }

  method load_symbolic (
    StIconColors()           $colors,
    Int()                    $was_symbolic,
    CArray[Pointer[GError]]  $error         = gerror,
                            :$raw           = False
  )
    is also<load-symbolic>
  {
    clear_error;
    my $p = st_icon_info_load_symbolic($!stii, $colors, $was_symbolic, $error);
    set_error($error);
    propReturnObject($p, $raw, |GDK::Pixbuf.getTypePair);
  }

  method load_symbolic_async (
    StIconColors()  $colors,
    GCancellable()  $cancellable,
                    &callback,
    gpointer        $user_data    = gpointer
  )
    is also<load-symbolic-async>
  {
    st_icon_info_load_symbolic_async(
      $!stii,
      $colors,
      $cancellable,
      &callback,
      $user_data
    )
  }

  method load_symbolic_finish (
    GAsyncResult()           $res,
    Int()                    $was_symbolic,
    CArray[Pointer[GError]]  $error         = gerror,
                            :$raw           = False
  )
    is also<load-symbolic-finish>
  {
    my gboolean $w = $was_symbolic.so.Int;

    propReturnObject(
      st_icon_info_load_symbolic_finish($!stii, $res, $w, $error),
      $raw,
      |GDK::Pixbuf.getTypePair
    );
  }

}
