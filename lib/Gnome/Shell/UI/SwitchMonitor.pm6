use v6.c;

use Mutter::Meta::MonitorManager
use Gnome::Shell::UI::SwitcherPopup;

constant APP_ICON_SIZE is export = 96;

class Gnome::Shell::UI::SwitchMonitorPopup
  is Gnome::Shell::UI::SwitcherPopUp
{

  submethod BUILD {
    my @items = (
      {
        icon       => 'view-mirror-symbolic',
        label      => 'Mirror',
        configType => META_MONITOR_SWITCH_CONFIG_ALL_MIRROR,
      },

      {
        icon       => 'video-joined-displays-symbolic',
        label      => 'Join Displays',
        configType => META_MONITOR_SWITCH_CONFIG_ALL_LINEAR,
      }
    );

    if global.backend.get_monitor_manager.has-builtin-panel {
      @items.append: (
        {
          icon       => 'video-single-display-symbolic',
          label      => 'External Only',
          configType => META_MONITOR_SWITCH_CONFIG_EXTERNAL,
        },

        {
          icon       => 'computer-symbolic',
          label      => 'Built-in Only',
          configType => META_MONITOR_SWITCH_CONFIG_BUILTIN,
        }
      );
    }

    self.setItems(@items);

    $!switcherList = Gnome::Shell::UI::SwitchMOnitorSwitcher.new(@items);
  }

  method show ($backward, $binding, $mask) {
    return False unless Mutter::Meta::MonitorManager.get.can-switch-config;

    nextsame;
  }

  method initialSelection {
    my $currentConfig = Mutter::Meta::MonitorManager.get.get-switch-config;
    my $selectConfig  = $currentConfig.succ % self.items.elems;
    self.select($selectConfig);
  }

  method keyPressHandler ($_, $action) {
    {
      when $action == META_KEY_BINDING_ACTION_SWITCH_MONITOR {
        self.select(self.next)
      }

      when CLUTTER_KEY_LEFT  { self.select(self.prev) }
      when CLUTTER_KEY_RIGHT { self.select(self.next) }

      default { return CLUTTER_EVENT_PROPAGATE }
    }

    CLUTTER_EVENT_STOP
  }

  method finish {
    callsame;

    global.backend.get-monitor-manager.switch-config(
      @!items[self.selectedIndex]
    )
  }
}

class Gnome::Shell::UI::SwitchMonitorSwitcher
  is Gnome::Shell::UI::SwitcherPopup::SwitcherList
{
  submethod BUILD ( :@items ) {
    self.addIcon($_) for @items;
  }

  method addIcon ($item) {
    my $box = Gnome::Shell::St::BoxLayout.new(
      style_class => 'alt-tab-app',
      vertical    => True,
    );

    my $icon = Gnome::Shell::St::Icon.new(
      icon-name => $item.icon,
      icon_size => APP_ICON_SIZE
    ):
    $box.add-child($icon);

    my $text = Gnome::Shell::St::Label.new(
      text    => $icon.label;
      x-align => CLUTTER_ACTOR_ALIGN_CENTER
    );
    $box.add-child($text);

    self.addItem($box, $text);
  }
}
