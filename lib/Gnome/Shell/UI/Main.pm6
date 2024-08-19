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

our sub AccessDialog            { Ui.AccessDialog };
our sub AudioDeviceSelection    { Ui.AudioDeviceSelection };
our sub Components              { Ui.Components };
our sub Config                  { Ui.Config };
our sub CtrlAltTab              { Ui.CtrlAltTab };
our sub EndSessionDialog        { Ui.EndSessionDialog };
our sub ExtensionDownloader     { Ui.ExtensionDownloader };
our sub ExtensionSystem         { Ui.ExtensionSystem };
our sub Introspect              { Ui.Introspect };
our sub InputMethod             { Ui.InputMethod };
our sub KbdA11yDialog           { Ui.KbdA11yDialog };
our sub Keyboard                { Ui.Keyboard };
our sub Layout                  { Ui.Layout };
our sub LoginManager            { Ui.LoginManager };
our sub LocatePointer           { Ui.LocatePointer };
our sub LookingGlass            { Ui.LookingGlass };
our sub Mangnifier              { Ui.Mangnifier };
our sub MessageTray             { Ui.MessageTray };
our sub ModalDialog             { Ui.ModalDialog };
our sub NotificationDaemon      { Ui.NotificationDaemon };
our sub OsdMonitorLabeler       { Ui.OsdMonitorLabeler };
our sub OsdWindow               { Ui.OsdWindow };
our sub Overview                { Ui.Overview };
our sub PadOsd                  { Ui.PadOsd };
our sub Panel                   { Ui.Panel };
our sub Params                  { Ui.Params };
our sub ParentalControlsManager { Ui.ParentalControlsManager };
our sub PonterA11yTimeout       { Ui.PonterA11yTimeout };
our sub RunDialog               { Ui.RunDialog };
our sub ScreenShield            { Ui.ScreenShield };
our sub Screenshot              { Ui.Screenshot };
our sub SessionMode             { Ui.SessionMode };
our sub ShellDBus               { Ui.ShellDBus };
our sub ShellMountOperation     { Ui.ShellMountOperation };
our sub Util                    { Ui.Util };
our sub WelcomeDialog           { Ui.WelcomeDialog };
our sub WindowAttentionHandler  { Ui.WindowAttentionHandler };
our sub WindowManager           { Ui.WindowManager };
our sub XdndHandler             { Ui.XdndHandler };

constant UI is export := Gnome::Shell::Main::UI;
