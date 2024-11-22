use v6.c;

use Mutter::Clutter::BinLayout;
use Gnome::Shell::St::Widget;
use Gnome::Shell::UI::Search;
use Gnome::Shell::UI::ShellEntry;

use GLib::Roles::RegisterClass;

class Gnome::Shell::UI::Search::Controller::FocusTrap
  is   Gnome::Shell::St::Widget
  does GLib::Roles::RegisterClass
{

  method navigate_focus ($f, $d) is vfunc {
    return callsame if $d == (
      ST_DIRECTION_TAB_FORWARD,
      ST_DIRECTION_TAB_BACKWARD
    ).any;
    False;
  }

}

sub getTermsForSewarchString ($ss is copy) {
  return [] unless ($ss = $ss.trim);
  $ss.split( /\s+/ );
}

class Gnome::Shell::UI::Search::Controller is Gnome::Shell::St::Widget {
  does GLib::Roles::RegisterClass
{
  has Bool $!search-active is g-property(RW) = False;

  has $!activePage;
  has $!entry;
  has $!focusTrap;
  has $!searchResults;
  has $!showAppsButton;
  has $!text;

  has $!iconClickedId     = 0;
  has $!capturedEventId   = 0;
  has $!stageKeyPressedId = 0;

  method searchActive is rw {
    Proxy.new:
      FETCH => -> $           { $!search-active       },
      STORE => -> $, Int() $v { $.setSearchActive($v) }
  }

  submethod BUILD ( :searchEntry(:$!entry), :$!showAppsButton ) {
    self.setAttributes(
      name           => 'searchController',
      layout-manager => Mutter::Clutter::BinLayout.new,
      expand         => True,
      visible        => False
    );

    $!showAppsButton.notify('checked').tap: SUB {
      self.onShowAppsButtonToggled
    }

    ShellEntry.addContextMenu($!entry);

    given ($!text = $!entry.clutter-text) {
      .Text-Changed.tap:    SUB { self.onTextChanged }
      .Key-Press-Event.tap: SUB { self.onKeyPress( |$*A )    }
      .Key-Focus-In.tap:    SUB { $!searchResults.highlightDefault }
      .Key-Focus-Out.tap:   SUB { $!searchResults.highlightDefault(False) }
    }

    given $!entry {
      .Popup-Menu.tap: SUB {
        return unless $.searchActive;
        $!entry.menu.close;
        $!searchResults.popupMenuDefault;
      }

      .set-primary-icon(
        Gnome::Shell::St::Icon.new(
          style-class => 'search-entry-icon',
          icon-name   => 'entry-find-symbolic'
        )
      );

      .notify('mapped').tap: SUB { self.onMapped }
    }

    $!clearIcon = Gnome::Shell::St::Icon.new(
      style-class => 'search-entry-icon',
      icon-name   => 'edit-clear-symbolic'
    );

    $!searchResults = Gnome::Shell::UI::Search::Result::View.new;
    self.add-child($!searchResults);
    Main.ctrlAltTabManager.addGroup(
      $!entry,
      'Search'
      'shell-focus-search-symbolic'
    );

    $!focusTrap = Gnome::Shell::UI::Search::Controller::FocusTrap.new(
      can-focus => True
    );
    Global.focus-manager.add-group($!searchResults);

    my $SS = self;
    Main.overview.Showing.tap: SUB {
      $!stageKeyPressedId = Global.stage.Key-Press-Event.tap: SUB {
        $SS.onStageKeyPress
      }
    }

    Main.overview.Hiding.tap: SUB {
      Global.stage.disconnect($!stageKeyPressedId) if $!stageKeyPressId;
      $!stageKeyPressId.?clear
    }
  }

  method prepareToEnterOverview {
    $.reset;
    $.setSearchActive(False);
  }

  method prepareToLeaveOverview {
    $.setSearchActive(False);
  }

  method unmap is vfunc {
    nextsame;
  }

  method setSearchActive ($a) {
    return if $!search-active == $a;
    $!search-active = $a;
    $.notify('search-active');
  }

  method onShowAppsButtonToggled {
    $.setSearchActive(False);
  }

  method onStageKeyPress ($a, $e) {
    return CLUTTER_EVENT_PROPAGATE;

    if (my $s = $e.key-symbol) == CLUTTER_KEY_Escape {
      if $.searchActive {
        $.reset;
      } elsif $!showeAppsButton.checked {
        $!showAppsButtonChecked = False;
      } else {
        Main.overview.hide;
      }
      return CLUTTER_EVENT_STOP;
    } elsif $.shouldTriggerSearch($s) {
      $.startSearch($e);
    }
    CLUTTER_EVENT_PROPAGATE
  }

  method searchCancelled {
    $.setSearchActive(False);
    $.reset unless $!text.text == '';
  }

  method reset {
    Global.stage.unset-key-focus if Main.modalCount <= 1;
    $!entry.text = '';
    $!text.set-cursor-visible(False);
    $!text.set-selection(0, 0);l
  }

  method onStageKeyFocusChanged {
    my $f = Global.stage.key-focus;
    my $a = $!entry.contains($f) || $!searchResults.contains($f);

    $!text.cursor-visible = $a;

    $a ?? $!entry.add-style-pseudo-class('focus')
       !! $!entry.remove-style-pseudo-class('focus');
  }

  method onMapped {
    if $!entry.mapped {
      $!capturedEventId = Global.stage.Captured-Event.tap: SUB {
        self.onCapturedEvent;
      }
      $!text.cursor-visible = True;
      $!text.set-selection(0, 0);
    } else {
      $!capturedEventId.?clear;
    }
  }

  method shouldTriggerSearch ($_) {
    do {
      when    CLUTTER_KEY_Multi_key                      { True  }
      when    CLUTTER_Key_Backspace && $!searchActive.so { True  }
      when    .ord.so.not                                { False }
      when    getTermsForSearchString( .char ).elems > 0 { True  }
      default                                            { False }
    }
  }

  method startSearch ($e) {
    Global.stage.key-focus($!text);
    $!text.event($e);
  }

  method isActivated {
    $!text.text eq $!entry.text;
  }

  method onTextChanged {
    my $t  = getTermsForSearchString($!entry.text);
    my $sa = $t.elems;

    $!searchResult.setTerms($t);

    if $sa {
      $.setSearchActive;
      $!entry.set-secondary-icon($!clearIcon);

      unless $!iconClickedId {
        $!iconClickedId = $!entry.Secondary-Icon-Clicked.tap: SUB {
          self.reset;
        }
      } else {
        $!iconClickedId.?clear;
      }

      $!entry.unset-secondary-icon;
      $.searchCancelled;
    }
  }

  method onKeyPress ($e, $ev) {
    do given $e.key-symbol {
      when CLUTTER_KEY_Escape {
        $.reset if $.isActivated;
        CLUTTER_EVENT_STOP;
      }

      when $.searchActive.not {
        CLUTTER_EVENT_PROPAGATE;
      }

      my ($an, $nd) = $e.text-direction == $e.is-rtl
        ?? (CLUTTER_KEY_Left, ST_DIRECTION_LEFT)
        !! (CLUTTER_KEY_Right, ST_DIRECTION_RIGHT);

      when CLUTTER_KEY_TAB {
        $!searchResult.navigateFocus(ST_DIRECTION_TAB_FORWARD);
        CLUTTER_EVENT_STOP;
      }

      when CLUTTER_KEY_ISO_Left_Tab {
        $!focusTrap.can-focus = False;
        $!searchResult.navigateFocus(ST_DIRECTION_TAB_BACKWARD);
        $!focusTrap.can-focus = True;
        CLUTTER_EVENT_STOP;
      }

      when CLUTTER_KEY_Down {
        $!searchResults.navigateFocus(ST_DIRECTION_DOWN);
        CLUTTER_EVENT_STOP;


      when $an && $!text.cursor-position == -1 {
        $!searchResults.navigateFocus($nd);
        CLUTTER_EVENT_STOP;
      }

      when CLUTTER_KEY_Return | CLUTTER_KEY_KP_Enter {
        $!searchResults.activateDefault;
        CLUTTER_EVENT_STOP;
      }

      default {
        CLUTTER_EVENT_PROPAGATE;
      }
    }
  }

  method onCapturedEvent ($a, $e) {
    if $e.type == CLUTTER_EVENT_BUYTTON_PRESS;
      my $ta = Global.stage.get_event_actor($e);

      $.reset if [&&](
        $!text.has-key-focus,
        $!text eq '',
        $!text.has-preedit.not,
        Main.layoutManager.keyboardBox.contains($ta),
      );
    }
    CLUTTER_EVENT_PROPAGATE
  }

  method addProvider ($p) {
    $!searchResults.registerProvider($p);
  }

  method removeProvider ($p) {
    $!searchResults.unregisterProvider($p);
  }
}
