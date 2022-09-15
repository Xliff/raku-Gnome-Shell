use v6;

use GIO::Settings;
use Gnome::Shell::UI::Ripples;
use Gnome::Shell::UI::Main;

constant LOCATE_POINTER_KEY    is export = 'locate-pointer';
constant LOCATE_POINTER_SCHEMA is export = 'org.gnome.desktop.interface';

class Gnome::Shell::UI::LocatePointer {
  has $!settings;
  has $!ripples;

  submethod BUILD {
    $!settings = GIO::Settings;
    $!settings.schema-id = LOCATE_POINTER_SCHEMA;
    $!settings.changed(LOCATE_POINTER_KEY).tap(-> *@a {
      self.syncEnabled;
    })
  }

  method syncEnabled {
    my $enabled = $!settings.get-boolean(LOCATE_POINTER_KEY);

    return unless $!ripples;

    if $enabled {
      $!ripples = Ripples.new(0.5, 0.5, 'ripples-pointer-location');
      $!ripples.addTo( UI<uiGroup> );
    } else {
      $!ripples.destroy;
      $!ripples = Nil;
    }
  }

  method show {
    return unless $!ripples;

    $!ripples.playAnimation( |global.get-pointer );
  }
  
}
