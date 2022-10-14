use v6.c;

use Gnome::Shell::UI::BoxPointer;
use Gnome::Shell::UI::Main;
#use Gnome::Shell::UI::PopupMenu;

class Gnome::Shell::UI::EntryMenu
	is Gnome::Shell::UI::Popup::Menu
{
	has $!entry;
	has $!clipboard;
	has $!copyItem;
	has $!pasteItem;
	has $!passwordItem;

	submethod BUILD (:$!entry) {
		$!clipboard = Gnome::Shell::St::Clipboard.get-default;

		$!copyItem = Gnome::Shell::Popup::MenuItem.new('Copy');
		$!copyItem.activate.tap( -> @*a { self.onCopyActivated });
		self.addMenuItem($!copyItem);

		$!pasteItem = Gnome::Shell::Popup::MenuItem.new('Paste');
		$!pasteItem.activate.tap( -> @*a { self.onPasteActivated });
		self.addMenuItem($!pasteItem);

		self.makePasswordItem if $entry ~~ Gnome::Shell::St::PasswordEntry;
		UI<uiGroup>.add-actor(self.actor)
		self.actor.hide
	}

	method makePasswordItem {
		$!passwordItem = Gnome::Shell::Popup::MenuItem.new('');
		$!passwordItem.activate.tap( -> *@a { self.onPasswordActivated });
		self.addMenuItem($!passwordItem);

		$!entry.bind-property(
			'show-peek-icon',
			$!passwordItem,
			'visible'
			G_BINDING_FLAGS_SYNC_CREATE
		);
	}

	method open ($animate) {
		self.updatePasteItem;
		self.updateCopyItem;
		self.updatePasswordItem if $!passwordItem;

		callsame;
		$!entry.add-style-pseudo-class('focus');

		my $direction = ST_DIRECTION_TAB_FORWARD;
		self.actor.grab-key-focus unless self.actor.navigate-focus($direction);
	}

	method updateCopyItem {
		my $selection = $!entry.clutter-text.get-selection;
		$!copyItem.setSensitive(
			$!entry.clutter-text.password-char && $selection
		);
	}

	method updatePasteItem {
		$!clipboard.get-text(
			ST_CLIPBOARD_TYPE_CLIPBOARD,
			-> *@a ($, $text) { $!pasteItem.setSensitive($text.so) }
		);
	}

	method updatePasswordItem {
		$!passwordItem.label.text = $!entry.password-visible
			?? 'Show Text'
			!! 'Hide Text';
	}

	method onCopyActivated {
		$!clipboard.set-text(
			ST_CLIPBOARD_TYPE_CLIPBOARD,
			$!entry.clutter-text.get-selection
		);
	}

	method onPasteActivated {
		$!clipboard.get-text(
			ST_CLIPBOARD_TYPE_CLIPBOARD,
			sub ($, $text) {
				return unless $text;

				$!entry.clutter-text.delete-selection;
				my $pos = $!entry.clutter-text.get-cursor-position;
				$!entry.clutter-text.insert-text($text, $pos);
			}
		);
	}

	method onPasswordActivated {
		$!entry.password-visible .= not;
	}

}

sub setMenuAlignment ($entry, $stageX) {
	my $entryX = $entry.transform-stage-point($stageX, 0);
	# cw: Can't use "/" due to broken syntax highlighting in Sublime Text.
	#     Feel free to fix.
	$entry.menu.setSourceAlignment($entryX * $entry.width ** -1) if $entryX;
}

sub onButtonPressEvent ($actor, $event, $entry) {
	if $entry.menu.isOpen {
		$entry.menu.close(BOXPOINTER_POPUP_ANIMATION_FULL);
		return CLUTTER_EVENT_STOP;
	} elsif $event.get-button == 3 {
		setMernuAlignment($entry, $event.get-coords.head);
		$entry.menu.open(BOXPOINTER_POPUP_ANIMATION_FULL);
		return CLUTTER_EVENT_STOP;
	}
	CLUTTER_EVENT_PROPAGATE;
}

sub onPopup ($actor, $entry) {
	my $cursorPosition = $entry.clutter-text.get-cursor-position;

	my ($textX, $textY, $lineHeight) = $entry.clutter-text.position-to-coords(
		$cursorPosition
	);

	$entry.menu.setSourceAlignment($textX * $entry.width ** -1)
		if $textX.defined;
	$entry.menu.open(BOXPOINTER_POPUP_ANIMATION_FULL);
}

sub addContextMenu is export ($entry, $params) {
	return if $entry.menu;

	$params = mergeHash($params, { actionMode => SHELL_ACTION_MODE_POPUP });
	$entry.menu = Gnome::Shell::UI::EntryMenu.new($entry);
	$entry.menuManager = Gnome::Shell::UI::Popup::MenuManager.new(
		$entry,
		actionMode => $params<actionMode>
	);
	$entry.menuManager.addMenu($entry.menu);

	$entry.clutter-text.button-press-event.tap( -> *@a ($actor, $event) {
		onButtonPressEvent($actor, $event, $entry);
	});
	$entry.button-press-event.tap( -> *@a ($actor, $event) {
		onButtonPressEvent($actor, $event, $entry)
	});

	$entry.popup-menu.tap( -> *@a ($actor) { onPopup($actor, $entry) });

	$entry.destroy.tap( -> *@a {
		$entry.menu.destroy;
		$entry.menu = $entry.menuManager = Nil;
	});
}

class Gnome::Shell::UI::CapsLockWarning
 	is Gnome::Shell::St::Label
{
	has $!keymap;
	has $!stateChangedId;

	submethod BUILD {
		self.text = 'Caps lock is on.';

		( .ellipsize, .line-wrap ) = (PANGO_ELLIPSIZE_NONE, True)
			given self.clutter-text;

		constant MCB = Mutter::Clutter::Backend;
		$!keymap = MCB.get-default-backend.get-default-seat.get-keymap;

		$!stateChangedId = 0;

		self.notify('mapped').tap( -> *@a {
			self.is-mapped
			  ?? $!keymap.state-changed.tap( -> *@a { self.sync(True) })
			  !! $!keymap.disconnect-object(self);

			self.sync(False)
		});
	}

	method sync ($animate) {
		my $capsLockOn = $!keymap.get-caps-lock-state;

		self.remove-all-transitions;

		self.natural-height-set = self<naturalHeightSet>;
		my $height = self.get-preferred-height(-1).tail;

		self.ease(
			$animate ?? 200 !! 0,
			height     => $capsLockOn ?? $height !! 0,
			opacity    => $capsLockOn ?? 255     !! 0,
			onComplete => -> *@a {
				self.height = -1 if $capsLockOn
			}
		);
	}

	method new (*%params) {
		my $style-class = %params<style-class> // 'caps-lock-wanring-label';

		self.bless( :$style-class )
	}

}
