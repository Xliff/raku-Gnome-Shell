use v6.c;

use Method::Also;

use NativeCall;

use Gnome::Shell::Raw::Types;

use GLib::GSList;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

our subset ShellAppUsageAncestry is export of Mu
  where ShellAppUsage | GObject;

class Gnome::Shell::AppUsage {
  also does GLib::Roles::Object;

  has ShellAppUsage $!sau is implementor;

  submethod BUILD ( :$shell-app-usage ) {
    self.setShellAppUsage($shell-app-usage) if $shell-app-usage
  }

  method setShellAppUsage (ShellAppUsageAncestry $_) {
    my $to-parent;

    $!sau = do {
      when ShellAppUsage {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellAppUsage, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::ShellAppUsage
    is also<ShellAppUsage>
  { $!sau }

  multi method new (ShellAppUsageAncestry $shell-app-usage, :$ref = True) {
    return unless $shell-app-usage;

    my $o = self.bless( :$shell-app-usage );
    $o.ref if $ref;
    $o;
  }

  method get_default is also<get-default> {
    my $shell-app-usage = shell_app_usage_get_default($!sau);

    $shell-app-usage ?? self.bless( :$shell-app-usage ) !! Nil;
  }

  method compare (Str() $id_a, Str() $id_b) {
    so shell_app_usage_compare($!sau, $id_a, $id_b);
  }

  method get_most_used ( :$raw = False, :$glist = False )
    is also<get-most-used>
  {
    returnGSList(
      shell_app_usage_get_most_used($!sau),
      $raw,
      $gslist,
      |Gnome::Shell::App.getTypePair
    );
  }

}

### /home/cbwood/Projects/gnome-shell/src/shell-app-usage.h

sub shell_app_usage_compare (ShellAppUsage $self, Str $id_a, Str $id_b)
  returns gint
  is      native(gnome-shell)
  is      export
{ * }

sub shell_app_usage_get_default ()
  returns ShellAppUsage
  is      native(gnome-shell)
  is      export
{ * }

sub shell_app_usage_get_most_used (ShellAppUsage $usage)
  returns GSList
  is      native(gnome-shell)
  is      export
{ * }
