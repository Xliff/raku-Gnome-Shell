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

my $remoteAccessInhibited = False;

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

  has $.componentManager;
  has $.extensionManager;
  has $.panel;
  has $.overview;
  has $.runDialog;
  has $.lookingGlass;
  has $.welcomeDialog;
  has $.wm;
  has $.messageTray;
  has $.screenShield;
  has $.notificationDaemon;
  has $.windowAttentionHandler;
  has $.ctrlAltTabManager;
  has $.padOsdService;
  has $.osdWindowManager;
  has $.osdMonitorLabeler;
  has $.sessionMode;
  has $.screenshotUI;
  has $.shellAccessDialogDBusService;
  has $.shellAudioSelectionDBusService;
  has $.shellDBusService;
  has $.shellMountOpDBusService;
  has $.screenSaverDBus;
  has $.uiGroup;
  has $.magnifier;
  has $.xdndHandler;
  has $.keyboard;
  has $.layoutManager;
  has $.kbdA11yDialog;
  has $.inputMethod;
  has $.introspectService;
  has $.locatePointer;
  has $.endSessionDialog;

  has $.modalCount = 0;
  has $.actionMode = Shell.ActionMode.NONE;
  has $.modalActorFocusStack = [];

  has %!S;

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

  method start is asynchronous {
    start {
      globalThis.log = $*ERR;
      globalThis.logError = sub ($e, $m) {
        my @a = ( formatErr($e) );
        @a.unshift("{ $msg }:");
        $*ERR.say: |@a;
      }

      Global.notify('error').tap: sub ($g, $m, $d) {
        notifyError($m, $d);
      }

      if %*ENV<XDG_CURRENT_DESKTOP> -> $cd {
        GIO::DesktopAppInfo.set-desktop-env('GNOME')
          unless $cd && $cd.first( * eq 'GNOME', :k ).defined;
      }

      my $sm = Gnome::Shell::UI::SessionMode.SessionMode;
      $sm.Updated.tap: sub { self.sessionUpdated }

      my \St := Gnome::Shell::St::Settings;
      St.get.notify('high-contrast').tap: SUB { loadDefaultStylesheet }
      St.get.InputMethodnotify('color-scheme').tap:  SUB { loadDefaultStylesheet }

      ParentalControlsManager.getDefault;
      await initializeUI;

      ::("\$shell{ $_ }DBusService") = ::("Gnome::Shell::UI::{ $_ }DBus").new
        for <AccessDialog AudioDeviceSelection>
      $shellDBusService        =
        Gnome::Shell::ShellDBus.GnomeShell.new;
      $shellMountOpDBusService =
        Gnome::Shell::MountOperation.GnomeShellMountOpHandler.new;s

      my $watchId = GIO::DBus.sessioni.watch-name(
        'org.gnome.Shell.Notifications',
        G_BUS_NAME_WATCHER_AUTO_START,
        bus => bus.unwatch-name($watchId)
      );

      $.sessionUpdated;
    }
  }

  method sessionUpdated {
    self!loadDefaultStylesheet if sessionMode.hasRunDialog;
    wm.allowKeybinding(
      'overlay-key',
      SHELL_ACTION_MODE_NONE +| SHELL_ACTION_MODE_OVERVIEW,
    );
    wm.allowKeyBinding('locate-pointer-key', SHELL_ACTION_MODE_ALL);
    wm.setCustomKeybindingHandler(
      'panel-run-dialog',
      SHELL_ACTION_MODE_NORMAL +| SHELL_ACTION_MODE_OVERVIEW,
      sub { sessionMode.hasRunDialog ?? openRunDialog !! Nil }
    )

    unless sessionMode.hasRunDialog {
      .().close with ::("\&{ $_ }") for <RunDialog LookingGlass WelcomeDialog>;
    }

    if Global.backend.get-remote-access-controller -> \rac {
      if sessionMode.allowScreencast && $remoteAccessInhibited {
        rac.uninhibit_remote_access;
        $remoteAccessInhibited = False;
      } else if sessionMode.allowScreencast.not && $remoteAccesssInhibited.not {
        rac.inhibit-remote-access;
        $remoteAccessInhibited = True;
      }
    }
  }

  constant AU = Gnome::Shell::UI::AppUsage;
  constant AS = Gnome::Shell::UI::Main::AnimationSettings;
  constant ED = Gnome::Shell::UI::ExtensionSystem::Downloader;
  constant LM = Gnome::Shell::UI::LoginManager;
  constant WT = Gnome::Shell::UI::WindowTracker;

  method initializeUI is asynchronous {
    start {
      WT.get-default;
      AU.get-default;

      reloadThemeResource;
      loadIcons;
      loadOskLayouts;
      loadDefaultStylesheet;
      loadWorkspaceAdjustment;

      AS.new;

      sub initModule (*@m) {
        %S{ .shortname } = .new for @m;
      }

      my $layoutManager = Gnome::Shell::UI::LayoutManager.new;
      my $uiGroup       = $layoutManager.uiGroup;

      initModules(
        Gnome::Shell::UI::PadOsd::Service
        Gnome::Shell::UI::XdndHandler
        Gnome::Shell::UI::CtrlAltTab
        Gnome::Shell::UI::OsdWindow::Manager
        Gnome::Shell::UI::OsdMonitorLabeler
        Gnome::Shell::UI::Overview
        Gnome::Shell::UI::KbdA11yDialog
        Gnome::Shell::UI::WindowManager
        Gnome::Shell::UI::Magnifier::Magnifier
        Gnome::Shell::UI::LocatePointer
        Gnome::Shell::UI::InputMethod
      );

      (my $screenShield)    = Gnome::Shell::UI::ScreenShield.new
        if LM.canLock;

      Global.Shutdown.tap: SUB {
        Clutter::Backend.get-default.unset-input-method
      }

      initModules(
        Gnome::Shell::UI::MessageTray,
        Gnome::Shell::UI::Panel,
        Gnome::Shell::UI::Keyboard,
        Gnome::Shell::UI::NotificationDaemon,
        Gnome::Shell::UI::WindowAttentionHandler,
        Gnome::Shell::UI::Components,
        Gnome::Shell::UI::Introspect,
        Gnome::Shell::UI::EndSessionDialog
      );

      .init for $layoutManager, $overview;

      Gnome::Shell::UI::PointerA11yTimeout.new;

      Global.Locate-Pointer.tap: SUB {
        $locatePointer.show;
      }

      Global.Show-Restart-Message.tap: sub ($, $message) => {
        showRestartMessage($message);
        True;
      }

      Global.display.Restart.tap: SUB {
        Global.reexec-self;
        True;
      }

      Global.display.GL-Video-Memory-Purged.tap: SUB { loadTheme }

      Global.display.notify('unsafe-mode', SUB {
        return unless Global.context.unsafe-mode;
        return if     $looking-class?.isOpen;

        my $source = MT.getSystemSource;
        my $notification = MT.Notification(
          $source,
          title       => 'System was put in unsafe mode',
          body        => 'Apps now have unrestricted access',
          isTransient => True
        );
        $notification.addAction(
          'Undo',
          SUB { Global.context.unsafe-mode = False }
        );
        $source.addNotification($notification);
      }

      my $endSessionDialog = Gnome::Shell::UI::EndSessionDialog.new;

      GLib::Timeout.idle-add: SUB {
        Gnome::Shell::Utils.util-sd-notify;
        Global.context.notify-ready;
        G_SOURCE_REMOVE;
      }

      $!startDate = DateTime.now;

      ED.init;
      my $em = Gnome::Shell::UI::ExtensionSystem::ExtensionManager.new;
      $em.init;

      $layoutManager.Startup-Prepared.tap: SUB { $screenShield.showDialog }
        if $sessionMode.isGreeter && $screenShield;

      my ($Scripting, $perfModule);
      my $animationScript = Global.animationScript;
      if $automationScript {
        $Scripting  = try require ::('Scripting.rakumod');
        $perfModule = try require ::($automationScript.uri);
        $perfModule.?init if $perfModule;
      }

      if $sessionMode eq <gdm initial-setup>.any {
        GLib.log_structured(
          LOG_DOMAIN,
          G_LOG_LEVEL_MESSAGE,
          {
            MESSAGE     => "GNOME Shell started at {$!startDate}",
            MESSAGE_ID  => GNOMESHELL_STARTED_MESSAGE_ID,
          }
        )

      }

      $layoutManager.Startup-Complete.tap: SUB {
        $actionMode = SHELL_ACTION_MODE_NORMAL
          if $actionMode == SHELL_ACTION_MODE_NONE;

        $screenShield?.lockIfWasLocked;

        unless $perfModule {
          if (my $creds = GIO::Credentials.new).unix-user).not {
            notify(
              'Logged in as a priviledged user',
              "Running a session as a privileged user should be avoided for {
               '' }security reasons. If possible, you should log in as a {
               '' }normal user."
            );
          } else if $sm.showWelcomeDialog {
            handleShowWelcomeScreen;
          }
        }

        handleLockScreenWarning
          if $sessionMode.currentMode ne <gdm initial-setup>.all;

        LM.registerSessionWithGDM;

        $Scripting.runPerfScript( $perfModule, %*ENV<SHELL_PERF_OUTPUT> )
          if $perfModule;
      }
    }
  }

  method handleShowWelcomeScreen {
    my $lsv = Global.settings.get-string(WELCOME_DIALOG_LAST_SHOWN_VERSION);
    my $ltc = Gnome::Shell::Util.GNOMEversionCompare(
      WELCOME_DIALOG_LAST_TOUR_CHANGE,
      $lsv
    );

    if $ltc > 0 {
      openWelcomeDialog;
      Global.settings.set-string(
        WELCOME_DIALOG_LAST_SHOWN_VERSION,
        Gnome::Shell::Misc::Config.PACKAGE_VERSION
      );
    }
  }

  method handleLockScreenWarning is asynchronous {
    start {
      my $p = Global.userdatadir.add('lock-warning-shown');
      my $f = GIO::File.new-for-path($p);

      my $*GERROR_EXCEPTIONS = True;
      if $screenShield.defined {
        CATCH {
          default {
            $*ERR.say($_) unless $e if $_ ~~ X::GLib::Error.new(
              code => G_IO_ERROR_NOT_FOUND
            );
          }
        }
        $f.delete_async;
      } else {
        CATCH { default { $*ERR.say($_) } }
        $f.touch-async;

        notify(
          'Screen Lock disabled',
          'Screen Locking requires the GNOME display manager'
        );
      }
    }
  }

  method getStylesheet ($name) {
    if GIO::File.new_for_uri(
      "resource:///org/gnome/shell/themes/{ $name }"
    ) -> $ss {
      return $ss if $ss.query_exists;
    }

    for GLib::Get-system-data-dirs[] {
      my $ss = GIO::File.new_for_path("{ $_ }/gnome-shell/themes/{ $name }");
      return $ss if $ss.query_exists;
    }

    if GIO::File.new-for-path("{ Global.datadir }/theme/{ $name }") -> $ss {
      return $ss if $ss.query_exists;
    }
    Nil;
  }

  method getStyleVariant {
    my $cs = Gnome::Shell::St::Settings.get;
    do given $sessionMode."{ $cs }"() {
      when 'force-dark'  { 'dark'  }
      when 'force-light' { 'light' }
      when 'prefer-dark' { $cs == ST_COLOR_SCHEME_PREFER_LIGHT  ?? 'light'
                                                                !! 'dark' }
      when 'prefer-dark' { $cs == ST_COLOR_SCHEME_PREFER_DARK   ?? 'light'
                                                                   'dark' }
      default            { '' }
    }
  }

  method getDefaultStylesheet {
    my ($name, $ss) = ($sessionMode.stylesheetName);

    if Gnome::Shell::St::Settings.get.high-contrast.so {
      $ss = getStyleSheet( $name.subst('.css', '-high-contrast.css') );
    }

    if $ss.defined.not {
      $ss = getStylesheet( $name.subst('.css', "-{ $.getStyleVariant }.css") );
    }

    if $ss.defined.not {
      $ss = getStyleSheet($name);
    }

    return $ss;
  }

  method loadDefaultStylesheet {
    my $ss = $.getDefaultStylesheet;
    return if $!defaultStylesheet && $!defaultStyleSheet eq $ss;
    $!defaultStylesheet = $ss;
    loadTheme;
  }

  # cw: This does NOT work because 1 !== (1 but ROLE)
  #
  # class AdjustmentRegistry {
  #   has $.count         = 0;
  #   has %!adjustments;
  #
  #   role AdjustmentValue {
  #     method DESTROY {
  #       if %!adjustments{self.WHERE} -> $m {
  #         $m(self);
  #       }
  #     }
  #   }
  #
  #   method adjustments { %!adjustments.Map }
  #
  #   method register ($adj) {
  #     %!adjustments{ $adj.WHERE } = $adj but AdjustmentValue;
  #   }
  #
  # }

  method loadWorkspaceAdjustment {
    my $wm  = Global.workspaceManager;
    my $awi = $wm.active-workspace-index;

    register-gobject-cleanup-class(
      'workspaces',
      sub ($_) { .remove-transition('value') }
    );

    $!workspacesAdjustment = Gnome::Shell::St::Adjustment.new(
      value          => $awi,
      lower          => 0,
      page-increment => 1,
      page-size      => 1,
      step-increment => 0,
      upper          => $wm.elems
    ) but GLib::Roles::Object::Cleanup['workspaces'];

    $wm.bind-property('n-workspaces', $!workspacesAdjustment, 'upper');

    $!workspacesAdjustment.notify('upper').tap: SUB {
      $!workspacesAdjustment.remove-transition('value');
      $!workspcesAdjustment.value = $wm.active-workspace-index;
    }
  }

  method createWorkspacesAdjustment ($actor) {
    my $a = Gnome::Shell::St::Adjustment.new( :$actor )
      but GLib::Roles::Cleanup['workspaces'];

    for self.listProperties {
      $_ eq 'value'
        ?? self.bind_property($_, $a, :bi, :create)
        !! self.bind_property($_, $a);
    }

    $a;
  }

  method getThemeStylesheet {
    Proxy.new:
      FETCH => -> $     { $!cssStylesheet },
      STORE => -> $, \v {
        if v.contains('{').not && v.ends-with('.css')
          ?? GIO::file.new_for_path(v) !! Nil;
        } else {
          $!cssStyleSheet = v;
        }
      }
  }

  method reloadThemeResource {
    $!themeResource.unregister-cleanup if $!themeResource;

    $!themeResource = GIO::Resource.load(
      Global.datadir.add($sessionMode.themeResourceName)
    ) but GLib::Roles::Object::Cleanup['workspaces'];
  }
  # class AdjustmentRegistry sub{
  #   has $.count         = 0;
  #   has %!adjustments;
  #
  #   role AdjustmentValue {
  #     method DESTROY {
  #       if %!adjustments{self.WHERE} -> $m {
  #         $m(self);
  #       }
  #     }
  #   }
  #
  #   method adjustments { %!adjustments.Map }
  #
  #   method register ($adj) {
  #     %!adjustments{ $adj.WHERE } = $adj but AdjustmentValue;
  #   }
  #
  # }

  method loadWorkspaceAdjustment {
    my $wm  = Global.workspaceManager;
    my $awi = $wm.active-workspace-index;

    register-gobject-cleanup-class(
      'workspaces',
      sub ($_) { .remove-transition('value') }
    );

    $!workspacesAdjustment = Gnome::Shell::St::Adjustment.new(
      value          => $awi,
      lower          => 0,
      page-increment => 1,
      page-size      => 1,
      step-increment => 0,
      upper          => $wm.elems
    ) but GLib::Roles::Object::Cleanup['workspaces'];

    $wm.bind-property('n-workspaces', $!workspacesAdjustment, 'upper');

    $!workspacesAdjustment.notify('upper').tap: SUB {
      $!workspacesAdjustment.remove-transition('value');
      $!workspcesAdjustment.value = $wm.active-workspace-index;
    }
  }

  method createWorkspacesAdjustment ($actor) {
    my $a = Gnome::Shell::St::Adjustment.new( :$actor )
      but GLib::Roles::Cleanup['workspaces'];

    for self.listProperties {
      $_ eq 'value'
        ?? self.bind_property($_, $a, :bi, :create)
        !! self.bind_property($_, $a);
    }

    $a;
  }

  method getThemeStylesheet {
    Proxy.new:
      FETCH => -> $     { $!cssStylesheet },
      STORE => -> $, \v {
        if v.contains('{').not && v.ends-with('.css')
          ?? GIO::file.new_for_path(v) !! Nil;
        } else {
          $!cssStyleSheet = v;
        }
      }
  }

  method reloadThemeResource {
    $!themeResource.unregister-cleanup if $!themeResource;

    $!themeResource = GIO::Resource.load(
      Global.datadir.add($sessionMode.themeResourceName)
    ) but GLib::Roles::Object::Cleanup['workspaces'];
  }

  method loadIcons {
    $!iconResource = GIO::Resource.load(
      Global.datadir.add('gnome-shell-icons.gresource')
    ) but GLib::Roles::Object::Cleanup['workspaces'];
  }

  method loadOskLayouts {
    $!oskResource = GIO::Resource.load(
      Global.datadir.add('gnome-shell-layouts.gresource')
    ) but GLib::Roles::Object::Cleanup['workspace'];
  }

  method loadTheme {
    my $tc = Gnome::Shell::St::ThemeContext.get-for-stage(Global.stage);
    my $pt = $tc.get-theme;

    my $theme = Gnome::Shell::St::Theme.new(
      application-stylesheet => $!cssStylesheet,
      default-stylesheet     => $!defaultCssStylesheet
    );

    without $theme.default-stylesheet {
      X::Error.new(
        message => "No valid stylesheet found for {
                    $sessionMode.stylesheetName }";
      ).throw;
    }

    $theme.load-stylesheet($_) for $pt[] if $pt;

    $tc.theme = $theme;
  }

  method notify ($msg, $details) {
    my $source       = Gnome::Shell::UI::MessageTray.getSystemSource;
    my $notification = Gnome::Shell::UI::MessageTray::Notification.new(
      source      => $source,
      title       => $msg,
      body        => $details,
      isTransient => True
    );

    $source.addNotification($notification);
  }

  method notifyError ($msg, $details) {
    $*ERR.say: [~](
      "Error: { $msg }",
      $details ?? ": { $details }" !! ''
    );

    $.notify($msg, $details);
  }

  method findModal ($grab) {
    $!modalActorFocusStack.&firstObject($grab, :k) // -1
  }

  method pushModal ($actor, *%params) {
    my $actionMode = %params<actionMode> // SHELL_ACTION_MODE_NONE;
    my $grab       = Global.stage.grab($actor);

    Mutter::Meta::Utils.disable-unredirect-for-display(Global.stage)
    unless $!modalCount++;

    my $destroyId = $actor.destroy.tap: SUB {
      if findModal($grab) >= 0 {
        $.popModal($grab);
      }
    }

    my $prevFocusDestroyId;

    with (my $prevFocus = Global.stage.get-key-focus) {
      $prevFocusDestroyId = $prevFocus.destroy.tap: SUB {
        if $!modalActorFocusStack.first({ .prevFocus.is($prevFocus) }) -> $o {
          $o.prevFocus = Nil;
        }
      }
    }
    $!modalActorFocusStack.push: %{
      :$actor,
      :$grab,
      :$destroyId,
      :$prevFocus,
      :$prevFocusDestroyId,
      :$actionMode
    }

    $!actionMode = %params<newActionMode>;
    Global.stage.set-key-focus($actor);
    $grab;
  }

  method popModal ($grab) {
    if ( my $focusIndex = $.findModal($grab) ) < 0 {
      Global.stage.unset-key-focus;
      $!actionMode = SHELL_ACTION_MODE_NORMAL;
    }

    $!modalCount--;

    given ( my $record = $!modalActorFocusStack[$focusIndex] ) {
      .<destroyId>.untap;
      .<grab>.dismiss;
    }

    if $focusIndex == $modalActorFocusStack.elems.pred {
      $record<prevFocusDestoryId>.untap if $record<prevFocus>;
      $!actionMode = $record<actionMode>;
      Global.stage.set-key-focus( $record<prevFocus> );
    } else {
      if $!modalActorFocusStack.tail -> $t {
        $t<prevFocus><prevFocusDestroyId>.untap if $t<prevFocus>;
      }
      for $!modalActorFocusStack[
        $focusIndex ^.. $!modalActorFocusStack.elems.pred
      ].reverse.rotor(2 => -1) {
        .tail = .head
      }
    }
    $!modalActorFocusStack.splice($focusIndex, 1);
    return if $!modalCount;
    $!layoutManager.modalEnded;
    Mutter::Meta::Util.enable-unredirect-for-display(Global.display);
    $!actionMode = SHELL_ACTION_MODE_NORMAL;
  }

  method createLookingGlass {
    $!lookingGlass //= Gnome::Shell::UI::LookingGlass.new;
  }

  method openRunDialog {
    ( $!runDialog //= Gnome::Shell::UI::RunDialog.new ).open;

  }

  method openWelcomeDialogs {
    ( $!welcomeDialog //= Gnome::Shell::UI::WelcomeDialog.new ).open;
  }

  method activateWindow ($w, $t is rw, $wn) {
    my $wm  = Global.workspace-manager;
    my $awi = $wm.active-workspace-index;
    my $wwi = $awi.defined ?? $wm !! $!window.workspace.index;

    $t //= Global.get-current-time;

    if $wwi == $awi {
      $wm.get-workspace-by-index($wwi).activate-with-focus($w, $t);
    } else {
      $w.activate($t);
    }

    $!overview.hide;
    $!panel.closeCalendar;
  }

  method moveWindowToMonitorAndWorkspace ($w, $mi, $wi, $append = False) {
    if $w.monitor != $mi {
      (my $id) = Global.Window-Entered-Monitor.tap: sub ($dsp, $num, $win) {
        return unless $w.is($win);
        $w.change-workspace-by-index($wi, $append);
        $id.clear;
      }
      $w.move-to-monitor($mi);
    } else {
      $w.change-workspace-by-index($wi, $append);
    }
  }

  constant DEFERRED_TIMEOUT_SECONDS = 20;

  my $deferredWorkData     = %{};
  my $deferredWorkQueue    = [];
  my $beforeRedrawQueue    = [];
  my $deferredWorkSequence = 0;
  my $deferredTimeoutId    = 0;

  method runDeferredWork ($workId) {
    return unless  $deferredWorkData[$workId];
    return without ( my $index = $deferredWorkQueue.first( $workId, :k ) );

    $deferredWorkQueue.splice($index, 1);
    $deferredWorkData[$workId].callback();
    $deferredTimeoutId.?clear;
  }

  method runAllDeferredWork {
    $.runDeferredWork( $deferredWorkQueue.head )
      while $deferredWorkQueue.elems;
  }

  method runBeforeRedrawQueue {
    runDeferredWork($_) for $beforeRedrawQueue[];
    $beforeRedrawQueue = [];
  }

}

method initializeDeferredWork ($a, &c) {
  my $workId = ++$!deferredWorkSequence;
  $!deferredWorkData[$workId] = ( actor => $a, callback = &c );
  $a.notify('mapped').tap: SUB {
    return if (
      $actor.mapped &&
      $!deferredWorkQueue.first( $workId ).defined).not
    );
    self.queueBeforeRedraw[$workId]
  }
  $workId;
}

method queueDeferredWork ($workId) {
  without ( my $data = $!deferredWorkData[$workId] ) {
    $*ERR.say("Invalid work id {$workId}");
    # cw: Throw a GError, here? If so, what is the domain and code?
    return;
  }
  if $!deferredWorkQueue.first($workId).defined.not {
    $!deferredWorkQueue.push: $workId
  } elsif $data<actor>.mapped {
    queueBeforeRedraw($workId)
  } elsif $!deferredTimoutId.not {
    $!deferredTimeoutId = GLib::Timeout.add-seconds(
      name => '[raku-gnome-shell] runAllDeferredWork',

      DEFERRED_TIMEOUT_SECONDS,
      SUB {
        self.runAllDeferredWork;
        $!deferredTimoutId = 0;
        G_SOURCE_REMOVE;
      }
    );
  }
}

class Gnome::Shell::UI::Main::RestartMessage
  is Gnome::Shell::UI::ModalDialog
{
  submethod BUILD ( :$message ) {
    self.setAttributes(
      shellReactive  => True,
      styleClass     => 'restart-message headline',
      shouldFadeIn   => False,
      destroyOnClose => True
    );

    my $label = Gnome::Shell::St::Label.new(
      text    => $message,
      x-align => CLUTTER_ACTOR_ALIGN_CENTER,
      y-align => CLUTTER_ACTOR_ALIGN_CENTER
    );

    self.contentLayout.add-child($label);
    self.buttonLabel.hide;
  }
}

sub showRestartMessage ($message) is export {
  Gnome::Shell::UI::Main::RestartMessage.new.open;
}

class Gnome::Shell::UI::Main::AnimationSettings {
  has $!animationsEnabled;
  has $!handles            = Set.new'

  submethod BUILD {
    Global.notify('force-animations').tap: SUB {
      self.syncAnimationsEnabled;
    }

    self.syncAnimationsEnabled;
    if Global.backend.remote-access-controller -> $rac {
      $rac.New-Handle.tap: sub ($, $handle) {
        self.onNewRemoteAccess($handle);
      }
    }
  }

  method shouldHandleAnimations {
    return False if $!handles.elems;
    return True  if Global.force-animations;
    return False if Global.backend.is-rendering-hardware-accelerated;
    return False if Gnome::Shell::Utils.has-x11-display-extension(
      Global.display,
      'VNC-EXTENSION'
    );
    True;
  }

  method syncAnimationsEnabled {
    my $ae = $.shouldEnableAnimations;
    return if $!animationsEnabled = $ae;
    $!animationsEnabled = $ae;

    my $s = Gnome::Shell::St::Settings.get;
    $ae ?? $s.uninhibit-animations
        !! $.inhibit-animations;
  }

  method onRemoteAccessHandleStopped ($h) {
    $!handles.delete($h);
    $.syncAnimationsEnbled;
  }

  method onNewRemoteAccessHandle ($h) {
    return unless $h.disable-animations;

    $!handles.add($h);
    $.syncAnimationsEnabled;
    $h.Stopped.tap: SUB {
      self.onRemoteAccessHandleStopped
    }
  }
}

constant Ui   is export  = Gnome::Shell::UI::Main;
constant UI   is export := Ui;
constant Main is export := Ui;

our sub AccessDialog            { Ui.AccessDialog            }
our sub AudioDeviceSelection    { Ui.AudioDeviceSelection    }
our sub Components              { Ui.Components              }
our sub Config                  { Ui.Config                  }
our sub CtrlAltTab              { Ui.CtrlAltTab              }
our sub EndSessionDialog        { Ui.EndSessionDialog        }
our sub ExtensionDownloader     { Ui.ExtensionDownloader     }
our sub ExtensionSystem         { Ui.ExtensionSystem         }
our sub Introspect              { Ui.Introspect              }
our sub InputMethod             { Ui.InputMethod             }
our sub KbdA11yDialog           { Ui.KbdA11yDialog           }
our sub Keyboard                { Ui.Keyboard                }
our sub Layout                  { Ui.Layout                  }
our sub LoginManager            { Ui.LoginManager            }
our sub LocatePointer           { Ui.LocatePointer           }
our sub LookingGlass            { Ui.LookingGlass            }
our sub Mangnifier              { Ui.Mangnifier              }
our sub MessageTray             { Ui.MessageTray             }
our sub ModalDialog             { Ui.ModalDialog             }
our sub NotificationDaemon      { Ui.NotificationDaemon      }
our sub OsdMonitorLabeler       { Ui.OsdMonitorLabeler       }
our sub OsdWindow               { Ui.OsdWindow               }
our sub Overview                { Ui.Overview                }
our sub PadOsd                  { Ui.PadOsd                  }
our sub Panel                   { Ui.Panel                   }
our sub Params                  { Ui.Params                  }
our sub ParentalControlsManager { Ui.ParentalControlsManager }
our sub PonterA11yTimeout       { Ui.PonterA11yTimeout       }
our sub RunDialog               { Ui.RunDialog               }
our sub ScreenShield            { Ui.ScreenShield            }
our sub Screenshot              { Ui.Screenshot              }
our sub SessionMode             { Ui.SessionMode             }
our sub ShellDBus               { Ui.ShellDBus               }
our sub ShellMountOperation     { Ui.ShellMountOperation     }
our sub Util                    { Ui.Util                    }
our sub WelcomeDialog           { Ui.WelcomeDialog           }
our sub WindowAttentionHandler  { Ui.WindowAttentionHandler  }
our sub WindowManager           { Ui.WindowManager           }
our sub XdndHandler             { Ui.XdndHandler             }
