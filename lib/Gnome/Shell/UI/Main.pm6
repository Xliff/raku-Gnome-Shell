use v6.c;

#our \LayoutManager          is export;
#our \PadOsdService          is export;
#our \XdndHandler            is export;
#our \CtrlAltTabManager      is export;
#our \XdndHandler            is export;
#our \OsdWindowManager       is export;
#our \OsdMonitorLabeler      is export;
#our \Overview               is export;
#our \KbdA11yDialog          is export;
#our \WindowManager          is export;
#our \Mangnifier             is export;
#our \LocatePointer          is export;
#our \InputMethod            is export;
#our \Screenshot             is export;
#our \MessageTray            is export;
#our \Panel                  is export;
#our \KeyboardManager        is export;
#our \NotificationDaemon     is export;
#our \WindowAttentionHandler is export;
#our \ComponentManager       is export;
#our \PonterA11yTimeout      is export;
#our \IntrospectService      is export;
#our \uiGroup                is export;
#our \ScreenShield           is export;
#our \ExtensionManager       is export;


my %S;

class UI does Associative {

  method initializeUI {
    # cw: Theres more stuff before this! DO THAT!
    %S{ $_ ~~ Pair ?? .key !! .^shortname } = .value.new
      for LayoutManager           => Layout,
          PadOsdService           => PadOsd,
          XdndHandler,
          CtrlAltTabManager       => CtrlAltTab,
          XdndHandler
          OsdWindowManager        => OsdWindow,
          OsdMonitorLabeler,
          Overview,
          KbdA11yDialog,
          WindowManager,
          Mangnifier,
          LocatePointer,
          InputMethod,
          Screenshot,
          MessageTray,
          Panel,
          KeyboardManager         => Keyboard,
          NotificationDaemon,
          WindowAttentionHandler,
          ComponentManager        => Components,
          PonterA11yTimeout,
          IntrospectService       => Introspect;

    # Various parts of the codebase still refer to Main.uiGroup
    # instead of using the layoutManager. This keeps that code
    # working until it's updated.
    %S<uiGroup> := S<LayoutManager>.uiGroup;

    %S<ScreenShield> = ScreenShield.new if Gnome::Shell::LoginManager.canLock;

    # cw: Figure out what this is.
    #Clutter.get_default_backend().set_input_method(inputMethod);

    %S<LayoutManager>.init;
    %S<Overview>.init;

    # cw: There's more stuff after this, so DO THAT TOO!
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
