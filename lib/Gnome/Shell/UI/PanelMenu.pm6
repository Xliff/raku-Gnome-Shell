use v6.c;

use Mutter::Raw::Types;

use Mutter::Raw::Clutter::Keysyms;
use Gnome::Shell::Raw::Types;

use Gnome::Shell::St::BoxLayout;
use Gnome::Shell::St::Widget;
use Gnome::Shell::UI::Global;
use Gnome::Shell::UI::Main;

use GLib::Roles::Object;

### /home/cbwood/Projects/gnome-shell/js/ui/panelMenu.js

class Gnome::Shell::UI::ButtonBox is Gnome::Shell::St::Widget {
  has $!minHPadding;
  has $!natHPadding;
  has $!container;
  #has $!delegate;

  submethod TWEAK {
    (.style-class, .x-expand, .y-expand) = ('panel-button', True, True);

    #$!delegate = self;
    $!container = Gnome::Shell::St::Bin.new( child => self );

    my $self = self;
    self.style-changed.tap( -> *@a {
      self.onStyleChanged( Mutter::Clutter::Actor.new( @a[1] ) );
    });
    self.destroy.tap( -> *@a {
      self.onDestroy;
    });

    $!minHPadding = $!natHPadding = 0;
  }

  method onStyleChanged ($a) {
    my $n = $a.get-first-child;

    $!minHPadding = $n.get-length('-minimum-hpadding');
    $!natHPadding = $n.get-length('-natural-hpadding');
  }

  method get_preferred_width ($fh) is vfunc {
    my $child = self.get-first-child;

    my ($ms, $ns) = $child ?? $child.get-preferred-width(-1)
                           !! 0 xx 2;

    ($ms, $ns) «+» ($!minHPadding, $!natHPadding) »*» 2;
  }

  method get_preferred_height ($fw) is vfunc {
    if self.get-first-child -> $c {
      return $c.get_preferred_height(-1);
    }

    (0, 0);
  }

  method allocate ($box) {
    self.set-allocation($box);

    if self.get-first-child -> $c {
      my $nw = $c.get_preferred_width(-1).tail;

      my ($aw, $ah) = ($box.width, $box.height);

      given ( my $cb = Mutter::Clutter::ActorBox.new() ) {
        (.x1, .x2) = $nw + 2 * $!natHPadding <= $aw
            ?? ($!natHPadding, $aw - $!natHPadding)
            !! ($!minHPadding, $aw - $!minHPadding);

        (.y1, .y2) = (0, $ah);
      }

      $c.allocate($cb);
    }
  }

  method !onDestroy {
    self.container.child = Nil;
    self.container.destroy
  }
}

class Gnome::Shell::UI::PanelMenu::Button
  is Gnome::Shell::UI::ButtonBox
{

  method menu-set is signal { }

  submethod TWEAK (
    :$menuAlignment,
    :$nameText,
    :$dontCreateMenu
  ) {
    self.setAttributes(
      reactive        => True,
      can-focus       => True,
      track-hover     => True,
      accessible-name => $nameText,
      accessible-role => ATK_ROLE_MENU
    );

    # cw: Not written yet!
    #constant PM = Gnome::Shell::UI::PopupMenu;
    constant PM = Mu;

    self.menu = $dontCreateMenu
       ?? Gnome::Shell::UI::PopupMenu::Dummy.new
       !! PM.new(self, $menuAlignment, ST_SIDE_TOP);

    self.key-press-event.tap( -> *@a {
      my $e = Mutter::Clutter::Event.new( @a[1] );
      Global.FocusManager.navigate-from-event($e);
    });
  }

  # cw: in methods, "self" can be spelled like '$'
  method setSentitive ($s){
    $.reactive = $.can-focus = $.track-hover = $s;
  }

  method setMenu ($m) {
    $.menu.destroy if $.menu;

    $.menu = $m;
    if $.menu {
      $.menu.actor.add-style-class-name('panel-menu');

      my $s = self;
      $.menu.open-state-changed.tap( -> *@a {
        $s.openStateChanged( @a[1] );
      });
      $.menu.actor.key-press-event( -> *@a {
        @a.tail.r = $s.onMenuKeyPress( |@a );
      });
      Main.uiGroup.add-action($.menu.actor);
      $.menu.actor.hide;
      $.emit('menu-set');
    }

    method event ($e) is vfunc {
      $e = Mutter::Clutter::Event.new($e)
        unless $e ~~ Mutter::Clutter::Event;

      $.menu.toggle if $.menu && $e.type == (
         CLUTTER_TOUCH_BEGIN,
         CLUTTER_BUTTON_PRESS
      ).any;

      CLUTTER_EVENT_PROPAGATE;
    }

    method hide is vfunc {
      nextsame;
       $.menu.close if $.menu
    }
  }

  method onMenuKeyPress ($a, $e) {
    my $ev = Mutter::Clutter::Event.new($e);

    return CLUTTER_EVENT_STOP
      if Global.FocusManager.navigate-from-event($ev);

    my $sym = $ev.get-key-symbol;
    if $sym == (MUTTER_CLUTTER_KEY_Left, MUTTER_CLUTTER_KEY_Right).any {
      if Global.FocusManager.get-group(self) -> $g {
        my $d = ($sym == MUTTER_CLUTTER_KEY_Left ?? ST_DIR_LEFT
                                                 !! ST_DIR_RIGHT);
        $g.navigate0focus(self, $d);
        return CLUTTER_EVENT_STOP
      }
    }
    CLUTTER_EVENT_PROPAGATE
  }

  # cw: Called via invocant so use of self is allowed.
  method onOpenStateChanged ($o) {
    $o ?? $.add-style-pseudo-class('active')
       !! $.remove-style-pseudo-class('active');

    my $wa = Main.LayoutManager.getWorkAreaForMonitor(
      Main.LayoutManager.primaryIndex
    );
    my $sf = Gnome::Shell::St::ThemeContext.get-for-stage(
      Global.stage
    ).scale-factor;
    my $vm = $.menu.actor.margin-top + $.menu.actor.margin-bottom;

    my $mh = ($wa.height - $vm) / $sf;
    $.menu.actor.style = "max-height: { $mh }px;";
  }

  method onDestroy {
    $.menu.destroy if $.menu;
    nextsame;
  }
}

class Gnome::Shell::UI::SystemIndicator is Gnome::Shell::St::BoxLayout {
  submethod TWEAK {
    self.setAttributes(
      style-class => 'panel-status-indicators-box',
      reactive    => True,
      visible     => False
    );
    self.menu = Gnome::Shell::UI::PopupMenu::Section.new;
  }

  method syncIndicatorsVisible {
    $.visible = $.children.grep( *.visible ).elems.so;
  }

  method addIndicator {
    my $i = Gnome::Shell::St::Icon.new(
      style-class => 'system-status-icon'
    );
    $.add-actor($i);

    my $s = self;
    $i.notify('visible').tap( -> *@a {
      $s.syncIndicatorsVisible;
    });
    $.syncIndicatorsVisible;
    $i;
  }
}
