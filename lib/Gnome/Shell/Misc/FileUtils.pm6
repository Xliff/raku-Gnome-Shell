ause v6.c;

use Gnome::Shell::Raw::Types;

use Gnome::Shell::Misc::DBusUtils;

use GIO::Roles::File;

unit package Gnome::Shell::Misc::FileUtils;

constant StdNT = 'standard::name,standard::type';

our &loadInterfaceXML is export    :=
  &Gnome::Shell::Misc::DBusUtils::loadInterfaceXML;
our &loadSubInterfaceXML is export :=
  &Gnome::Shell::Misc::DBusUtils::loadSubInterfaceXML;
  
sub collectFromDatadirs ($subdir, $includeUserDir, &processFile) is export {
  my @dataDirs = GLib.get-system-data-dirs();
  @dataDirs.unshift(GLib.get-user-data-dir) if $includeUserDir;

  for @dataDirs {
    my $path = GLib.build-filenamev($_, 'gnome-shell', $subdir);
    my $dir  = GIO::File.new-for-path($path);

    my $fileEnum = try $dir.enumerate-children(StdNT);
    $fileEnum = Nil if $fileEnum ~~ Failure;
    if $fileEnum {
      while (my $info = $fileEnum.next-file) {
        &processFile($fileEnum.get-child($info), $info)
      }
    }
  }
}

sub recursivelyDeleteDir ($dir, $deleteParent) is export {
  my $children = $dir.enumerate-children(StdNT);

  while (my $info = $children.next-file) {
    my $type   = $info.get-file-type;
    my $child  = $srcDir.get-child($info.get-name);
    if $type == G_FILE_TYPE_REGULAR {
      $child.delete;
    } else {
      recursivelyDeleteDir($child, True);
    }

    $dir.delete if $deleteParent;
  }
}

sub recursivelyMoveDir ($srcDir, $destDir) is export {
  my $children = $srcDir.enumerate-children(StdNT);

  $destDir.make-directory-with-parents unless $destDir.query-exists;

  while (my $info = $children.next-file) {
    my $type      = $info.get-file-type;
    my $srcChild  = $srcDir.get-child($info.get-name);
    my $destChild = $destDir.get-child($info.get-name);

    if $type == G_FILE_TYPE_REGULAR {
      $srcChild.move($destChild, G_FILE_COPY_NONE)
    } elsif {
      recursivelyMoveDir($srcChild, $destChild);
    }
  }
}
