use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use GLib::Raw::Structs;
use GIO::Raw::Definitions;
use NetworkManager::Raw::Definitions;
use NetworkManager::Raw::Structs;
use Gnome::Shell::Raw::Definitions;
use Gnome::Shell::Raw::Enums;
use Gnome::Shell::Raw::Structs;

unit package Gnome::Shell::Raw::NetworkAgent;

### /home/cbwood/Projects/gnome-shell/src/shell-network-agent.h

sub shell_network_agent_add_vpn_secret (
  ShellNetworkAgent $self,
  Str               $request_id,
  Str               $setting_key,
  Str               $setting_value
)
  is native(gnome-shell)
  is export
{ * }

sub shell_network_agent_get_type ()
  returns GType
  is native(gnome-shell)
  is export
{ * }

sub shell_network_agent_respond (
  ShellNetworkAgent         $self,
  Str                       $request_id,
  ShellNetworkAgentResponse $response
)
  is native(gnome-shell)
  is export
{ * }

sub shell_network_agent_search_vpn_plugin (
  ShellNetworkAgent $self,
  Str               $service,
                    &callback (ShellNetworkAgent, GAsyncResult, gpointer),
  gpointer          $user_data
)
  is native(gnome-shell)
  is export
{ * }

sub shell_network_agent_search_vpn_plugin_finish (
  ShellNetworkAgent       $self ,
  GAsyncResult            $result,
  CArray[Pointer[GError]] $error
)
  returns NMVpnPluginInfo
  is native(gnome-shell)
  is export
{ * }

sub shell_network_agent_set_password (
  ShellNetworkAgent $self,
  Str               $request_id,
  Str               $setting_key,
  Str               $setting_value
)
  is native(gnome-shell)
  is export
{ * }
