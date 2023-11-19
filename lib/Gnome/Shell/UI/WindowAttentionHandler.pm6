use v6.c;

#use Gnome::Shell;
use Gnome::Shell::UI::Main;
#use Gnome::Shell::UI::MessageTray;

### /home/cbwood/Projects/gnome-shell/js/ui/windowAttentionHandler.js

class Gnome::Shell::UI::WindowAttentionSource
  is Gnome::Shell::UI::MessageTray::Source
{
  has $!window   is built;
  has $!app      is built;

  has $!tracker;

  submethod BUILD {
    $!window.notify($_).tap( -> *@a {
      self.sync;
    }) for <demands-attention urgent>;

    $!window."$_"().tap(-> *@a { self.destroy }) for <focus unmanaged>;
  }

  method sync {
    return if $!window.demands-attention || $!window.urgent;
    self.destroy;
  }

  method createPolicy {
    do if $!app && $!app.get-app-info {
      my $id = $!app.get-id.subst(/'.desktop'$/, '');
      Gnome::Shell::UI::MessageTray::NotificationApplicationPolicy.new($id)
    } else {
      Gnome::Shell::UI::MessageTray::NotificationApplicationPolicy.new;
    }
  }

  method createIcon ($size) {
    $!apop.create-icon-texture($size);
  }

  method destroy {
    $!window.disconnect(self);
  }

  method open {
    Main.activateWindow($!window);
  }

}

class Gnome::Shell::UI::WindowAttentionHandler {
  has $!tracker;

  submethod BUILD {
    $!tracker = UI<WindowTracker>.get_default;

    global.display.window-demands-attention.tap(-> *@a {
      self.onWindowsDemandsAttention( |@a );
    });

    global.display.windows-marked-urgent.tap(-> *@a {
      self.onWindowsDemandsAttention( |@a );
    });
  }

  method getTitleAndBanner ($app, $window) {
    ( $app.get-name, "{ $window.title } is ready" )
  }

  method onWindowDemandsAttention ($display, $window, *@) {
    return if $window.not || $window.has-focus || $window.is-skip-taskbar;

    my $app    = $!tracker.get-window-app($window);
    my $source = Gnome::Shell::WindowAttentionSource.new(:$app, :$window);
    UI<MessageTray>.add($source);

    my ($title, $banner) = getTitleAndBanner($app, $window);
    my $notification = Gnome::Shell::MessageTray::Notification.new(
      $source,
      $title,
      $banner
    );
    $notification.activated.tap(-> *@a { $source.open });
    $notification.setForFeedback(True);
    $source.showNotification($notification);

    $window.notify('title').tap( -> *@a {
      $notification.update( |self.getTitleAndBanner );
    });

  }

}

class Gnome::Shell::UI::WindowAttention::Source
  is Gnome::Shell::UI::MessageTray::Source
{
  has $!app;
  has $!window;

  submethod BUILD (:$!app, :$!window) {
    self.title = $app.name

    my $self = self;
    $!window.connectObject(
      'notify::demands-attention', -> *@a { $self.sync( |@a ) },
      'notify::urgent',            -> *@a { $self.sync( |@a ) },
      'focus'                      -> *@a { $self.destroy     },
      'unmanaged',                 -> *@a { $self.destroy     }
    );
  }

  method sync {
    return if $!window.demands-attention || $!window.urgent;
    self.destroy;
  }

  method createPolicy {
    my $id = $!app.id.subst(/ '.desktop'$/, '');
    $!app && $!app.app-info
      ?? Gnome::Shell::UI::MessageTray::NotificationApplicationPolicy($id)
      !! Gnome::Shell::UI::Messagetray::NotificationGenericPolicy;
  }

  method createIcon ($size) {
    $!app.create-icon-textgure($size);
  }

  method destroy ($params) {
    $!window.disconnectObject(self);

    # cw: ???
    #super.destroy($params);
  }

  method open {
    Main.activateWindow($!window);
  }

}





}
