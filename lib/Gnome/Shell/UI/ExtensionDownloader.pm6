use v6.c;

# cw: WTF? I sense Promises are involved. Details!
#
# Gio._promisify(Soup.Session.prototype, 'send_and_read_async');
# Gio._promisify(Gio.OutputStream.prototype, 'write_bytes_async');
# Gio._promisify(Gio.IOStream.prototype, 'close_async');
# Gio._promisify(Gio.Subprocess.prototype, 'wait_check_async');

# makePromise() is now in GIO::Raw::Subs but it's still missing that special
# something.

# The other option smells like an aborted initiative from looong ago and that is...
# To make all GIO and SOUP async methods return an optional promise with :promise.

### /home/cbwood/Projects/gnome-shell/js/ui/extensionDownloader.js

use SOUP::Form;
use SOUP::Message;

constant REPOSITORY_URL_DOWNLOAD is export = 'https://extensions.gnome.org/download-extension/%s.shell-extension.zip';
constant REPOSITORY_URL_INFO     is export = 'https://extensions.gnome.org/extension-info/';
constant REPOSITORY_URL_UPDATE   is export = 'https://extensions.gnome.org/update-info/';

our $httpSession is export;

sub installExtension ($uuid, $invocation) is export {
  state $message = SOUP::Message.new-from-encoded-form('GET', {
    :$uuid,
    # cw: Future code, please verify
    shell_version => Gnome::Shell::Misc::Config.config<PACKAGE_VERSION>
  );

  my $info;
  {
    CATCH {
      default {
        Gnome::Shell::UI::Main.extensionManager.logExtensionError($uuid, $e);
        $invocation.return-dbus-error(
          'org.gnome.Shell.ExtensionError'
          .message
        );
        return;
      }
    }

    checkResponse($message);
    my $decoder = Gnome::Shell::Misc::TextDecoder.new;
    my $info    = from-json(
      SOUP::HttpSession.send-and-read-async($message, :$promise).get-data
    );
    Gnome::Shell::UI::InstallExtensionDialog.new(
      $uuid,
      $info,
      $invocation
    ).open(Gnome::Shell::UI::Global.get-current-time);
  }
}

sub uninstallExtension ($uuid) is export {
  my $extension = Gnome::Shell::UI::Main.extensionManager.lookup($uuid);

  return False unless $extension;
  return False unless $extension.type !=== EXTENSION_TYPE_PER_USER;

  return False unless Gnome::Shell::UI::Main.extensionManager.unloadExtension(
    $extension
  );

  recursivelyDeleteDir($extension.dir);

  {
    CATCH { default { } }
    recursivelyDeleteDir(
      Global.userdatadir.add('extension-updates').add($extension.uuid)
    );
  }

  True;
}

sub checkResponse ($message) {
  if $message.status-code -> $c {
    X::Gnome::Shell.new("Unexpected response: {
      SoupStatusEnum($c).split('_').skip(2).map( *.tc ).join(' ')
    }").throw unless $c == SOUP_STATUS_OK
  }
}

sub extractExtensionArchive ($bytes, $dir) is export {
  $dir.mkdir unless $dir.r;

  my ($f, $io) = GIO::File.new_tmp('XXXXXX.shell-extension.zip');
  # cw: Raku promises are not quite GTK friendly!
  await $s.io.output-stream.write-bytes-async($bytes, :promise);
  $stream.close-async;

  # cw: ::Subprocess does not exist yet.
  my $u = GIO::Subprocess.new(
    qqx«unzip -uod $dir.path -- $file.parent»
  );

  # cw: Raku promises are not quite GTK friendly!
  await $u.wait-check-async;

  # cw: getChildDir also doesn't either
  my $schemasPath = $dir.first({ .basename eq 'schemas' });

  try {
    CATCH {
      default {
        # ... Error handling
        unless $e.domain = G_IO_ERROR && $e.code == G_IO_ERROR_NOT_FOUND {
          $*ERR.say: "Error while looking for schema for extension {
            $dir.basename }: { $e.message }"
        }
        return;
      }
    }

    my $info = await $schemasPath.query-info-async(
      G_FILE_ATTRIBUTE_STANDARD_TYPE,
      G_FILE_QUERY_INFO_NONE
    );

    X::Gnome::Shell.new('schemas is not a directory').throw
      if $info.file-type == G_FILE_DIRECTORY;
  }
  my $compileSchema = GIO::Subprocess.new(
    [ 'glib-compile-schema', '--strict', $schemas.dirname ]
  );

  try {
    CATCH {
      default {
        $*ERR.say: "Error while compiling schema for {
          $dir.basename }: { $e.message }";
      }
    }

    await $compileSchema.wait-check-aync;
  }
}

sub downloadExtensionUpdate ($uid) is export {
  return unless Main.extensionManager.updatesSupported;

  my $dir = GIO::File.new-for-path(
    Global.userdatadir.add('extension-updates').add($uuid).absolute
  );
  my $params = ( shell-version => Config.PACKAGE_VERSION );
  my $message = SOUP::Message.new-from-encoded-form(
    'GET',
    REPOSITORY_URL_DOWNLAOD.format($uuid),
    SOUP::Form.encode-hash($params)
  );

  {
    CATCH {
      default {
        $*ERR.say: "Error while downloading update for extension { $uuid }:
                   { .message }";
      }
    }

    my $bytes = await $httpSession.send-and-read-async($message, :promise);
    await extractionExtensionArchive($bytes, $dir);
    Main.extensionManager.notifyExtensionUpdate($uuid);
  }
}

sub checkForUpdates is export {
  return unless Main.extensionManager.updatesSupported;

  my %metadata;
  for Main.extensionManager.uuids {
    my $e = Main.extensionManager.lookup($_);

    next unless $e.type == EXTENSION_TYPE_PER_USER;
    next if     $e.hasUpdate

    %metadata{$_}<version> = $e.metadata<version>;
  }

  return unless %metadata.keys.elems;

  my $vc = Global.Settings.get-boolean(
    'disable-extension-version-validation'
  );
  my %params = (
    shell-version              => Config.PACKAGE_VERSION,
    disable-version-validation => $vc
  );
  my $rb = GLib::Bytes.new( to-json(%metadatas) );
  my $m  = SOUP::Message.new(
    'POST',
    "{ REPOSITORY_URL_UPDATE }?{ SOUP::Form.encode-hash(%params) }",
  );
  $m.set-request-body-from-bytes('application/json', $rb);

  my $json = do {
    CATCH {
      default { $*ERR.say: "Update check failed: { .message }" }
    }

    my $bytes = await $httpSession.send-and-read-async($m, ;promise);
    checkResponse($m);
    Gnome::Shell::Misc::TextDecoder.decode($bytes.get-data);
  }

  my @updates;
  my $perations = from-json($json);
  for $operations.pairs {
    @updates.push: .key if .value eq <upgrade downgrade>.any
  }

  {
    CATCH {
      default {
        $*ERR.say: "Some extensions updates failed to download: {
                    .message }";
      }
    }

    await Promise.allof( @updates.map({ downloadExtension($_) }) );
  }
}

class Gnome::Shell::IO::Dialog::Extension::Installer
  is Gnome::Shell::UI::Dialog::Modal
{
  has $!uuid;
  has $!info;
  has $!invocation;

  submethod BUILD ( :$!uuid, :$!info, :$!invocation ) {
    my $s = self;
    self.setButtons([
      {
        label  => '_Cancel',
        action => -> *@a { $s.onCancelButtonPressed( |@a ) }
        key    => MUTTER_CLUTTER_KEY_Escape
      },

      {
        label   => 'Install',
        action  => -> *@a { $s.onInstallButtonPressed( |@a ) },
        default => True
      }
    );

    my $content = Gnome:Shell::UI::Dialog::Dialog::Message::Content.new(
      title       => 'Install Extension',
      description => "Download and install '{
                      $!info<name> }' from extensions.gnome.org?"
    );

    self.contentLayout.add($content);
  }

  method onCancelButtonPressed ( *@a ) {
    self.close;
    $!invocation.return-value(
      GLib::Variant.new( '(s)', ['cancelled'] )
    );
  }

  method onInstallButtonPressed ( *@a ) {
    self.close;

    my $message = SOUP::Message.new-from-encoded-form(
      'GET',
      REPOSITORY_URL_DOWNLOAD.&sf($!uuid),
      SOUP::Form.encode-hash( %{ shell-version => Config.PACKAGE_VERSION } );
    );

    my $dir = GIO::File.new-for-path(
      Global.userdatadir.add('extensions').add($!uuid).absolute
    );

    {
      CATCH {
        default {
          $*ERR.say: "Error while installing { $!uuid }: { .message }";
          $!invocation.return-dbus-error(
            'org.gnome.Shell.ExtensionError',
            .message
          );
        }
      }

      my $bytes = await $!httpSession.send-and-read-async($message, :promise);
      checkResponse($message);

      await extractExtensionArchive($bytes, $dir);

      my $extension = Main.extensionManager.createExtensionObject(
        $!uuid,
        $dir,
        EXTENSION_TYPE_PER_USER
      );
      Main.extensionManager.loadExtension($extension);
      unless Main.extensionManager.enableExtension($!uuid) {
        X::Gnome::Shell::Error.new(
          "Cannot enable extension { $!uuid }"
        ).throw;
      }

      $!invocation.return-value(
        GLib::Variant.new( '(s)', ['successful'] )
      );
    }
  }


}

INIT {
  $httpSession = SOUP::Session
}
