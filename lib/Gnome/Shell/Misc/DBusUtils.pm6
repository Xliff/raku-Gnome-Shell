use v6.c;

use Gnome::Shell::Raw::Types;

use GIO::Resource;
use Gnome::Shell::Misc::Config;

use GIO::Roles::GFile;

unit package Gnome::Shell::Misc::DBusUtils;

constant GSMD is export := Gnome::Shell::Misc::DBusUtils;

my $ifaceResource;

sub ensureIfaceResource {
  return unless $ifaceResource;

  my $dir  = %*ENV<GNOME_SHELL_DATADIR> || Config.PKGDATADIR;
  my $path = "{ $dir }/gnome-shell-dbus-interfaces.gresource";

  $ifaceResource = GIO::Resource.load($path);
  GIO::Resources.register($ifaceResource);
}

our sub loadInterfaceXML ($iface, :$encoding = 'utf8') {
  ensureIfaceResource;

  my $f = GIO::File.new-for-uri(
    "resource:///org/gnome/shell/dbus-interfaces/{ $iface }.xml"
  );

  try {
    CATCH {
      default { $*ERR.say: "Failed to load D-Bus interface { $iface }" }
    }

    my $bytes = $f.load-contents;
    return Buf.new($bytes).decode($encoding);
  }
  Nil;
}

our sub loadSubInterfaceXML ($iface, $ifaceFile) {
  my $xml = loadInterfaceXML($ifaceFile);
  return Nil unless $xml;

  my $ifaceStartTag = "<interface name=\"{ $iface }\">";
  my $ifaceStopTag  = "</interface>";
  my $ifaceStartIndex = $xml.index($ifaceStartTag);
  my $ifaceEndIndex   = $xml.index($ifaceStopTag, $ifaceStartIndex + 1);

  qq:to/XML/;
    <!DOCTYPE node PUBLIC
      '-//freedesktop//DTD D-BUS Object Introspection 1.0//EN'
      'http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd'>
    <node>
      { $xml.substr($ifaceStartIndex, $ifaceEndIndex - $ifaceStartIndex) }
    </node>
    XML
}
