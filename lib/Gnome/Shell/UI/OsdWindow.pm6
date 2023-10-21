use v6.c;

use Gnome::Shell::Raw::Types;

use Gnome::Shell::UI::BarLevel;
#use Gnome::Shell::UI::Layout;
use Gnome::Shell::UI::Main;

constant HIDE_TIMEOUT         is export = 1500;
constant FADE_TIME            is export = 100;
constant LEVEL_ANIMATION_TIME is export = 100;

### /home/cbwood/Projects/gnome-shell/js/ui/osdWindow.js

class Gnome::Shell::UI::OsdWindow is Mutter::Clutter::Actor {

  has $!monitorIndex is built;

  has $!hbox;
  has $!icon;
  has $!vbox;
  has $!label;
  has $!level;
  has $!hideTimeoutId;

  # method icon is rw {
  #   Proxy.new:
  #     FETCH => -> $ { $!icon },
  #     STORE => -> $, \v {
  #       setIcon($!icon, $v);
  #     }
  # }
  #
  # method setIcon ($icon) {
  #   $!icon.gicon := $icon;
  # }

  submethod BUILD ( :$!monitorIndex ) {
    .x-expand = .y-expand = True given self;
    self.x-align = CLUTTER_ACTOR_ALIGN_CENTER;
    self.y-align = CLUTTER_ACTOR_ALIGN_END;

    self.add-constraint(
      Gnome::Shell::UI::Layout::MonitorConstraint(
        index => $monitorIndex
      )
    );

    $!hbox = Gnome::Shell::St::BoxLayout(
      style-class => 'osd-window'
    );
    $!hbox.add-child(
      $!icon = Gnome::Shell::St::Icon( y-expand => True )
    );
    $!hbox.add-child(
      $!vbox = Gnome::Shell::St::BoxLayout(
        vertical => True,
        y-align  => CLUTTER_ACTOR_ALIGN_CENTER
      )
    );
    $!label = Gnome::Shell::St::Label;
    $!level = Gnome::Shell::UI::BarLevel.new(
      style-class => 'level',
      value       => 0
    );
    $!vbox.add-child($_) for $!label, $!level;

    $!hideTimeoutId = 0;
    self.reset;
    UI<uiGroup>.add-child(self);
  }

  method updateBoxVisibility {
    # cw: I hope this is a faithful conversion of the following:
    # this._vbox.visible = [...this._vbox].some(c => c.visible);
    $!vbox.visible = $!vbox.get-children.map( *.visible ).any;
  }

  method setLabel ($label) {
    $!label.visible = ( my $newLabelVisible = $label.defined && $label.chars );
    $!label.text = $label if $newLabelVisible;
    self.updateBoxVisibility;
  }

  method setLevel ($value) {
    $!level.visible = (my $newLevelVisible = $value.defined);
    if self.visible {
      $!level.ease-property(
        'value',
        $value,
        mode     => CLUTTER_EASE_OUT_QUAD.
        duration => LEVEL_ANIMATION_TIME
      );
    } else {
      $!level.value = $value;
    }
    self.updateBoxVisibility;
  }

  method setMaxLevel ($max = 1) {
    $!level.maximum-value = $max;
  }

  method show {
    return unless $!icon.gicon;

    global.display.disble-unredirect-for-display unless self.visible;
    callsame;
    self.opacity = 0;
    self.get-parent.set-child-above-sibling(self);

    self.ease(
      opacity  => 255,
      duration => FADE_TIME,
      mode     => CLUTTER_EASE_OUT_QUAD
    );

    GLib::Source.remove($!hideTimeoutId) if $!hideTimeoutId;
    $!hideTimeoutId = GLib::Timeout.add(HIDE_TIMEOUT, -> *@a { self.hide });
    GLib::Source.set-name-by-id(
      $!hideTimeoutId,
      '[gnome-shell-raku] OSDWindow.hide'
    );
  }

  method cancel {
    return unless $!hideTimeoutId;
    GLib::Source.remove($!hideTimeoutId);
    self.hide;
  }

  method hide {
    $!hideTimeoutId = 0;
    self.ease(
      opacity    => 0,
      duration   => FADE_TIME,
      mode       => CLUTTER_EASE_OUT_QUAD
      onComplete => -> *@a {
        self.reset;
        global.display.enable-unredirect-for-display;
      }
    );
    GLIB_SOURCE_REMOVE;
  }

  method reset {
    self.Mutter::Clutter::Actor::hide();
    self."set{ $_ }"(Nil) for <Label MaxLevel Level>;
  }

}

class Gnome::Shell::UI::OsdWindow::Manager {
  has @!osdWindows;

  submethod BUILD {
    UI<layoutManger>.monitors-changed.tap( -> *@a {
      self.monitorsChanged( |@a );
    });
  }

  method monitorsChanged (*@a) {
    my $mainWinMonitors = UI<layoutManager>.monitors.elems;
    $!osdWindows[$_] //= Gnome::Shell::UI::OSDMonitor.new($_)
      for ^$mainWinMonitorsLength;

    for $mainWinMonitorsLength .. @!osdWindows.elems -> $w {
      @!osdWindows[$w].destroy;
      $!osdWindows[$w]:delete;
    }
  }

  method showOsdWindow ($monitorIndex, $icon, $label, $level, $maxLevel) {
    given @!osdWindows[$monitorIndex] {
        .setIcon($icon); .setLabel($label); .setMaxLevel($maxLevel);
      .setLevel($level); .show
    }
  }

  method show ($monitorIndex, $icon, $label, $level, $maxLevel) {
    unless $monitorIndex == -1 {
      for @!osdWindows.kv -> $k, $m {
        if $k == $monitorIndex {
          self.showOsdWindow($k, $icon, $label, $level, $maxLevel);
        } else {
          $m.cancel;
        }
      }
    } else {
      .show for @!osdWindows;
    }
  }

  method hideAll {
    .cancel for @!osdWindows;
  }

}



    }
  }


}
