use v6.c;

use Gnome::Shell::Raw::Types;

use Gnome::Shell::Misc::ParentalControlsManager;
use Gnome::Shell::Misc::Signals;
use Gnome::Shell::UI::Main;

### /home/cbwood/Projects/gnome-shell/js/ui/appFavorites.js

our %RENAMED_DESKTOP_IDS is export = (
  'baobab.desktop'                        => 'org.gnome.baobab.desktop',
  'cheese.desktop'                        => 'org.gnome.Cheese.desktop',
  'dconf-editor.desktop'                  => 'ca.desrt.dconf-editor.desktop',
  'empathy.desktop'                       => 'org.gnome.Empathy.desktop',
  'eog.desktop'                           => 'org.gnome.eog.desktop',
  'epiphany.desktop'                      => 'org.gnome.Epiphany.desktop',
  'evolution.desktop'                     => 'org.gnome.Evolution.desktop',
  'file-roller.desktop'                   => 'org.gnome.FileRoller.desktop',
  'five-or-more.desktop'                  => 'org.gnome.five-or-more.desktop',
  'four-in-a-row.desktop'                 => 'org.gnome.Four-in-a-row.desktop',
  'gcalctool.desktop'                     => 'org.gnome.Calculator.desktop',
  'geary.desktop'                         => 'org.gnome.Geary.desktop',
  'gedit.desktop'                         => 'org.gnome.gedit.desktop',
  'glchess.desktop'                       => 'org.gnome.Chess.desktop',
  'glines.desktop'                        => 'org.gnome.five-or-more.desktop',
  'gnect.desktop'                         => 'org.gnome.Four-in-a-row.desktop',
  'gnibbles.desktop'                      => 'org.gnome.Nibbles.desktop',
  'gnobots2.desktop'                      => 'org.gnome.Robots.desktop',
  'gnome-boxes.desktop'                   => 'org.gnome.Boxes.desktop',
  'gnome-calculator.desktop'              => 'org.gnome.Calculator.desktop',
  'gnome-chess.desktop'                   => 'org.gnome.Chess.desktop',
  'gnome-clocks.desktop'                  => 'org.gnome.clocks.desktop',
  'gnome-contacts.desktop'                => 'org.gnome.Contacts.desktop',
  'gnome-documents.desktop'               => 'org.gnome.Documents.desktop',
  'gnome-font-viewer.desktop'             => 'org.gnome.font-viewer.desktop',
  'gnome-klotski.desktop'                 => 'org.gnome.Klotski.desktop',
  'gnome-nibbles.desktop'                 => 'org.gnome.Nibbles.desktop',
  'gnome-mahjongg.desktop'                => 'org.gnome.Mahjongg.desktop',
  'gnome-mines.desktop'                   => 'org.gnome.Mines.desktop',
  'gnome-music.desktop'                   => 'org.gnome.Music.desktop',
  'gnome-photos.desktop'                  => 'org.gnome.Photos.desktop',
  'gnome-robots.desktop'                  => 'org.gnome.Robots.desktop',
  'gnome-screenshot.desktop'              => 'org.gnome.Screenshot.desktop',
  'gnome-software.desktop'                => 'org.gnome.Software.desktop',
  'gnome-terminal.desktop'                => 'org.gnome.Terminal.desktop',
  'gnome-tetravex.desktop'                => 'org.gnome.Tetravex.desktop',
  'gnome-tweaks.desktop'                  => 'org.gnome.tweaks.desktop',
  'gnome-weather.desktop'                 => 'org.gnome.Weather.desktop',
  'gnomine.desktop'                       => 'org.gnome.Mines.desktop',
  'gnotravex.desktop'                     => 'org.gnome.Tetravex.desktop',
  'gnotski.desktop'                       => 'org.gnome.Klotski.desktop',
  'gtali.desktop'                         => 'org.gnome.Tali.desktop',
  'iagno.desktop'                         => 'org.gnome.Reversi.desktop',
  'nautilus.desktop'                      => 'org.gnome.Nautilus.desktop',
  'org.gnome.gnome-2048.desktop'          => 'org.gnome.TwentyFortyEight.desktop',
  'org.gnome.taquin.desktop'              => 'org.gnome.Taquin.desktop',
  'org.gnome.Weather.Application.desktop' => 'org.gnome.Weather.desktop',
  'polari.desktop'                        => 'org.gnome.Polari.desktop',
  'seahorse.desktop'                      => 'org.gnome.seahorse.Application.desktop',
  'shotwell.desktop'                      => 'org.gnome.Shotwell.desktop',
  'simple-scan.desktop'                   => 'org.gnome.SimpleScan.desktop',
  'tali.desktop'                          => 'org.gnome.Tali.desktop',
  'totem.desktop'                         => 'org.gnome.Totem.desktop',
  'evince.desktop'                        => 'org.gnome.Evince.desktop',
);

class Gnome::Shell::UI::AppFavorites
  is Gnome::Shell::Misc::Signals::EventEmitter
{
  has ParentalControlsManager $!parentalControlsManager;
  has Str                     $!FAVORITE_APPS_KEY;

  has %!favorites;

  submethod BUILD {
    $!parentalControlsManager = PCM.get-default;

    my $s = self;
    $!parentalControlsManager.app-filter-changed.tap( -> *@a {
      $s.reload;
      $s.emit('changed');
    })

    $!FAVORITE_APPS_KEY = 'favorite-apps';
    UI<Global>.settings.changed($!FAVORITE_APPS_KEY).tap( -> *@a {
      $s.onFavsChanged()
    });
  }

  method onFavsChanged {
    $s.reload;
    $s.emit('changed');
  }

  method reload {
    my $ids     = UI<Global>.settings{$FAVORITE_APPS_KEY};
    my $appSys  = UI<Shell>.AppSystem.get-default;
    my $updated = False;

    $ids .= map({
      my $newId = %RENAMED_DESKTOP_IDS{$_};
      do if $newId && $appSys.lookup-app($newId) {
        $updated = True;
        $newId;
      } else {
        $id
      }
    });

    UI<Global>settings{$FAVORITE_APP_KEY} = $ids if $updated;

    my $apps = $ids.map({
      $appSys.lookup-app($_)
    }).grep({ $_ && $!parentalControlsManager.shoudShowApp( .app_info ) })

    $!favorites = %{};
    $!favorites{ .id } = $_ for $apps[];
  }

  method getIds {
    $!favorites.map( *.id ).List;
  }

  method getFavoritesMap {
    $!favorites.Map;
  }

  method getFavorites {
    $!favorites.pairs.map( *.value ).List;
  }

  method isFavorite ($appId) {
    $!favorites{$appId}:exists;
  }

  multi method addFavorite ($appId) {
    samewith($appId, -1);
  }
  method !addFavorite ($appId, $pos) {
    return False if self.isFavorite($appId);

    my $app = UI<Shell>.AppSystem.get-default.lookup-app($appId);

    return False unless $app;
    return False unless $!parentalControlsManager.shouldShowApp($app.app-info);

    my $ids = self.getIds;
    $pos == -1 ?? $ids.push($appId) !! $ids.splice($pos, 0, $appId);
    UI<Global>settings{$!FAVORITE_APPS_KEY} = $ids;

    True;
  }

  method addFavoriteAtPos ($appId, $pos) {
    return unless self!addFavorite($appId, $pos);

    my $app = UI<Shell>.AppSystem.get-default.lookup-app($appId);

    my $msg = "{ $app.name } has been pinned to the dash.";

    UI<Main>.overview.setMessage(
      $msg,
      forfeedback  => True,
      undoCallback =>  -> *@a { self.removeFavorite($appId) }
    );
  }

  method !removeFavorite ($appId) {
    return False unless $!favorites{$appId}:exists;

    UI<Global>settings{$!FAVORITE_APPS_KEY} = self.getIds.grep( * ne $appId );
    True;
  }

  method removeFavorite ($appId) {
    my $ids = self.getIds;
    my $pos = $ids.first( $appId, :k );
    my $app = $!favorites{$appId};

    return False unless self!removeFavorite($appId);

    my $msg = "{ $app.name } has been unpinned from the dash.";

    UI<Main>.overview.setMessage(
      $msg,
      forfeedback  => True,
      undoCallback =>  -> *@a { self!addFavorite($appId, $pos) }
    );
  }

}


sub getAppFavorites is export {
  state $appFavoritesInstance = Gnome::Shell::UI::AppFavorites.new;
  $appFavoritesInstance;
}
