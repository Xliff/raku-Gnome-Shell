use v6.c;

use NativeCall;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::NetworkAgent;

use NetworkManager::SecretAgent::Old;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

our subset ShellNetworkAgentAncestry is export of Mu
  where ShellNetworkAgent | NMSecretAgentOldAncestry;

class Gnome::Shell::NetworkAgent is NetworkManager::SecretAgent::Old {
  has ShellNetworkAgent $!sna is implementor;

  submethod BUILD ( :$shell-network-agent ) {
    self.setShellNetworkAgent($shell-network-agent)
      if $shell-network-agent
  }

  method setShellNetworkAgent (ShellNetworkAgentAncestry $_) {
    my $to-parent;

    $!sna = do {
      when ShellNetworkAgent {
        $to-parent = cast(NMSecretAgentOld, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellNetworkAgent, $_);
      }
    }
    self.setNMSecretAgentOld($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::ShellNetworkAgent
  { $!sna }

  multi method new (
    ShellNetworkAgentAncestry  $shell-network-agent,
                              :$ref                  = True
  ) {
    return unless $shell-network-agent;

    my $o = self.bless( :$shell-network-agent );
    $o.ref if $ref;
    $o;
  }

  # Type: NMDbusConnection
  method dbus-connection ( :$raw = False ) is rw  is g-property {
    my $gv = GLib::Value.new( GIO::DBus::Connection.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('dbus-connection', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          GIO::DBus::Connection.getTypePair
        );
      },
      STORE => -> $, GObject() $val is copy {
        $gv.object = $val;
        self.prop_set('dbus-connection', $gv);
      }
    );
  }

  # Type: string
  method identifier is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_STRING );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('identifier', $gv);
        $gv.string;
      },
      STORE => -> $, Str() $val is copy {
        $gv.string = $val;
        self.prop_set('identifier', $gv);
      }
    );
  }

  # Type: boolean
  method auto-register is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('auto-register', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        $gv.boolean = $val;
        self.prop_set('auto-register', $gv);
      }
    );
  }

  # Type: boolean
  method registered is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('registered', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        warn 'registered does not allow writing'
      }
    );
  }

  # Type: NMSecretAgentCapabilities
  method capabilities ( :$flags = False ) is rw  is g-property {
    my $gv = GLib::Value.new(
      GLib::Value.typeFromEnum(NMSecretAgentCapabilities)
    );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('capabilities', $gv);
        my $flags = $gv.valueFromEnum(NMSecretAgentCapabilities);
        return $flags unless $flags;
        getFlags(NMSecretAgentCapabilities, $flags);
      },
      STORE => -> $,  $val is copy {
        $gv.valueFromEnum(NMSecretAgentCapabilities) = $val;
        self.prop_set('capabilities', $gv);
      }
    );
  }

  method add_vpn_secret (
    Str() $request_id,
    Str() $setting_key,
    Str() $setting_value
  ) {
    shell_network_agent_add_vpn_secret(
      $!sna,
      $request_id,
      $setting_key,
      $setting_value
    );
  }

  method get_type {
    state ($n, $t);

    unstable_get_type( self.^name, &shell_network_agent_get_type, $n, $t );
  }

  method respond (Str() $request_id, Int() $response) {
    my ShellNetworkAgentResponse $r = $response;

    shell_network_agent_respond($!sna, $request_id, $r);
  }

  method search_vpn_plugin (
    Str()    $service,
             &callback,
    gpointer $user_data = gpointer
  ) {
    shell_network_agent_search_vpn_plugin(
      $!sna,
      $service,
      &callback,
      $user_data
    );
  }

  method search_vpn_plugin_finish (
    GAsyncResult()          $result,
    CArray[Pointer[GError]] $error  = gerror
  ) {
    clear_error;
    my $mrv = shell_network_agent_search_vpn_plugin_finish(
      $!sna,
      $result,
      $error
    );
    set_error($error);
    $mrv;
  }

  method set_password (
    Str() $request_id,
    Str() $setting_key,
    Str() $setting_value
  ) {
    shell_network_agent_set_password(
      $!sna,
      $request_id,
      $setting_key,
      $setting_value
    );
  }

}
