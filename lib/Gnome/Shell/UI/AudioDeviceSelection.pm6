use v6.c;

use Gnome::Shell::AppSystem;

use Gnome::Shell::Misc::FileUtils;

use Gnome::Shell::UI::Dialog;
use Gnome::Shell::UI::Main;
use Gnome::Shell::UI::ModalDialog;

### /home/cbwood/Projects/gnome-shell/js/ui/audioDeviceSelection.js

my \AudioDeviceSelectionIface = loadInterfaceXML(
	'org.gnome.Shell.AudioDeviceSelection'
);

our enum AudioDevice is export (
	HEADPHONES => 1,
	HEADSET    => 1 +< 1,
	MICROPHONE => 1 +< 2
);

class Gnome::Shell::AudioDeviceSelectionDialog
	is   Gnome::Shell::UI::ModalDialog
	does Signaling[
		[ 'device-selected', [uint32] ]
	]
{
	has %!deviceItems;

	submethod BUILD ( :$devices ) {
		self.GLib::Roles::Object::BUILD;
		
		self.style-class = 'audio-device-selection-dialog';
		self.buildLayout;

		self.addDevice($_) if $device +& .value for AudioDevice.enums.pairs;

		X::Gnome::Shell::TooFewDevices.new.throw if $!selectionBox.elemens < 2;
	}

	method buildLayout {
		my $content = Gnome::Shell::Dialog::MessageDialogContent.new(
			title => 'Select Audio Device'
		);

		$!selectionBox = Gnome::Shell::St::BoxLayout.new(
			style-class => 'audio-selection-box',
			x-align     => CLUTTER_ACTOR_ALIGN_CENTER,
			x-expand    => True
		);
		$content.add-child($!selectionBox);

		if Main.sessionMode.allowSettings {
			self.addButton(
				action => -> *@a { self.openSettings( |@a ) },
				label  => 'Sound Settings'
			);
		}
		self.addButton(
			action => -> *@a { self.close },
			label  => 'Cancel',
			key    => CLUTTER_KEY_Escape,
		)
	}

	method getDeviceString ($_, @strings) {
		when    HEADPHONES { @strings[0] }
		when    HEADSET    { @strings[1] }
		when    MICROPHONE { @strings[2] }
		default            { ''          }
	}

	method getDeviceLabel ($device) {
		self.getDeviceString($device, <Headphones Headset Microphone>);
	}

	method getDeviceIcon ($device) {
		self.getDeviceString(
			$device,
			<headphones headset input-microphone>.map("audio-{$_}-symbolic")
		);
	}

	method addDevice ($device) {
		my $box = Gnome::Shell::St::BoxLayout.new(
			style-class => 'audio-selection-device-box',
			vertical    => True
		);
		$box.notify('height').tap(-> *@a {
			Mutter::Meta::Later.add(META_LATER_BEFORE_REDRAW, -> *@a {
				$box.width = $box.height;
				GLIB_SOURCE_REMOVE
			})
		});

		my $icon = Gnome::Shell::St::Icon.new(
			style-class => 'audio-selection-device-icon',
			icon-name   =>  self.getDeviceIcon($device)
		);
		$box.add($icon);

		my $label = Gnome::Shell::St::Label.new(
			style-class => 'audio-selection-device-label',
			label       => self.getDeviceLabel($device),
			x-align     => CLUTTER_ACTOR_ALIGN_CENTER
		);
		$box.add($label);

		my $button = Gnome::Shell::St::Button.new(
			style-class => 'audio-selection-device',
			can-focus   => True,
			child       => $box
		);
		$!selectionBox.add($button);

		$button.clicked.tap( -> *@a {
			self.emit('device-selected', $device);
			self.close;
			UI<overview>.hide
		});
	}

	method openSettings {
		my $desktopFile = 'gnome-sound-panel.desktop';
		my $app         = Gnome::Shell::AppSystem.get-default.lookup-app(
			$desktopFile
		);

		unless $app {
			$*ERR.say: "Settings panel for desktop file {
				          $desktopFile } could not be loaded!";
			return;
		}

		self.close;
		UI<overview>.hide;
		$app.activate;
	}

}
