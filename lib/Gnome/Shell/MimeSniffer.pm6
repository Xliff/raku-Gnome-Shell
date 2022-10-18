use v6.c;

use Method::Also;

use NativeCall;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

class Gnome::Shell::MimeSniffer {
  also does GLib::Roles::Object;

  has ShellMimeSniffer $!sms is implementor;

  multi method new (GFile() $file) {
    my $shell-mime-sniffer = shell_mime_sniffer_new($file);

    $shell-mime-sniffer ?? self.bless( :$shell-mime-sniffer ) !! Nil;
  }

  # Type: GFile
  method file ( :$raw = False ) is rw  is g-property {
    my $gv = GLib::Value.new( GIO::File.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('file', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |GIO::File.getTypePair
        );
      },
      STORE => -> $, GFile() $val is copy {
        $gv.object = $val;
        self.prop_set('file', $gv);
      }
    );
  }


  method sniff_async (&callback, gpointer $user_data = gpointer)
    is also<sniff-async>
  {
    shell_mime_sniffer_sniff_async($!sms, &callback, $user_data);
  }

  method sniff_finish (
    GAsyncResult()          $res,
    CArray[Pointer[GError]] $error = gerror
  )
    is also<sniff-finish>
  {
    clear_error;
    my $sa = shell_mime_sniffer_sniff_finish($!sms, $res, $error);
    set_error($error);

    CArrayToArray($sa);
  }

}
### /home/cbwood/Projects/gnome-shell/src/hotplug-sniffer/shell-mime-sniffer.h

sub shell_mime_sniffer_new (GFile $file)
  returns ShellMimeSniffer
  is native(gnome-shell)
  is export
{ * }

sub shell_mime_sniffer_sniff_async (
  ShellMimeSniffer $self,
                   &callback (ShellMimeSniffer, GAsyncResult, gpointer),
  gpointer         $user_data
)
  is native(gnome-shell)
  is export
{ * }

sub shell_mime_sniffer_sniff_finish (
  ShellMimeSniffer        $self,
  GAsyncResult            $res,
  CArray[Pointer[GError]] $error
)
  returns CArray[Str]
  is native(gnome-shell)
  is export
{ * }
