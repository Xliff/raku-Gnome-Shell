use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Mutter::Raw::Definitions;
use Mutter::Raw::Structs;
use Gnome::Shell::Raw::Definitions;
use Gnome::Shell::Raw::Structs;

unit package Gnome::Shell::Raw::St::FocusManager;

### /home/cbwood/Projects/gnome-shell/src/st/st-focus-manager.h

sub st_focus_manager_add_group (StFocusManager $manager, StWidget $root)
  is native(gnome-shell-st)
  is export
{ * }

sub st_focus_manager_get_for_stage (MutterClutterStage $stage)
  returns StFocusManager
  is native(gnome-shell-st)
  is export
{ * }

sub st_focus_manager_get_group (StFocusManager $manager, StWidget $widget)
  returns StWidget
  is native(gnome-shell-st)
  is export
{ * }

sub st_focus_manager_navigate_from_event (
  StFocusManager     $manager,
  MutterClutterEvent $event
)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_focus_manager_remove_group (StFocusManager $manager, StWidget $root)
  is native(gnome-shell-st)
  is export
{ * }
