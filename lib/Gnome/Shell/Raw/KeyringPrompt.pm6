use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Mutter::Raw::Definitions;
use Gnome::Shell::Raw::Definitions;

unit package Gnome::Shell::Raw::KeyringPrompt;

### /home/cbwood/Projects/gnome-shell/src/shell-keyring-prompt.h

sub shell_keyring_prompt_cancel (ShellKeyringPrompt $self)
  is native(gnome-shell)
  is export
{ * }

sub shell_keyring_prompt_complete (ShellKeyringPrompt $self)
  returns uint32
  is native(gnome-shell)
  is export
{ * }

sub shell_keyring_prompt_get_confirm_actor (ShellKeyringPrompt $self)
  returns MutterClutterText
  is native(gnome-shell)
  is export
{ * }

sub shell_keyring_prompt_get_password_actor (ShellKeyringPrompt $self)
  returns MutterClutterText
  is native(gnome-shell)
  is export
{ * }

sub shell_keyring_prompt_new ()
  returns ShellKeyringPrompt
  is native(gnome-shell)
  is export
{ * }

sub shell_keyring_prompt_set_confirm_actor (
  ShellKeyringPrompt $self,
  MutterClutterText  $confirm_actor
)
  is native(gnome-shell)
  is export
{ * }

sub shell_keyring_prompt_set_password_actor (
  ShellKeyringPrompt $self,
  MutterClutterText  $password_actor
)
  is native(gnome-shell)
  is export
{ * }
