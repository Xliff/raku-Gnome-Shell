use v6.c;

use Method::Also;

use NativeCall;

use Gnome::Shell::Raw::Types;

use GIO::MountOperation;

use GLib::Roles::Object;
use GLib::Roles::Implementor;

our subset ShellMountOperationAncestry is export of Mu
  where ShellMountOperation | GMountOperationAncestry;

class Gnome::Shell::MountOperation is GIO::MountOperation {
  has ShellMountOperation $!gsmo is implementor;

  submethod BUILD ( :$shell-mount-operation ) {
    self.setShellMountOperation($shell-mount-operation)
      if $shell-mount-operation
  }

  method setShellMountOperation (ShellMountOperationAncestry $_) {
    my $to-parent;

    $!gsmo = do {
      when ShellMountOperation {
        $to-parent = cast(GMountOperation, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellMountOperation, $_);
      }
    }
    self.setGMountOperation($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::ShellMountOperation
    is also<ShellMountOperation>
  { $!gsmo }

  multi method new (
    ShellMountOperationAncestry  $shell-mount-operation,
                                :$ref                     = True
  ) {
    return unless $shell-mount-operation;

    my $o = self.bless( :$shell-mount-operation );
    $o.ref if $ref;
    $o;
  }
  multi method new {
    my $shell-mount-operation = shell_mount_operation_new();

    $shell-mount-operation ?? self.bless( :$shell-mount-operation ) !! Nil;
  }

  method show-processes-2 {
    self.connect($!gsmo, 'show-processes-2');
  }

  method get_show_processes_choices is also<get-show-processes-choices> {
    shell_mount_operation_get_show_processes_choices($!gsmo);
  }

  method get_show_processes_message is also<get-show-processes-message> {
    shell_mount_operation_get_show_processes_message($!gsmo);
  }

  method get_show_processes_pids ( :$raw = False ) 
    is also<get-show-processes-pids> 
  {
    propReturnObject(
      shell_mount_operation_get_show_processes_pids($!gsmo),
      $raw,
      GLib::Array.getTypePair
    );
  }

}


### /home/cbwood/Projects/gnome-shell/src/shell-mount-operation.h

sub shell_mount_operation_get_show_processes_choices (
  ShellMountOperation $self
)
  returns Str
  is native(gnome-shell)
  is export
{ * }

sub shell_mount_operation_get_show_processes_message (
  ShellMountOperation $self
)
  returns Str
  is native(gnome-shell)
  is export
{ * }

sub shell_mount_operation_get_show_processes_pids (
  ShellMountOperation $self
)
  returns GArray
  is native(gnome-shell)
  is export
{ * }

sub shell_mount_operation_new ()
  returns ShellMountOperation
  is native(gnome-shell)
  is export
{ * }
