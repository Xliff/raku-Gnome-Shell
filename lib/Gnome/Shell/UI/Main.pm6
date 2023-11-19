use v6.c;

my %S;

#use Gnome::Shell::Misc::Introspect;
use Gnome::Shell::UI::AccessDialog;
use Gnome::Shell::UI::AudioDeviceSelection;
#use Gnome::Shell::UI::Components;
#use Gnome::Shell::UI::Config;
use Gnome::Shell::UI::CtrlAltTab;
#use Gnome::Shell::UI::EndSessionDialog;
use Gnome::Shell::UI::ExtensionDownloader;
#use Gnome::Shell::UI::ExtensionSystem;
#use Gnome::Shell::UI::Introspect;
#use Gnome::Shell::UI::InputMethod;
use Gnome::Shell::UI::KbdA11yDialog;
#use Gnome::Shell::UI::Keyboard;
#use Gnome::Shell::UI::Layout;
#use Gnome::Shell::UI::LoginManager;
#use Gnome::Shell::UI::LocatePointer;
use Gnome::Shell::UI::LookingGlass;
#use Gnome::Shell::UI::Mangnifier;
#use Gnome::Shell::UI::MessageTray;
use Gnome::Shell::UI::ModalDialog;
use Gnome::Shell::UI::MountOperation;
#use Gnome::Shell::UI::NotificationDaemon;
use Gnome::Shell::UI::Osd;
use Gnome::Shell::UI::OsdWindow;
#use Gnome::Shell::UI::Overview;
#use Gnome::Shell::UI::PadOsd;
#use Gnome::Shell::UI::Panel;
#use Gnome::Shell::UI::Params;
#use Gnome::Shell::UI::ParentalControlsManager;
use Gnome::Shell::UI::PonterA11yTimeout;
#use Gnome::Shell::UI::RunDialog;
#use Gnome::Shell::UI::ScreenShield;
#use Gnome::Shell::UI::Screenshot;
use Gnome::Shell::UI::SessionMode;
#use Gnome::Shell::UI::ShellDBus;
#use Gnome::Shell::UI::Util;
use Gnome::Shell::UI::WelcomeDialog;
use Gnome::Shell::UI::WindowAttentionHandler;
#use Gnome::Shell::UI::WindowManager;
use Gnome::Shell::UI::XdndHandler;

constant WELCOME_DIALOG_LAST_SHOWN_VERSION is export = 'welcome-dialog-last-shown-version';
constant WELCOME_DIALOG_LAST_TOUR_CHANGE   is export = '40.beta';
constant LOG_DOMAIN                        is export = 'GNOME Shell';
constant GNOMESHELL_STARTED_MESSAGE_ID     is export = 'f3ea493c22934e26811cd62abe8e203a';

class Gnome::Shell::UI::Main::AnimationSettings { ... }

class Gnome::Shell::UI::Main does Associative {
  has $.startDate;
  has $.defaultCssStylesheet;
  has $.cssStylesheet;
  has $.themeResource;
  has $.oskResource;
  has $.iconResource;
  has $.workspacesAdjustment;
  has $.workspaceAdjustmentRegistry;
  has $.remoteAccessInhibited         = False;

  has %!S;

  method InitModules ( @m ) {
    %!S{ $_ ~~ Pair ?? .key !! .^shortname } = .value.new for @m;
  }

  method initializeUI {
    # We initialize WindowTracker and AppUsage.
    $ = Gnome::Shell::WindowTracker.get-default;
    $ = Gnome::Shell::AppUsage.get-default;

    $.reloadThemeResource;
    $.loadIcons;
    $.loadOskLayouts;
    $.loadDefaultStylesheet;
    $.loadWorkspacesAdjustments;

    $ = Gnome::Shell::UI::Main::AnimationSettings.new;

    # cw: Theres more stuff before this! DO THAT!
    $.InitModules([
      LayoutManager           => Gnome::Shell::UI::Layout::Manager,

      #PadOsdService           => Gnome::Shell::UI::PadOsd,
      XdndHandler             => Gnome::Shell::UI::XDndHandler,
      CtrlAltTabManager       => Gnome::Shell::UI::CtrlAltTab::Manager,
      OsdWindowManager        => Gnome::Shell::UI::OsdWindow::Manager,
      OsdMonitorLabeler       => Gnome::Shell::UI::Osd::Monitor::Labeler,
      Overview,
      KbdA11yDialog           => Gnome::Shell::UI::KbdA11yDialog,
      WindowManager,
      Mangnifier,
      LocatePointer           => Gnome::Shell::UI::LocatePointer,
    ]);

    %S<ScreenShield> = ScreenShield.new
      if Gnome::Shell::UI::LoginManager.canLock;

    $.InitModules( <InputMethod> );

    # cw: Figure out what this is.
    my $db = Mutter::Clutter::Backend.get-default-backend();
    $db.set-input-method( %S<InputMethod> );

    Global.shutdown.tap( SUB { $db.clearInputMethod });

    $.InitModules(<
      Screenshot,
      MessageTray,
      Panel,
      KeyboardManager,
      NotificationDaemon,
      WindowAttentionHandler,
      ComponentManager,
      PonterA11yTimeout,
      IntrospectService
    >);

    %S<wm>      = %S<Wm>      = %S<WindowManager>;
    %S<UiGroup> = %S<UIGroup> = %S<LayoutManager>.UiGroup;

    # Various parts of the codebase still refer to Main.uiGroup
    # instead of using the layoutManager. This keeps that code
    # working until it's updated.
    %S<uiGroup> := %S<LayoutManager>.uiGroup;


    .init for %S<LayoutManager Overview>;

    # cw: There's more stuff after this, so DO THAT TOO!

    # cw: This should be last!
    %S{ .&lcfirst } = %S{$_} for %S.keys;
  }

  method AT-KEY (\k) {
    %S{k}
  }

  method FALLBACK (\name) {
    do if %S{name} -> $v {
      $v;
    } else {
      warn "Method { name } not found on UI!";
    }
  }

}

constant Ui   is export = Gnome::Shell::Main::UI;
constant Main is export = Ui;

sub AccessDialog            is export { Ui.AccessDialog };
sub AudioDeviceSelection    is export { Ui.AudioDeviceSelection };
sub Components              is export { Ui.Components };
sub Config                  is export { Ui.Config };
sub CtrlAltTab              is export { Ui.CtrlAltTab };
sub EndSessionDialog        is export { Ui.EndSessionDialog };
sub ExtensionDownloader     is export { Ui.ExtensionDownloader };
sub ExtensionSystem         is export { Ui.ExtensionSystem };
sub Introspect              is export { Ui.Introspect };
sub InputMethod             is export { Ui.InputMethod };
sub KbdA11yDialog           is export { Ui.KbdA11yDialog };
sub Keyboard                is export { Ui.Keyboard };
sub Layout                  is export { Ui.Layout };
sub LoginManager            is export { Ui.LoginManager };
sub LocatePointer           is export { Ui.LocatePointer };
sub LookingGlass            is export { Ui.LookingGlass };
sub Mangnifier              is export { Ui.Mangnifier };
sub MessageTray             is export { Ui.MessageTray };
sub ModalDialog             is export { Ui.ModalDialog };
sub NotificationDaemon      is export { Ui.NotificationDaemon };
sub OsdMonitorLabeler       is export { Ui.OsdMonitorLabeler };
sub OsdWindow               is export { Ui.OsdWindow };
sub Overview                is export { Ui.Overview };
sub PadOsd                  is export { Ui.PadOsd };
sub Panel                   is export { Ui.Panel };
sub Params                  is export { Ui.Params };
sub ParentalControlsManager is export { Ui.ParentalControlsManager };
sub PonterA11yTimeout       is export { Ui.PonterA11yTimeout };
sub RunDialog               is export { Ui.RunDialog };
sub ScreenShield            is export { Ui.ScreenShield };
sub Screenshot              is export { Ui.Screenshot };
sub SessionMode             is export { Ui.SessionMode };
sub ShellDBus               is export { Ui.ShellDBus };
sub ShellMountOperation     is export { Ui.ShellMountOperation };
sub Util                    is export { Ui.Util };
sub WelcomeDialog           is export { Ui.WelcomeDialog };
sub WindowAttentionHandler  is export { Ui.WindowAttentionHandler };
sub WindowManager           is export { Ui.WindowManager };
sub XdndHandler             is export { Ui.XdndHandler };

constant UI is export := Gnome::Shell::Main::UI;
