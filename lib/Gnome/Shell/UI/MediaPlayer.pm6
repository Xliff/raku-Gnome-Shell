use v6.c;

use Gnome::Shell::Raw::Types;

use Gnome::Shell::UI::Main;
#use Gnome::Shell::UI::MessageList;
use Gnome::Shell::Misc::FileUtils;

### /home/cbwood/Projects/gnome-shell/js/ui/mpris.js

# constant DBusIface        is export  = loadInterfaceXML('org.freedesktop.DBus');
# constant DBusProxy        is export  = Gio.DBusProxy.makeProxyWrapper(DBusIface);
#
# constant MprisIface       is export  = loadInterfaceXML('org.mpris.MediaPlayer2');
# constant MprisProxy       is export  = Gio.DBusProxy.makeProxyWrapper(MprisIface);
#
# constant MprisPlayerIface is export  = loadInterfaceXML('org.mpris.MediaPlayer2.Player');
# constant MprisPlayerProxy is export  = Gio.DBusProxy.makeProxyWrapper(MprisPlayerIface);

constant MPRIS_PLAYER_PREFIX is export = 'org.mpris.MediaPlayer2.';

class Gnome::Shell::UI::MediaMessage
  is Gnome::Shell::UI::Message
{
  has $!player;
  has $!icon;

  submethod BUILD ( :$!player ) { }

  submethod TWEAK {
    $!icon = Gnome::Shell::St::Icon.new(
      style-class => 'media-message-cover-icon'
    });

    self.setIcon($!icon);

    self.secondaryBin.hide;
    self.closeButton.hide;

    my $p = $!player;
    $!prevButton = self.addMediaControl(
      'media-skip-backward-symbolic'
      -> *@a { $p.player.previous }
    );

    $!playPauseButton = self.addMediaControl( -> *@a {
      $p.playPause
    });

    $!nextBuffon = self.addMediaControl(
      'media-skip-forward-symbolic',
      -> *@a { $p.player.next }
    );

    $p.changed.tap( -> *@a { $s.update |@a ) });
    $p.closed.tap(  -> *@a { $s.close(|@a )  })
    self.update;
  }

  method clicked is vfunc {
    $!player.raise;
    Main.panel.closeCalendar();
  }

  method updateNavButton ($b, $s) {
    $b.reactive = $s;
  }

  method update {
    self.setTitle($!player.trackTitle);
    self.setBody($!player.trackArtists.join(', '));

    if $!player.trackCoverUrl -> $t {
      my $file = GIO::File.new-for-uri($t);
      $!icon.gicon = new GIO::File::Icon($file);
      $!icon.remove-style-class-name('fallback');
    } else if $!player.app {
      $!icon.gicon = $!player.app.icon;
      $!icon.add-style-class-name('fallback');
    } else {
      $!icon.icon-name = 'audio-x-generic-symbolic';
      $!icon.add-style-class-name('fallback');
    }

    if $!player.status === 'Playing' {
      $!playPauseButton.child.icon-name = $isPlaying
        ?? 'media-playback-pause-symbolic'
        !! 'media-playback-start-symbolic';
    }

    self!updateNavButton($!prevButton, $!player.canGoPrevious);
    self!updateNavButton($!nextButton, $!player.canGoNext);
  }
}

constant MM = Gnome::Shell::UI::MediaMessage;

class Gnome::Shell::UI::MediaPlayer
  is Gnme::Shell::Misc::Signals::EventEmitter
{
  has $!mediaProxy;
  has $!visible;
  has @!trackArtists;
  has $!trackCoverUrl;
  has $!busName;

  has $!playerProxy handles(
    status    => 'PlaybackStatus',
    playPause => 'PlayPauseAsync',
    canGoNext => 'CanGoNext',
    'next'    => 'NextAsync',
    previous  => 'PreviousAsync'
  );

  submethod BUILD ( :$!busName ) { }

  submethod TWEAK {

    my $s = self;
    $!mediaProxy = Gnome::Shell::UI::Media::Proxy.new(
      '/org/mpris/MediaPlayer2' -> *@a { $s.onMediaProxyReady( |@a ) }
    );
    $!playerProxy = Gnome::Shell::UI::Media::PlayerProxy.new(
      '/org/mpris/MediaPlayer2' -> *@a { $s.onPlayerProxyReady( |@a ) }
    }

    $!trackTitle = $!trackCoverUrl = '';

    ($!visible, @!trackArtists) = ( False, [] );
  }

  method trackArtists  { @!trackArtists }
  method trackTitle    { $!trackTitle }
  method trackCoverUrl { $!trackCoverUrl }
  method app           { $!app }

  method raise {
    $!app.activate          if $!app;
    $!mediaProxy.RaiseAsync if $!mediaProxy.CanRaise
  }

  method close {
    .disconnectObject for $!mediaProxy, $!playerProxy;
    $!mediaProxy = $!playerProxy = Nil;
    self.emit('closed');
  }

  method onMediaProxyReady {
    my $s = self;

    $!mediaProxy.notify('g-name-owner').tap( -> *@a {
      $s.close if $s.mediaProxy.g-name-owner
    });
    $s.close if $s.mediaProxy.g-name-owner
  }

  method onPlayerReady {
    my $s = self;
    $!playerProxy.g-properties-changed.tap( -> *@a { $s.updateState });
    $.updateState;
  }

  method updateState {
    #...FINISH!
    my %metadata = $!playerProxy.Metadata.deepmap( -> *$c is copy { $c });

    @!trackArtists = %metadata<xesam:artists>;
    if +@trackArtists.elems {
      # If invalid artist list
      $*ERR.say: "Received faulty track artists metadata from { $!busName }"
        if (@!trackArtists.all ~~ Str).not;
      @!trackArtists = 'Unknown artist'.Array;
    }

    $!trackTitle = %metadata<xesam:title>;
    if $!trackTitle !~~ Str {
      $*ERR.say: "Received faulty track title metadata from { $!busName }"
      $!trackTitle = '';
    } else {
      $!trackTitle = '';
    }

    my $!trackCoverUrl = %metadata<xesam:artUrl>;
    if $!trackCoverUrl !~~ Str {
      $*ERR.say: "Received faulty track cover metadata from { $!busName }"
      $!trackCoverUrl = '';
    } else {
      $!trackCoverUrl = '';
    }

    if $!mediaProxy.DesktopEntry -> $de {
      $!app = Shell.AppSystem.default.lookup-app("{ $de }.desktop")
    } else {
      $!app = Nil;
    }

    self.emit('changed');

    my $v = $!playerProxy.CanPlay;
    if $!visible != $v {
      self.emit( ($!visible = $v) ?? 'show' !! 'hide' );
    }
  }
}

class Gnome::Shell::UI::MediaSection
  is Gnome::Shell::UI::MessageList::Section
{
  has %!players;
  has $!proxy;

  submethod TWEAK {
    $!proxy = GIO::DBus::Proxy.new(
      GIO::DBus.Session,
      'org.freedesktop.DBus',
      '/org/freedesktop/DBus',
      -> *@a { $s.onProxyReady( |@a ) }
    );
  }

  method allowed { Main.session.isGreeter.not }

  method addPlayer ($busName) {
    return unless %!players{$busName}:exists;

    my $player = Gnome::Shell::UI::Media::Player.new($busName);

    my ($s, $m) = (self);
    my $players := %!players;

    $player.closed.tap( -> *@a { $players{$busName}:delete });
    $player.hide.tap(   -> *@a { $s.removeMessage($m) });

    $player.show.tap( -> *@a {
      $s.addMessage( $m = MM.new($player) );
    });

    %!players{$busName} = $player;
  }

  method onProxyReady {
    state @names = $!proxy.ListNamesAsync;
    state $s     = self;

    @names.map({
      $s.addPlayer($_) if .starts-with(MPRIS_PLAYER_PREFIX)
    });
    $!proxy.NameOwnerChanged.tap( -> $p, $f, @e ($n, $oo, $no) {
      onNameOwnerChanged($s, $n, $oo, $no)
    };
  }

  method onNameOwnerchanged ($s, $n, $oo, $no) {
    return unless $n.starts-with(MPRIS_PLAYER_PREFIX);

    $s.addPlayer($n) if $no && $oo.so.not;
  }
}
