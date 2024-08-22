use v6.c;

use Method::Also;
use NativeCall;

use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::St::IconCache;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

our subset StIconCacheAncestry is export of Mu
  where StIconCache | GObject;

class Gnome::Shell::St::IconCache {
  also does GLib::Roles::Object;

  has StIconCache $!stic is implementor;

  submethod BUILD ( :$st-icon-cache ) {
    self.setStIconCache($st-icon-cache) if $st-icon-cache
  }

  method setStIconCache (StIconCacheAncestry $_) {
    my $to-parent;

    $!stic = do {
      when StIconCache {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StIconCache, $_);
      }
    }
    self.setObject($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::StIconCache
    is also<StIconCache>
  { $!stic }

  multi method new ($st-icon-cache where * ~~ StIconCacheAncestry , :$ref = True) {
    return unless $st-icon-cache;

    my $o = self.bless( :$st-icon-cache );
    $o.ref if $ref;
    $o;
  }
  multi method new (@data) {
    samewith( newCArray(uint8, @data) );
  }
  multi method new (CArray[uint8] $data) {
    my $st-icon-path = st_icon_cache_new($data);

    $st-icon-path ?? self.bless( :$st-icon-path ) !! Nil
  }

  method new_for_path (Str() $path) is also<new-for-path> {
    my $st-icon-path = st_icon_cache_new_for_path($!stic, $path);

    $st-icon-path ?? self.bless( :$st-icon-path ) !! Nil
  }

  proto method add_icons (|)
    is also<add-icons>
  { * }

  multi method add_icons (Str() $directory, %hashtable) {
    samewith($directory, GLib::HashTable.new(%hashtable) );
  }
  multi method add_icons (
    Str()         $directory,
    GHashTable()  $hash_table
  ) {
    st_icon_cache_add_icons($!stic, $directory, $hash_table);
  }

  method get_directory_index (Str() $directory) is also<get-directory-index> {
    st_icon_cache_get_directory_index($!stic, $directory);
  }

  method get_icon (
    Str() $icon_name,
    Int() $directory_index
  )
    is also<get-icon>
  {
    my gint $d = $directory_index;

    st_icon_cache_get_icon($!stic, $icon_name, $d);
  }

  method get_icon_flags (
    Str() $icon_name,
    Int() $directory_index
  )
    is also<get-icon-flags>
  {
    my gint $d = $directory_index;

    st_icon_cache_get_icon_flags($!stic, $icon_name, $directory_index);
  }

  method has_icon (Str() $icon_name) is also<has-icon> {
    st_icon_cache_has_icon($!stic, $icon_name);
  }

  method has_icon_in_directory (
    Str() $icon_name,
    Str() $directory
  )
    is also<has-icon-in-directory>
  {
    st_icon_cache_has_icon_in_directory($!stic, $icon_name, $directory);
  }

  method has_icons (Str() $directory) is also<has-icons> {
    so st_icon_cache_has_icons($!stic, $directory);
  }

  method ref {
    st_icon_cache_ref($!stic);
    self;
  }

  method unref {
    st_icon_cache_unref($!stic);
  }

}
