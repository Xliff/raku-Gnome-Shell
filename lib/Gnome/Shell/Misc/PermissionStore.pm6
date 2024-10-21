use v6.c;

use GIO::Raw::Types;
use GIO::DBus;
use GIO::DBus::Proxy;

use Gnome::Shell::Misc::FileUtils;

constant PermissionStoreIface = loadInterfaceXML('org.freedesktop.impl.portal.permissionstore');

my $PermissionStoreProxy;

INIT {
  #$PermissionStoreProxy = GIO::DBus::Proxy.makeWrapper(PermissionStoreIface);
}

sub PermissionStore ($init = Callable, $cancel = GCancellable) is export {
  $PermissionStoreProxy.new(
    GIO::DBus.session,
    '/org/freedesktop/impl/portal/PermissionStore',
    $init,
    $cancel
  );
}
