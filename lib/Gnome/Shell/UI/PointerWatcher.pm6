use v6.c;

use Gnome::Shell::Raw::Types;

use GLib::Source;
use GLib::Timeout;

use Gnome::Shell::UI::Global;

### /home/cbwood/Projects/gnome-shell/js/ui/pointerWatcher.js

constant IDLE_TIME = 1000;

my $pointerWatcher;

sub getPointerWatcher is export {
  $pointerWatcher = Gnome::Shell::UI::PointerWatcher.new
    unless $pointerWatcher;
  $pointerWatcher;
}

class Gnome::Shell::UI::PointerWatch {
  has $!watcher  is built;
  has $!interval is built;
  has &!callback is built;

  method remove {
    $!watcher.removeWatch(self);
  }
}

class Gnome::Shell::UI::PointerWatcher {
  has $!idleMonitor;
  has $!idle;
  has $.pointerX;
  has $.pointerY;
  has @!watches;
  has $!timeoutId;

  submethod TWEAK {
    $!idleMonitor = Global.backend.get-core-idle-monitor;

    my $s = self;
    $!idleMonitor.add-idle-watch(IDLE_TIME, -> *@a {
      self.onIdleMonitorBecameIdle
    });
    $!idle = $!idleMonitor.get-idletime > IDLE_TIME;
  }

  method addWatch ($interval, &callback) {
    self!updatePointer;

    my $watch = Gnome::Shell::UI::PointerWatch.new(
      self,
      $interval,
      &callback
    );
    @!watches.push: $watch;
    self!updateTimeout;
    $watch;
  }

  method !removeWatch ($watch) {
    @!watches .= grep( *.WHERE !== $watch.WHERE );
    self!updateTimeout;
  }

  method onIdleMonitorBecameActive {
    $!idle = False;
    self!updatePointer;
    self!updateTimeout;
  }

  method onIdleMonitorBecameIdle {
    $!idle = True;

    my $s = self;
    $!idleMonitor.add-user-active-watch(-> *@a {
      $s.onIdleMOnitorBecameActive
    });
    self!updateTimeout;
  }

  method !updateTimeout {
    GLib::Source.remove($!timeoutId) if $!timeoutId;
    $!timeoutId = 0;

    return if $!idle || @!watches.elems.not;

    my $minInterval = @!watches.map( *.interval ).min;

    my $s = self;
    $!timeoutId = GLib::Timeout.add(
      $minInterval,
      -> *@a { $s.onTimeout },
      name => 'Gnome::Shell::PointerWatcher.onTimeout'
    );
  }

  method  onTimeout {
    self!updatePointer;
    G_SOURCE_CONTINUE;
  }

  method !updatePointer {
    my ($x, $y) = Global.get-pointer;
    return if $!pointerX == $x && $!pointerY == $y;

    ($!pointerX, $!pointerY) = ($x, $y);

    # cw: Not using iterator, but is the original code
    #     a proper guard against self-removal or an
    #     endless loop?
    .callback.($x, $y) for @!watches;
  }
}
