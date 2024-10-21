use v6.c;

use Method::Also;

use JSON::GLib::Variant;
use GIO::DBus::Proxy;
use Gnome::Shell::Misc::FileUtils;
use Gnome::Shell::UI::Dialog;
use Gnome::Shell::UI::ModalDialog;
use Gnome::Shell::UI::QuickSettings;

constant LOCATION_SCHEMA       = 'org.gnome.system.location';
constant MAX_ACCURACY_LEVEL    = 'max-accuracy-level';
constant ENABLED               = 'enabled';
constant APP_PERMISSIONS_TABLE = 'location';
constant APP_PERMISSIONS_ID    = 'location';
constant GeoclueIface          = loadInterfaceXML('org.freedesktop.GeoClue2.Manager');
constant GeoclueManager        = GIO::DBus::Proxy.makeProxyWrapper(GeoclueIface);
constant AgentIface            = loadInterfaceXML('org.freedesktop.GeoClue2.Agent');

### /home/cbwood/Projects/gnome-shell/js/ui/status/location.js

enum GeoclueAccuracyLevelEnum = (
  GEOCLUE_ACCURACY_NONE         => 0,
  GEOCLUE_ACCURACY_COUNTRY      => 1,
  GEOCLUE_ACCURACY_CITY         => 4,
  GEOCLUE_ACCURACY_NEIGHBORHOOD => 5,
  GEOCLUE_ACCURACY_STREET       => 6,
  GEOCLUE_ACCURACY_EXACT        => 8
);

sub accuracyLevelToString ($a) {
  GeoclueAccuracyLevelEnum.enums{$a} || 'GEOCLUE_ACCURACY_NONE'
}

my $geoclueAgent;

class Gnome::Shell::UI::Status::Geoclue::Agent {
  also does GLib::Roles::Object;
  also does GLib::Roles::RegisterClass;

  has $!gs-geo-agent is implementor;

  has gboolean $!enabled            is g-attribute;
  has gboolean $!in-use             is g-attribute;
  has gint     $!max-accuracy-level is g-attribute  is ranged(0..8);

  has $!settings;
  has $!agent;
  has $!managerProxy;
  has $!connecting;

  submethod BUILD {
    $!settings = GIO::Settings.new(LOCATION_SCHEMA);
    $!settings.connectObject(
      "changed::{ENABLED}"            => SUB { self.notify('enabled') }
      "changed::{MAX_ACCURACY_LEVEL}" => SUB { self.onMaxAccuracyLevelChanged }
    );

    $!agent = GIO::DBus::Object.wrap(AgentIface, self);
    $!agent.export(GIO::DBus.system, '/org/freedesktop/GeoClue2/Agent');

    self.notify('enabled').tap: SUB { self.onMaxAccuracyLevelChanged }

    $!watchId = GIO::DBus::Utils.watch-name(
      G_BUS_SYSTEM,
      'org.freedesktop.GeoClue2',
      0,
      SUB { self.connectToGeoclue  },
      SUB { self.onGeoclueVanished }
    );
    self.onMaxAccuracyLevelChanged;
    self.connectToGeoclue;
    self.connectToPermissionStore;
  }

  method enabled is rw {
    Proxy.new:
      FETCH => -> $     { $!settings.get-boolean(ENABLED)    },
      STORE => -> $, \v { $!settings.set-boolean(ENABLED, v) }
  }

  method in-use {
    $!managerProxy?.InUse // False
  }

  method max-accuracy-level is also<MaxAccuracyLevel> {
    $.enabled
      ?? accuracyLevelToString($!settings.get-string(MAX_ACCURACY_LEVEL).uc)
      !! GEOCLUE_ACCURACY_NONE;
  }

  method AuthorizeAppAsync ( @p ($did, $ral), $i) is asynchronous {
    start {
      my $auth = AppAuthorizsser(
        $did,
        $ral,
        $!permStoreProxy,
        $.max-accuracy-level
      );

      my $r  = (await $auth.authorize) != GEOCLUE_ACCURACY_NONE;
      $i.return-value( JSON::GLib::Variant.deserialize-data(
        [True, $r],
        '(bu)'
      );
    }
  }

  method connectToGeoclue {
    return False unless $!managerProxy && $!connecting.not;

    $!connecting = True;
    GeoclueManager.new(
      GIO::DBus.system,
      'org.freedesktop.GeoClue2',
      '/org/freedesktop/GeoClue2/Manager',
      SUB { self.onManagerProxyReady }
    );
    True;
  }

  method onManagerProxyReady ($p, $e) is asynchronous {
    start {
      with $e {
        $*ERR.say: $e.message;
        $!connecting = False;
        return;
      }

      $!managerProxy = $p;
      $!managerProxy.g-properties-changed.tap: SUB {
        self.onGeocluePropsChanged( |$*A );
      }

      $.notify('in-use');

      {
        CATCH { default { $*ERR.say: .message } }

        await $!managerProxy.AddAgentAsync('gnome-shell');
        $!connecting = False;
        $.notifyMaxAccuracyLevel;
      }
    }
  }

  method onGeoclueVanished {
    $!managerProxy.disconnect(self);
    $!managerProxy = Nil;
    $.notify('in-use');
  }

  method onMaxAccuracyLevelChanged {
    $.notify('max-accuracy-level');
    $!notifyMaxAccuracyLevel unless $.connectToGeoclue;
  }

  method notifyMaxAccuracyLevel {
    $!agent.emit-property-changed(
      'MaxAccuracyLevel',
      JSON::GLib::Variant.deserialize-data($.maxAccuracyLevel, 'u')
    );
  }

  method onGeocluePropsChangedff ($proxy, $props) {
    $.notify('in-use') if $props.lookup-value('InUse');
  }

  method connectToPermissionStore {
    $!permStoreProxy = Nil;
    Gnome::Shell::Misc::PermissionStore.new(
      SUB { self.onPermStoreProxyReady( |$*A ) }
    )
  }

  sub onPermStoreProxyReady ($p, $e) {
    with $e {
      $*ERR.say: .message;
      return;
    }

    $!permStoreProxy = $p;
  }
}

class Gnome::Shell::UI::Status::Location::Indicator {
  has $!desktopId        is built;
  has $!reqAccuracyLevel is built;
  has $!permStoreProxy   is built;
  has $!maxAccuracyLevel is built;

  has $!permissions   = %{};
  has $!accuracyLevel = GEOCLUE_ACCURACY_NONE;

  method authorize is asynchronous {
    start {
      Gnome::Shell::AppSystem.default.lookup-app("{ $!desktopId }.desktop");
      return $.completeAuth without $!app || $!permStoreProxy;

      {
        CATCH {
          when X::GLib::GError {
            if .error.domain = GIO::DBus::Error.quark {
              ($!accuracyLevel, $!permStoreProxy) = ($!reqAccuracyLevel, Nil);
              self.completeAuth;
            } else {
              $*ERR.say: .message;
              $!permissions = %{};
            }
          }
        }

        my $*GERROR-EXEPTIONS = True;
        $!permissions = (
          await $!permStoreProxy
        ).LookupAsync(
          APP_PERMISSIONS_TABLE,
          APP_PERMISSIONS_ID
        );
      }

      with $!permissions{$!desktopId} {
        $!accuracyLevel =
          GeoclueAccuracyLevel.enums{await $.userAuthorizeApp} ||
          GEOCLUE_ACCURACY_NONE;
      } else {
        $.userAuthorizeApp;
      }

      $.completeAuth;
    }

    method userAuthorizeApp {
      my $n = ( .name, my $ai = .app-info ) given $!app;
      my $r =   $ai.get-locale-string('X-Geoclue-Reason');

      $!dialog = Gnome::Shell::UI::Location::Dialog.new(
        name             => $name,
        reason           => $reason,
        reqAccuracyLevel => $!reqAccuracyLevel
      );

      my $p = Promise.new;
      my $t = $!dialog.response.tap: SUB {
        $t.untap;
        $!accuracyLevel = $*A[1];
        $p.keep;
      }

      $!dialog.open;
      await $p;
    }
  }

  method completeAuth {
    $!accuracyLevel = $!accuracyLevel.&clamp(0..$!maxAccuracyLevel)
      if $!accuracyLevel != $;
    $.saveToPermissionStore;

    $!accuracyLevel;
  }

  method saveToPermissionStore is asynchronous {
    start {
      return unless $!permStoreProxy;

      my $lStr = accurayuLevelToString($!accuracyLevel);
      my $dStr = DateTime.now.Str;
      $!permissions{$!desktopId} = [$lStr, $dStr];

      {
        CATCH { default { $*ERR.say: .message } }

        await $!permStoreProxy.SetAsync(
          APP_PERMISSIONS_TABLE,
          True,
          APP_PERMISSIONS_ID,

          $!permissions,
          JSON::GLib::Variant.deserialize-data(
            %(),
            'av'
          )
        );
      }
    }
  }
}

class Gnome::Shell::UI::Location::Dialog
  is   Gnome::Shell::UI::ModalDialog
  does GLib::Roles::StaticClass
{
  method response (gint) is g-signal { }

  has $!reqAccuracyLevel;

  submethod BUILD ( :$name, :$reason, :$!reqAccuracylevel ) {
    self.setAttributes( style-class => 'geolocation-dialog' );

    my $c = Gnome::Shell::UI::Dialog::Message::Content.new(
      title => 'Allow location access',
      description => "The app { $name } wants to access your location."
    );

    my $l = Gnome::Shell::St::Label.new(
      text        => $reason,
      style-class => 'message-dialog-description'
    );
    my $i = Gnome::Shell::St::Label.new(
      text        => "Location access can be changed at any time from the {
                      '' }privacy settings."
      style-class => 'message-dialog-description'
    );
    $c.add-child($_) for $l, $i;

    self.setInitialKeyFocus(
      self.addButton(
        label  => 'Deny Access',
        action => SUB { self.onDenyClicked }
        key    => CLUTTER_KEY_Escape
      }
    )
    self.addButton(
      label  => 'Grant Access',
      action => SUB { self.onGrantclicked }
    );
  }

  method onGrantClicked {
    $.emit('response', $!reqAccuracyLevel);
    $.close;
  }

  method onDenyClicked {
    $.emit('response', GEOCLUE_ACCURACY_NONE);
    $.close
  }
}













  # ...

}


sub getGeoclueAgent {
  $geoclueAgent //= Gnome::Shell::UI::Status::GeoclueAgent.new;
}
