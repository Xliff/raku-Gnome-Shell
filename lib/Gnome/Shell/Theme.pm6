use v6.c;

use Method::Also;
use NativeCall;

use Gnome::Shell::Raw::Types;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

our subset StThemeAncestry is export of Mu
  where StTheme | GObject;

class Gnome::Shell::Theme {
  also does GLib::Roles::Object;

  has StTheme $!stt is implementor;

  submethod BUILD ( :$st-theme ) {
    self.setStTheme($st-theme) if $st-theme
  }

  method setStTheme (StThemeAncestry $_) {
    my $to-parent;

    $!stt = do {
      when StTheme {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StTheme, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Mutter::Clutter::Raw::Definitions::StTheme
    is also<StTheme>
  { $!stt }

  multi method new (StThemeAncestry $st-theme, :$ref = True) {
    return unless $st-theme;

    my $o = self.bless( :$st-theme );
    $o.ref if $ref;
    $o;
  }

  method new (
    GFile() $application_stylesheet,
    GFile() $theme_stylesheet,
    GFile() $default_stylesheet
  )
    my $st-theme = st_theme_new(
      $application_stylesheet,
      $theme_stylesheet,
      $default_stylesheet
    );

    $st-theme ?? self.bless( :$st-theme ) !! Nil;
  }

  method get_custom_stylesheets ( :$raw = False, :$glist = False ) {
    returnGList(
      st_theme_get_custom_stylesheets($!stt),
      $raw,
      $glist,
      |GIO::File.getTypePair
    );
  }

  method load_stylesheet (
    GFile()                 $file,
    CArray[Pointer[GError]] $error = GError
  )
    is also<load-stylesheet>
  {
    clear_error;
    my $rv = so st_theme_load_stylesheet($!stt, $file, $error);
    set_error($error);
    $rv;
  }

  method unload_stylesheet (GFile() $file) is also<unload-stylesheet> {
    st_theme_unload_stylesheet($!stt, $file);
  }

}


### /home/cbwood/Projects/gnome-shell/src/st/st-theme.h

sub st_theme_get_custom_stylesheets (StTheme $theme)
  returns GSList
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_load_stylesheet (
  StTheme                 $theme,
  GFile                   $file,
  CArray[Pointer[GError]] $error
)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_new (
  GFile $application_stylesheet,
  GFile $theme_stylesheet,
  GFile $default_stylesheet
)
  returns StTheme
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_unload_stylesheet (StTheme $theme, GFile $file)
  is native(gnome-shell-st)
  is export
{ * }
