use v6.c;

use Gnome::Shell::WindowTracker;
use Gnome::Shell::UI::CheckBox;
use Gnome::Shell::UI::Dialog;
use Gnome::Shell::UI::ModalDialog;

use Gnome::Shell::UI::FileUtils;

constant requestIface = loadInterfaceXML('org.freedesktop.impl.portal.Request');
constant accessIface  = loadInterfaceXML('org.freedesktop.impl.portal.Access');

class Gnome::Shell::UI::AccessDialog
  is Gnome::Shell::UI::ModalDialog
{
    has $!invocation       is built;
    has $!handle           is built;
    has %!options          is built;
    has $!requestExported;
    has $!request;
    has %!choices;

    submethod BUILD (
      :$!invocation,
      :$!handle,
      :%!options,
      :$title,
      :$description,
      :$body
    ) {
      $!requestExported = False;

      # function _wrapJSObject(interfaceInfo, jsObj) {
      #     var info;
      #     if (interfaceInfo instanceof Gio.DBusInterfaceInfo)
      #         info = interfaceInfo;
      #     else
      #         info = Gio.DBusInterfaceInfo.new_for_xml(interfaceInfo);
      #     info.cache_build();
      #
      #     var impl = new GjsPrivate.DBusImplementation({g_interface_info: info});
      #     impl.connect('handle-method-call', function (self, methodName, parameters, invocation) {
      #         return _handleMethodCall.call(jsObj, info, self, methodName, parameters, invocation);
      #     });
      #     impl.connect('handle-property-get', function (self, propertyName) {
      #         return _handlePropertyGet.call(jsObj, info, self, propertyName);
      #     });
      #     impl.connect('handle-property-set', function (self, propertyName, value) {
      #         return _handlePropertySet.call(jsObj, info, self, propertyName, value);
      #     });
      #
      #     return impl;
      # }

      # NYI - .wrapRakuObject does not yet exist.
      $!request = GIO::DBus::ExportedObject.wrapRakuObject(
        requestIface,
        self
      );

      self.buildLayout($title, $description, $body, %options);
    }

    method buildLayout ($title, $description, $body, $options) {
      my $denyLabel  = $options<deny-label>  // 'Deny Access';
      my $grantLabel = $options<grant-label> // 'Grant Access';
      my $choices    = $options<choices>     // [];
      my $content    = Gnome::Shell::Dialog::UI::MessageDialogGContent(
        :$title,
        :$description
      );
      .contentLayout.add-actor($content);

      for $choices -> ($id, $name, $opts, $selected) {
        next unless $opts.elems;

        my $check = Gnome::Shell::UI::CheckBox.new;
        $check.getLabelActor.text = $name;
        $check.checked = $selected.lc eq 'true';
        $content.add-child($check);
        $!choices.set($id, $check);
      }

      my $bodyLabel = Gnome::Shell::St::Label.new(
        text    => $body,
        x-align => CLUTTER_ACTOR_ALIGN_CENTER
      );
      $bodyLabel.clutter-text.ellipsize = PANGO_ELLIPSIZE_MODE_NONE;
      $bodyLabel.clutter-text.line-wrap = True;
      $content.add-child($bodyLabel);

      self.addButton(
        label  => $denyLabel,
        action => self.sendResponse(DIALOG_RESPONSE_CANCEL),
        key    => CLUTTER_KEY_ESCAPE
      );
      self.addButton(
        label  => $grantLabel,
        action => self.sendResponse(DIALOG_RESPONSE_OK),
      );
    }

    method open {
      return False unless callsame;

      my $connection = $!invocation.get-connection;
      $!requestExported = $!request.export($connection, $!handle);
      True;
    }

    method CloseAsync ($invocation, $params) {
      if $!invocation.get-sender !=== $invocation.get-sender {
        $invocation.return_error_literal(
          G_DBUS_ERROR,
          G_DBUS_ERROR_ACCESS_DENIED,
          ''
        );
        return;
      }

      self.sendResponse(DIALOG_RESPONSE_CLOSED);
    }

    method sendResponse ($response) {
      $!request.unexport if $!requestExported;
      $!requestExported = False;

      my $results;
      if $response == DIALOG_RESPONSE_OK {
        for $!choices => ($id, $check) {
          $results{$id} = GLib::Variant.new('s', $check.checked.Str);
        }
      }

      self.closed.tap(-> *@a {
        $!invocation.return_value(
          # cw: Please note that GLib::Variant may not be mature enough
          #     to handle this particular call..
          GLib::Variant.new(
            '(ua{sv})',
            [ $response, $results ]
          );
        )
      })
      self.close;
    }
  }

}

class Gnome::Shell::UI::AccessDialog::DBus {
  has $!accessDialog;
  has $!windowTracker;
  has $!dbusImpl;

  submethod BUILD {
    $!windowTracker = Gnome::Shell::WindowTracker.get-default;

    $!dbusImpl = GIO::DBus::ExportedObject.wrapRakuObject(AccessIface, self);
    $!dbusImpl.export(GIO::DBus.session, '/org/freedesktop/portal/desktop');

    GIO::DBus.session.own-name(
      'org.gnome.shell.Portal',
      G_BUS_NAME_OWNER_FLAGS_REPLACE
    );
  }

  method AccessDialogAsync (
    (
      $handle,
      $appId,
      $parentWindow,
      $title,
      $description,
      $body,
      $options
    ),
    $invocation
  ) {a
    if $!accessDialog(
      $!invocation.return_error_literal(
        G_DBUS_ERROR_LIMITS_EXCEEDED,
        'Already showing a system access dialog'
      );
      return;
    }

    if $appId && "{ $appId.desktop }" ne $!windowTracker.focus_app.id  {
      $!invocation.return_error_literal(
        G_DBUS_ERROR,
        G_DBUS_ERROR_ACCESS_DENIED
        'Only the focused app is allowed to show a system access dialog'
      );
      return;
    }

    my $dialog = Gnome::Shell::UI::AccessDialog.new(
      $invocation,
      $handle,
      $title,
      $description,
      $body,
      $options
    );
    $dialog.open;
    $dialog.closed.tap(-> *@a { $!accessDialog = Nil });
    $!accessDialog = $dialog;
  }

}
