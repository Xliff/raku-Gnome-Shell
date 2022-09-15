use v6.c;

my %S;

use Gnome::Shell::UI::Layout;
use Gnome::Shell::UI::PadOsd;
use Gnome::Shell::UI::XdndHandler;
use Gnome::Shell::UI::CtrlAltTab;
use Gnome::Shell::UI::OsdWindow;
use Gnome::Shell::UI::OsdMonitorLabeler;
use Gnome::Shell::UI::Overview;
use Gnome::Shell::UI::KbdA11yDialog;
use Gnome::Shell::UI::WindowManager;
use Gnome::Shell::UI::Mangnifier;
use Gnome::Shell::UI::LocatePointer;
use Gnome::Shell::UI::InputMethod;
use Gnome::Shell::UI::Screenshot;
use Gnome::Shell::UI::MessageTray;
use Gnome::Shell::UI::Panel;
use Gnome::Shell::UI::Keyboard;
use Gnome::Shell::UI::NotificationDaemon;
use Gnome::Shell::UI::WindowAttentionHandler;
use Gnome::Shell::UI::Components;
use Gnome::Shell::UI::PonterA11yTimeout;
use Gnome::Shell::Misc::Introspect;

class Gnome::Shell::Main::UI does Associative {

  method initializeUI {
    # cw: Theres more stuff before this! DO THAT!
    %S{ $_ ~~ Pair ?? .key !! .^shortname } = .value.new
      for LayoutManager           => Layout,
          PadOsdService           => PadOsd,
          XdndHandler,
          CtrlAltTabManager       => CtrlAltTab,
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

sub LayoutManager          is export { Ui.LayoutManager          }
sub PadOsdService          is export { Ui.PadOsdService          }
sub XdndHandler            is export { Ui.XdndHandler            }
sub CtrlAltTabManager      is export { Ui.CtrlAltTabManager      }
sub XdndHandler            is export { Ui.XdndHandler            }
sub OsdWindowManager       is export { Ui.OsdWindowManager       }
sub OsdMonitorLabeler      is export { Ui.OsdMonitorLabeler      }
sub Overview               is export { Ui.Overview               }
sub KbdA11yDialog          is export { Ui.KbdA11yDialog          }
sub WindowManager          is export { Ui.WindowManager          }
sub Mangnifier             is export { Ui.Mangnifier             }
sub LocatePointer          is export { Ui.LocatePointer          }
sub InputMethod            is export { Ui.InputMethod            }
sub Screenshot             is export { Ui.Screenshot             }
sub MessageTray            is export { Ui.MessageTray            }
sub Panel                  is export { Ui.Panel                  }
sub KeyboardManager        is export { Ui.KeyboardManager        }
sub NotificationDaemon     is export { Ui.NotificationDaemon     }
sub WindowAttentionHandler is export { Ui.WindowAttentionHandler }
sub ComponentManager       is export { Ui.ComponentManager       }
sub PonterA11yTimeout      is export { Ui.PonterA11yTimeout      }
sub IntrospectService      is export { Ui.IntrospectService      }
sub uiGroup                is export { Ui.uiGroup                }
sub ScreenShield           is export { Ui.ScreenShield           }
sub ExtensionManager       is export { Ui.ExtensionManager       }

constant UI is export := Gnome::Shell::Main::UI;
