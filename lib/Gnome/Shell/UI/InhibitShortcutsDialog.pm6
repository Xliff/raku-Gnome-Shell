use v6.c;

use Gnome::Shell::UI::Dialog;
use Gnome::Shell::UI::ModalDialog;
use Gnome::Shell::UI::PermissionStore;

use GLib::Roles::Object;
use Mutter::Meta::Roles::InhibitShortcutsDialog;

constant APP_ALLOWLIST              is export = ('org.gnome.Settings.desktop');
constant WAYLAND_KEYBINDINGS_SCHEMA is export = 'org.gnome.mutter.wayland.keybindings';
constant APP_PERMISSIONS_TABLE      is export = 'gnome';
constant APP_PERMISSIONS_ID         is export = 'shortcuts-inhibitor';
constant GRANTED                    is export = 'GRANTED';
constant DENIED                     is export = 'DENIED';

class Gnome::Shell::UI::InhibitShortcutsDialog {
  also does GLib::Roles::Object;
  also does Mutter::Meta::Roles::InhibitShortcutsDialog;

  has $!window is built;
  has $!dialog is built;

  has $!permStore;

  submethod BUILD ( :$!window, :$ui-inhibit-shortcuts-dialog ) {
    if $ui-inhibit-shortcuts-dialog {
      self.setUiInhibitShortcutsDialog($ui-inhibit-shortcuts-dialog);
      return;
    }

    return unless $window;

    $!dialog = Gnome::Shell::UI::ModalDialog.new;
    self.buildLayout;

    self!setObject( GLib::Object.new(G_TYPE_OBJECT) );
  }

  method window is rw {
    Proxy.new:
      FETCH => -> $     { $!window },
      STORE => -> $, \w { $!window := w }
  }

  method app {
    Gnome::Shell::WindowTracker.get-default.get-window-app($!window);
  }

  method getRestoreAccel {
    my $setting = GIO::Settings.new( schema_id => WAYLAND_KEYBINDINGS_SCHEMA );
    my $accel   = $settings.get-strv('restore-shortcuts').head || '';

    GTK::Accelerator.get-label(
      |GTK::Accelerator.parse($accel)
    );
  }

  method shouldUsePermStore {
    return .is-window-backed with $!app;
    False;
  }

  method saveToPermissionStore ($grant) is async {
    return unless self.shouldUsePermStore && $!permStore;

    my $permissions;
    $permissions{ $!app.get-id } = [ $grant ];
    my $data = GLib::Variant.new('av');

    try {
      CATCH {
        default { $*ERR.say: .message }
      }

      await $!permStore.setAsync(
        APP_PERMISSIONS_TABLE,
        True,
        APP_PERMISSIONS_ID,
        $permissions,
        $data
      }
    }

    method buildLayout {
      my $name;
      $name   = $!app.get_name;
      $name //= $!window.title;

      my $content = Gnome::Shell::UI::Dialog::MessageDialogContent.new(
        title       => 'Allow inhibiting shortcuts',
        description => $name
          ?? "The application { $name} wants to inhibit shortcuts"
          !! "An application wants to inhibit shortcuts'"
      );

      my $restoreAccel = self.getRestoreAccel;
      if $restoreAccel {
        my $restoreLabel = Gnome::Shell::St::Label.new(
          text        => "You can restore shurtcuts by pressing {
                          $restoreAccel }",
          style-class => 'message-dialog-description'
        );
        $restoreLabel.clutter-text.ellipsize = PANGO_ELLIPSIZE_MODE_NONE;
        $restoreLabel.clutter-text.line-wrap = True;
        $content.add-child($restoreLabel);
      }

      $!dialog.contentLayout.add-child($content);

      $!dialog.addButton(
        label  => 'Deny',
        action => -> $, *@a {
          self.saveToPermissionStore(DENIED);
          self.emitResponse(DIALOG_RESPONSE_DENY)
        },
        key    => CLUTTER_KEY_ESCAPE
      );

      $!dialog.addButton(
        label   => 'Allow',
        action  => -> $, *@a {
          self.saveToPermissionStore(GRANTED);
          self.emitResponse(DIALOG_RESPONSE_ALLOW)
        },
        default => True
      );
    }

    method emitResponse ($response) {
      self.emit('response', $response);
      $!dialog.close;
    }

    method show is vfunc {
      my $appId = $!app.get_id;

      if $!app && APP_ALLOWLIST.first( * eq $appId, :k ) {
        self.emitResponse(DIALOG_RESPONSE_ALLOW);
        return;
      }

      unless self.shouldUsePermStore {
        $!dialog.open;
        return;
      }

      $!permStore = Gnome::Shell::Misc::PermissionsStore.new( -> $p, $e {
        if $e {
          $*ERR.say: $e.message;
          $!dialog.open;
          return;
        }

        try {
          CATCH {
            $!dialog.open;
            $*ERR.say: .message
          }

          my $permissions = $!permStore.lookupAsync(
            APP_PERMISSIONS_TABLE,
            APP_PERMISSIONS_ID
          );

          if $permissions{$appId}.defined.not {
            $!dialog.open;
          } elsif $permissions{$appId} == GRANTED {
            self.emitResponse(DIALOG_RESPONSE_ALLOW);
          } else {
            self.emitResponse(DIALOG_RESPONSE_DENY);
          }
        }
      });
    }

    method hide is vfunc {
      $!dialog.close;
    }
  }
