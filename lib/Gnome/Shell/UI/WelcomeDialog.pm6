use v6;

use Gnome::Shell::Misc::Config;
use Gnome::Shell::UI::Dialog;
use Gnome::Shell::UI::Main;
use Gnome::Shell::UI::ModalDialog;

our enum DialogResponse = <NO_THANKS TAKE_TOUR>;

class Gnome::Shell::UI::WelcomeDialog is Gnome::Shell::UI::ModalDialog {
  has $!tourAppInfo;

  submethod BUILD {
    self.styleClass = 'welcome-dialog';

    my $appSystem = Gnome::Shell::AppSystem.get-default;
    $!tourAppInfo = $appSystem.lookup-app('org.gnome.Tour.desktop');

    self.buildLayout;
  }

  method open {
    return False unless $!tourAppInfo;
    nextsame;
  }

  method buildLayout {
    my $content = MessageDialogContent.new(
      title => "Welcome to GNOME { PACKAGE_VERSION }";
      desc  => 'If you want to learn your way around, check out the tour.'
    );

    my $icon = Gnome::Shell::St::Widget(
      style_class => 'welcome-dialog-image'
    );
    $content.insert-child-at-index($content);

    self.addButton(
      label  => 'No Thanks',
      action => -> *@a { self.sendResponse(NO_THANKS) },
      key    => CLUTTER_KEY_Escape
    );

    self.addButton(
      label  => 'Take Tour',
      action => -> *@a { self.sendResponse(TAKE_TOUR) }
    );
  }

  method sendResponse ($r) {
    if $r == TAKE_TOUR {
      $!tourAppInfo.launch;
      Gnome::Shell::Main::UI<overview>.hide;
    }

    self.close;
  }

}

constant WelcomeDialog is export := Gnome::Shell::UI::WelcomeDialog;
