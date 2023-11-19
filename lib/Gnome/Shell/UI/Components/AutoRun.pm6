use v6.c;

use Gnome::Shell::Raw::Types;

### /home/cbwood/Projects/gnome-shell/js/ui/components/autorunManager.js

constant SETTINGS_SCHEMA         = 'org.gnome.desktop.media-handling';
constant SETTING_DISABLE_AUTORUN = 'autorun-never';
constant SETTING_START_APP       = 'autorun-x-content-start-app';
constant SETTING_IGNORE          = 'autorun-x-content-ignore';
constant SETTING_OPEN_FOLDER     = 'autorun-x-content-open-folder';

enum AutorunSetting <RUN IGNORE FILES ASK>;

class Gnome::Shell::UI::Components::Autorun::ContentTypeDiscoverer { ... }
class Gnome::Shell::UI::Components::Autorun::Dispatcher            { ... }
class Gnome::Shell::UI::Components::Autorun::Notification          { ... }
class Gnome::Shell::UI::Components::Autorun::Source                { ... }

constant C   = Gnome::Shell::UI::Components::Autorun::ContentTypeDiscoverer;
constant B   = Gnome::Shell::UI::MessageTray::Notification::Banner;
constant D   = Gnome::Shell::UI::Components::Autorun::Dispatcher;
constant N   = Gnome::Shell::UI::Components::Autorun::Notification;
constant SRC = Gnome::Shell::UI::Components::Autorun::Source;

sub shouldAutorunMount ($m) {
  my ($r, $v) = ( .get-root, .get-volume ) given $m;

  return False unless $v           && $v.allowAutorun;
  return False if     $r.is-native && isMountRootHidden($r);

  True;
}

sub isMountRootHidden ($r) {
  $r.get-path.contains('/.');
}

sub isMountNoLocal ($m) {
  my $v = $m.get-volume;

  return True unless $v;

  $v.get-identifier('class') eq 'network';
}

sub startAppForMount ($a, $m) {
  my ($r, $rv, $f) = ( $m.get-root, False, [] );

  $f.push: $r;
  do {
    CATCH {
      default {
        $*ERR.say: "Unable to launch the app {
                    $app.name }: { .message }";
      }
    }

    $app.launch($f, Global.create-app-launch-context)
  }
}

constant HotplugSnifferIface = loadInterfaceXML(
  'org.gnome.Shell.HotplugSniffer'
);

constant HotplugSnifferProxy = Gio.DBusProxy.makeProxyWrapper(
  HotplugSnifferIface
);

sub HotplugSniffer() {
  HotplugSnifferProxy.new(
    GIO::DBus::Session.new(
      'org.gnome.Shell.HotplugSniffer',
      '/org/gnome/Shell/HotplugSniffer'
    )
  )
}

class Gnome::Shell::UI::Component::Automount::ContentTypeDiscoverer {
  has $!settings;

  submethod TWEAK {
    $!settings = GIO::Settings.new(SETTINGS_SCHEMA);
  }

  method guessContentTypes ($m) {
    my $autorunEnabled = $!settings.get-boolean(SETTING_DISABLE_AUTORUN);
    my $shouldScan     = $autorunEnabled && isMountNonLocal($m).not;

    my $contentTypes = [];
    if $shouldScan {
      {
        CATCH {
          default {
            $*ERR.say: "Unable to guess content types on added mount {
                        $m.name }: { .message }";
          }
        }

        $contentTypes = await $m.guess-content-type;
      }

      $contentTypes = HotplugSniffer().SniffURIAsync($m.get-root.get-uri)
        if $contentTypes.elems.not
    }

    $contentTypes .= grep( *.type neq 'x-content/win32-software' );

    my $apps = do for $contentTypes[] {
      do if GIO::AppInfo.get-default-for-type($_) -> $t {
        $t;
      }
    }

    $apps.push: GIO::AppInfo.get-default-for-type('inode/directory')
      if $apps.elems.not;

    ($apps, $contentTypes);
  }

  class Gnome::Shell::UI::Autorun::Manager {
    has $!session;
    has $!volumeMonitor;
    has $!dispatcher;

    submethod TWEAK {
      $!session       = Gnome::Shell::Misc::GnomeSession::SessionManager;
      $!volumeMonitor = GIO::VolumeMonitor.get;
      $!dispatcher    = D.new(self);
    }

    method enable {
      my $s = self;
      $!volumeMonitor.mount-added.tap: sub ($mon, $mnt, *@) {
        $s.onMountAdded($mon, $mnt);
      }
      $!volumeMonitor.mount-removed.tap: sub ($mon, $mnt, *@) {
        $s.onMountRemoved($mon, $mnt);
      }
    }

    method disable {
      $!volumeMonitor.disconnect( :all );
    }

    method onMountAdded ($mon, $mnt) {
      return unless $!session.SessionIsActive;

      my ($a, $c) = await C.new.guessContentTypes($mnt);
      $!dispatcher.addMount($mount, $a, $c);
    }

    method onMountRemoved ($mon, $mnt) {
      $!dispatcher.removeMount($mnt);
    }
  }

}

class Gnome::Shell::UI::Components::Autorun::Dispatcher {
  has $!manager    is built;
  has @!sources
  has $!settings;

  submethod TWEAK {
    $!settings = GIO::Settings.new(SETTINGS_SCHEMA);
  }

  multi method new ($manager) {
    self.bless( :$manager );
  }

  method getAutorunSettingsForType ($c) {
    return RUN    if $!settings.get-strv(SETTING_START_APP).first($c).defined;
    return IGNORE if $!settings.get-strv(SETTING_IGNORE).first($c).defined;
    return FILES  if $!settings.get-strv(SETTING_OPEN_FOLDER).first($c).defined;

    ASK
  }

  method getSourceForMount ($m) {
    my $f = $!sources.grep({ .mount.is($m) });

    return $f.head if $f.elems === 1;
    Nil;
  }

  method addSource ($m, $a) {
    return if $.getSourceForMount($m);

    $!sources.push: SRC.new($!manager, $m, $a);
  }

  method addMount ($m, $a, $c) {
    return if     $!settings.get-boolean(SETTING_DISABLE_AUTORUN);
    return unless $!shouldAutorunMount($m);

    my $setting = $c.elems > 0 ?? $.getAutorunSettingsForType($c.head)
                               !! ASK;

    my ($s, $app);

    my $app = given $setting {
      when IGNORE { return }
      when RUN    { GIO::AppInfo.get-default-for-type($c.head) }
      when FILES  { GIO::AppInfo.get-default-for-type('inode/directory') }
    }

    $s = startAppForMount($a, $m) if $app;

    $.addSource($m, $a) unless $s;
  }

  method removeMount ($m) {
    if $!getSourceForMount($m) -> $s {
      $s.destroy;
    }
  }

}

class Gnome::Shell::UI::Components::Autorun::Source
  is Gnome::Shell::UI::MessageTray::Source
{
  has $!manager is built;
  has $.mount              handles<getIcon>;
  has $.apps;
  has $!notification;

  submethod TWEAK {
    $!notification = N.new($!manager, self);

    #self.::Gnome::Shell::UI::MessageTray::Source::TWEAK( name => $m.name );

    Main.messageTray.add(self);
    $.showNotification($!notification);
  }

  # cw: Sicne MessageTray::Source has yet to be written, the named parameter
  #     <name> will need to be updated.
  method new ($manager, $mount, $apps) {
    self.bless( :$manager, :$mount, :$apps, name => $mount.name );
  }

  method createPolicy {
    Gnone::Shell::UI::Components::MessageTray.NotificationApplicationPolicy(
      'org.gnome.Nautilus'
    );
  }
}

class Gnome::Shell::UI::Components::Autorun::Notification
  is also Gnome::Shell::UI::MessageTray::Notification
{
  has $!manager is built;
  has $!mount;

  submethod TWEAK (
    $!mount = $.source.mount;
  }

  multi method new ($manager, $source) {
    self.bless( :$manager, :$source );
  }

  method createBanner {
    for $.source.apps[] {
      my $banner = B.new(self);

      if $.buttonForApp($app) -> $b {
        $banner.addButton($b);
      }

    }
    $banner;
  }

  method buttonForApp ($app) {
    my $box = Gnome::Shell::St::BoxLayout.new(
      x-expand => True,
      x-align  => CLUTTER_ACTOR_ALIGN_START
    );

    my $icon = Gnome::Shell::St::Icon.new(
      gicon       => $app.icon,
      style-class => 'hotplug-notification-item-icon'
    );
    my $label = Gnome::Shell::St::Bin.new(
      child => Gnome::Shell::St::Label.new(
        text    => "Open with { $app.name }",
        y-align => CLUTTER_ACTOR_ALIGN_CENTER
      )
    );
    $box.add-child($_) for $icon, $label);

    my $button = Gnome::Shell::St::Button.new(
      child       => $box,
      x-expand    => True,
      button-mask => ST_BUTTON_MASK_ONE,
      style-class => 'hotplug-notification-item button'
    );
    my $s = self;
    $button.clicked.tap: SUB {
      startAppForMount($app, $!mount);
      $s.destroy;
    }

    $button;
  }

  method activate {
    callsame;
    startAppForMount(
      GIO::AppInfo::get-default-for-type('inode/directory'),
      $!mount
    )
  }
}
