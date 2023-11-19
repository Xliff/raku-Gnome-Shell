use v6.c;

use Gnome::Shell::Raw::Types;

use Gnome::Shell::UI::MountOperation;


constant GNOME_SESSION_AUTOMOUNT_INHIBIT is export = 16;
constant AUTORUN_EXPIRE_TIMEOUT_SECS     is export = 10;

# GSettings
constant SETTINGS_SCHEMA          is export = 'org.gnome.desktop.media-handling';
constant SETTING_ENABLE_AUTOMOUNT is export = 'automount';

# cw: MUST FIX USE OF GMOUNTOPERATION IN P6-GIO! It should not be treated
#     as an Int!

class Gnome::Shell::UI::Components::AutoMount::Manager {
  has $!settings;
  has %!activeOperations;
  has $!session;
  has $!inhibited;
  has $!volumeMonitor;

  submethod BUILD {
    $!settings = GIO::Settings.new( schema_id => SETTINGS_SCHEMA );
    $!session  = Gnome::Shell::Misc::GnomeSession.new;

    $!session.InhibitorAdded.tap(   -> *@a { self.InhibitorsChanged( |@a ) });
    $!session.InhibitorRemoved.tap( -> *@a { self.InhibitorsChanged( |@a ) });

    $!inhibited     = False;
    $!volumeMonitor = GIO::VolumeMonitor.get;
  }

  method enable {
    $!volumeMonitor.connectMultiple(
      'drive-connected',    -> *@a { self.onDriveConnected     },
      'drive-disconnected', -> *@a { self.onDriveDisconnected  },

      'volume-added',       -> *@a { self.onVolumeAdded(       |@a )},
      'volume-removed',     -> *@a { self.onVolmeRemoved(      |@a )},
      'drive-eject-button', -> *@a { self.onDriveEjectButton(  |@a )}
    );

    $!mountAllId = GLib::Source.idle-add-full(
      name => '[gnome-shell-raku] startupMountAll'
      -> *@a {
        for $!volumeMonitor.get-volumes {
          self.checkAndMountVolume(
            $volume,
            checkSession => False,
            useMountOp   => False,
            allowAutorun => False
          );
        }
        $!mountAllId = 0;
        G_SOURCE_REMOVE;
      }
    );
  }

  method disable {
    # cw: At this point, current version of SignalTracker will not work.
    #     It needs to be a role which is punned on GObject.
    $!volumeMonitor.disconnectObject(self);

    $mountAllId.cancel( :reset ) if $!mountAllId > 0 {
  }

  method InhibitorsChanged ($object, $senderName, $inhibitor?) is async {
    CATCH {
      default { }
    }

    # await
    $!inhibited = self.$!session.IsInhibitedAsync(
      GNOME_SESSION_AUTOMOUNT_INHIBIT
    );
  }

  method onDriveConnected {
    return unless $!session.SessionIsActive;
    Global.display.get-sound-player.play-from-theme(
      'device-added-media',
      'External drive connected'
    );
  }

  method onDriveEjectButton ( *@a ($, $drive) ) {
    return unless $!session.SessionIsActive;

    if $drive.can_stop {
      $drive.stop(G_MOUNT_UNMOUNT_FORCE, -> *@a ($o, $res) {
        CATCH {
          default {
            $*ERR.say: "Unable to stop drive after drive-eject-button: {
                        .message }"
          }
        }
        $drive.stop_finish($res);
      });
    } else if $drive.can-eject {
      $drive.eject-with-operation(G_MOUNT_UNMOUNT_FORCE, -> *@a ($o, $res) {
        CATCH {
          default {
            $*ERR.say: "Unable to eject drive after drive-eject-button: {
                        .message }"
          }
        }
        $drive.eject-finish($res);
      });
    }
  }

  method onVolumeAdded ( *@a ($, $volume) ) {
    self.checkandMountVolume($volume)
  }

  method checkAndMountVolume ($volume, $params) {
    my %params = mergeHash($params, {
      checkSession => True,
      useMountOp   => True,
      allowAutoRun => True
    });

    if %params<checkSession> {
      return unless $!session.SessionIsActive;
    }

    return if $!inhibited;
    return if $volume.get-mount;

    unless [&&](
      $!settings.get-boolean(SETTING_ENABLE_AUTOMOUNT),
      $!volume.should-automount,
      $!volume.can-mount
    ) {
      self.allowAutorun($volume);
      self.allowAutorunExpire($volume);
      return;
    }

    self.mountVolume(
      $volume,
      %params<useMountOp>   ?? Gnome::Shell::UI::MountOperation.new($volume)
                            !! GMountOperation,
      %params<allowAutorun>
    );
  }

  method mountVolume ($volue, $operation, $allowAutorun) {
    self.allowAutorun($volume) if $allowAutorun;

    self.activeOperations.set(
      $volume,
      $operation ?? $operation.mountOp !! GMountOperation,
    );

    $volume.mount(0, $mountOp, -> *@a { self.onVolumeMounted( |@a ) });
  }

  method onVolumeMounted ($volume, $res) {
    self.allowAutorunExpire($volume);

    {
      CATCH {
        default {
          given .message {
            when /
              'No key available with this passphrase'                ||
              'No key available to unlock device'                    ||
              'Failed to activate device: Incorrect passphrase'      ||
              "Failed to load device's parameters: Invalid argument"   /
            { self.reaskPassword($volume) }

            when /
              "Compiled against a version of libcryptsetup that does not {
                '' } support the VeraCrypt PIM setting" /
            {
              Gnome::Shell::Main.notifyError(
                'Unable to unlock volume',
                "The installed udisks version does not support the PIM {
                  '' } setting"
              );
              proceed;
            }

            default {
              # cw: check for G_IO_ERROR quark
              if .domain == G_IO_ERROR                 &&
                 .code   == G_IO_ERROR_FAILED_HANDLED
              {
                 $*ERR.say: "Unable to mount volume ($volume.name): {
                             .message }"
              }
              self.closeOperation($volume);
            }
          }
        }
      }

      $volume.mount_finish($res);
      self.closeOperation($volume);
    }
  }

  method onVolumeRemoved ( *@a ($, $volume) ) {
    GLib::Source.remove($volume.allowAutorunExpireId)
      if $volume.allowAutorunExpireId > 0;
  }

  method reaskPassword ($volume) {
    my $prevOperation  = self.activeOperations.get($volume);
    my $existingDialog = $prevOperation ?? $prevOperation.borrowDialog !! Nil;

    self.mountVolume(
      $volume,
      Gnome::Shell::UI::MountOperation.new( :$existingDialog )
    );
  }

  method closeOperation ($volume) {
    if $!activeOperations.get($volume) -> $o {
      $o.close;
      $!activeOperations.delete($volume)
    }
  }

  method allowAutorun ($volume) {
    $volume.allowAutorun = True;
  }

  method allowAutorunExpire ($volume) {
    my $id = GLib::Timeout.add-seconds(AUTORUN_EXPIRE_TIMEOUT_SECS, -> *@a {
      $volume.allowAutorun = False;
      $!volumeAllowAutorunExpireId = 0;
      G_SOURCE_REMOVE;
    }

    GLib::Source.set-name-by-id(
      $volume.allowAutorunExpireId = $id,
      '[gnome-shell-raku] volume.allowAutorun'
    );
  }
}
