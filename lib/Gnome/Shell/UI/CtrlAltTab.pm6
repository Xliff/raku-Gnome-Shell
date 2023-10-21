use v6.c;

use Gnome::Shell::UI::Main;
use Gnome::Shell::UI::Switcher;

constant POPUP_APPICON_SIZE is export = 96;

### /home/cbwood/Projects/gnome-shell/js/ui/ctrlAltTab.js

class Gnome::Shell::UI::CtrlAltTab::Popup { ... }

class Gnome::Shell::UI::CtrlAltTab::Manager {
	has @!items;

	submethod BUILD {
		self.addGroup(
			global.window_group,
			'Windows',
			'focus-windows-symbolic',
			{
				sortGroup     => SORT_GROUP_TOP,
				focusCallback => -> *@a {
					self.focusWindows( |@a )
				}
			}
		);
	}

	method addGroup ($root, $name, $icon, $params) {
		my %items = mergeHash($params, {
			sortGroup     => SORT_GROUP_MIDDLE,
			proxy         => $root,
			focusCallback => Nil
		})

		$item<root name iconName> = ($root, $name, $icon);
		@!items.push($item);
		my $s := self;
		$root.destroy.tap(-> *@a { $s.removeGroup($root) });
		Global.focus-manager.add-group($root)
			if $root ~~ Gnome::Shell::St::Widget;
	}

	method removeGroup ($root) {
		Global.focus-manager.remove-group($root)
			if $root ~~ Gnome::Shell::St::Widget;
		@!items .= grep( * =:= $root );
	}

	method focusGroup ($item, $timestamp) {
		$item<focusCallback> ?? $item<focusCallback>($timeStamp)
		                     !! $item<root>.navigage-focus(
		                     		$,
		                     		ST_DIRECTION_TYPE_TAB_FORWARD
		                     	)
	}

	method popup ($backward, $binding, $mask) {
		my $items := @!items.grep( *.proxy.mapped );

		if Main.sessionMode.hasWindows && UI<overView>.visible {
			my $display    = Global.display;
			my $aWorkspace = global.workspace-manager.get-active-workspace;
			my $windows    = $display.get-tab-list(
				META_TABLIST_DOCS,
				$aWorkspace
			);
			my $windowTracker = Gnome::Shell::WindowTracker.get-default;
			my $textureCache  = Gnome::Shell::St::TextureCache.get-default;

			for $windows[] {
				my ($icon, $iconName);
				if .get-window-type == META_WINDOW_TYPE_DESKTOP {
					$icon = 'video-display-symbolic'
				} else {
					my $app = UI<windowTracker>.get-window-app($_);
					my \m = 'bind-cairo-surface-property';
					$icon = $app
						?? $app.create_icon_texture(POPUP_APPICON_SIZE);
						!! Gnome::Shell::St::Icon(
						   	 gicon     => $textureCache."{ m }"($_, $icon),
							 icon-size => POPUP_APPICON_SIZE
						   );
				}


				my $w = $_;
				@!items.push: {
					name          => .title,
					proxy         => .get-compositor-private,
					focusCallback => -> $timestamp {
						activateWindow($w, $timestamp)
					}
					iconActor     => $icon,
					iconName	  => $iconName,
					sortGroup     => SOTR_GROUP_MIDDLE
				};
			}
		}

		return unless @!items.length;

		@!items.sort: -> $a, $b {
			if $a<sortGroup> - $b<sortGroup -> $d {
				return $d;
			}

			return $a.proxy.get-transformed-position.head -
				   $b.proxy.get-transformed-position.head;
		};

		my $p := $!popup;
		if $!popup {
			$!popup = CtrlAltTabPopup.new($items);
			$!popup.show($backward, $binding, $mask);
			$!popup.destroy.tap(-> *@a { $p = Nil });
		}
	}

}

class Gnome::Shell::UI::CtrlAltTab::Switcher { ... }

class Gnome::Shell::UI::CtrlAltTab::Popup
	is Gnome::Shell::UI::Switcher::Popup
{
	has $!switcherList;

	submethod BUILD ( :@items ) {
		$!switcherList = Gnome::Shell::UI::CtrlAltTab::Switcher.new(:@items);
	}

	method keyPresshHandler ($keysym, $action) {
		given $action {
			when META_KEY_BINDING_ACTION_SWITCH_PANELS {
				self.select(self.next)
			}

			when META_KEY_BINDING_ACTION_SWITCH_PANELS_BACKWARDS {
				self.select(self.previous)
			}

			when $keysym == CLUTTER_KEY_LEFT {
				self.select(self.previous)
			}

			when $keysymn == CLUTTER_KEY_RIGHT {
				self.select(self.next)
			}
		}
		CLUTTER_EVENT_PROPAGATE
	}

	method finish ($time) {
		callsame;
		UI<ctrlAltTabManager>.focusGroup(
			self.items[self.selectedIndex],
			$time
		);
	}
}

class Gnome::Shell::CtrlAltTab::Switcher
	is Gnome::Shell::SwitcherPopup::List
{

	submethod BUILD (:@items) {
		self.addIcon($_) for @items;
	}

	method addIcon ($item) {
		my $box = Gnome::Shell::St::BoxLayout.new(
			style-class => 'alt-tab-app',
			vertical    => True
		);

		my $icon = $item.iconActor // Gnome::Shell::St::Icon.new(
			icon-name => $item.iconName,
			icon-size => POPUP_APPICON_SIZE
		);
		$box.add-child($icon);

		my $text = Gnome::Shell::St::Label.new(
			text    => $item.name,
			x-align => CLUTTER_ACTOR_ALIGN_CENTER
		);
		$box.add-child($text);
		self.addItem($box, $text);
	}
}
