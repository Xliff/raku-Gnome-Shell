use v6.c;

use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::Compat;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

our subset PolkitListenerAncestry is export of Mu
  where PolkitListener | GObject;

class Polkit::Listener {
  also does GLib::Roles::Object;

  has PolkitListener $!pl is implementor;

  method setPolkitListener ($o) {
    self!setObject(
      $o ~~ GObject ?? $o !! cast(GObject, $o)
    );
  }

}
