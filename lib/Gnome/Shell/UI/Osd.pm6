use v6.c;

use GIO::DBus::Utils;
use Gnome::Shell::St::Widget
use Gnome::Shell::St::BoxLayout;
use Gnome::Shell::St::Label;
use Gnome::Shell::UI::Main;

class Gnome::Shell::UI::OSD::MonitorLabel is Gnome::Shell::St::Widget {
  has $!monitor is built;
  has $!label;
  has $!box;

  submethod BUILD ( :$!monitor, :$label ) {
    self.x-expand = self.y-expand = True;

    $!box = Gnome::Shell::St::BoxLayout.new(
      vertical => True
    );
    self.add-actor($box);

    $!label = Gnome::Shell::St::Label.new(
      style-class => 'osd-monitor-label',
      text        => $label
    );
    $!box.add($!label);
    UI<uiGroup>.add(self);
    UI<uiGroup>.set-child-above-sibling(self);
    self.position;
    Meta.disable-unredirect-for-display(global.display);
    self.destroy.tap(-> *@a {
      Meta.enable-unredirect-for-display(global.display);
    });
  }

  method position {
    my $workArea = UI<layoutManager>.getWorkAreaForMonitor($!monitor);
    if
      Mutter::Clutter.get-default-text-direction == CLUTTER_TEXT_DIRECTION_RTL
    {
      $!box.x = $workArea.x + ($workArea.width - $!box.width);
    } else {
      $!box.x = $workArea.x;
    }

    $!box.y = $workArea.y;
  }

}

class Gnome::Shell::UI::OSD::MonitorLabeler {
  has $!monitorManager;
  has $!client;
  has $!clientWatchId;
  has @!osdLabels;
  has $!monitorLabels;

  submethod BUILD {
    $!monitorManager = Meta::MonitorManager.get;
    $!clientWatchId  = 0;

    UI<layoutManager>.monitors-changed.tap( -> *@a { self.reset });
  }

  method reset {
    .destroy for @!osdLabels;
    @osdLabels = ();
    $!monitorLabels{ .index } = [] for UI<layoutManager>.monitors;
  }

  method trackClient ($client) {
    return $!client == $client if $!client;

    $!client = $client;
    $!clientWatchId = GIO::DBus::Utils.watch_name(
      G_BUS_TYPE_SESSION,
      $client,
      name-vanished-handler => -> *@a ($, $name) {
        self.hide($name)
      }
    );

    True
  );

  method untrackClient ($client) {
    return False if $!client || $!client != $client;

    GIO::DBus::Utils.unwatch_name($!clientWatchId);
    ($!clientWatchId, $!client) = (0, Nil);
    True;
  }

  method show ($client, *%params) {
    return unless self.trackClient($client);
    self.reset;
    for %params.pairs {
      my $monitor = $!monitorManager.get-monitor-for-connector( .key );
      next if $monitor == -1;
      $!monitorLabels.get($monitor).push( .value.deepUnpack );
    }

    for $!monitorLabels.entries.pairs {
      .values .= sort;
      $!osdLabels.push:
        Gnome::Shell::OSD::MonitorLabel.new( .key, .value.join(' ') );
    }
  }

  method hide ($client) {
    return unless self.untrackClient($client);
    self.reset;
  }

}
