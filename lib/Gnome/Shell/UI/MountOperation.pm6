use v6.c;

use Gnome::Shell::Raw::Types;

use Gnome::Shell::Misc::FileUtils
use Gnome::Shell::Misc::Utils;
use Gnome::Shell::UI::Animation;
use Gnome::Shell::UI::CheckBox;
use Gnome::Shell::UI::Dialog;
use Gnome::Shell::UI::Main;
use Gnome::Shell::UI::MessageTray;
use Gnome::Shell::UI::ModalDialog;
use Gnome::Shell::UI::ShellEntry;

constant LIST_ITEM_ICON_SIZE          is export = 48;
constant WORK_SPINNER_ICON_SIZE       is export = 16;
constant REMEMBER_MOUNT_PASSWORD_KEY  is export = 'remember-mount-password';

sub setButtonForChoices ($dialog, $oldChoices, $choices) {
	my @buttons;
	my $buttonsChanged = $oldChoices.elems != $choices.elems;

	for $choices.kv {
		$buttonsChanged ||= $oldChoices[ .key ] !== $choices[ .key ];

		my $button = .key;
		$buttons.unshift: {
			label  => .value,
			action => -> *@a { $dialog.emit('response', $button) }
		);
	}

	$dialog.setButtons($buttons) if $buttonsChanged;
}

sub setLabelsForMessage ($content, $message) {
	my @labels = $message.lines;

	$content.title       = @labels.shift;
	$content.description = @labels.join('\n');
}

class Gnome::Shell::UI::MountOperation {
	has $!dialog;
	has $!processesDialog;
	has $!existingDialog   is built;
	has $.mountOp;

	submethod BUILD ( :$!existingDialog ) {
		$!mountOp = Gnome::Shell::MountOperation.new;

		my $s = self;
		$!mountOp.connectMultiple(
			         'ask-question', -> *@a { $s.onAskQuestion(         |@a ) },
			         'ask-password', -> *@a { $s.onAskPassword(         |@a ) },
			     'show-processes-2', -> *@a { $s.onShowProcesses2(      |@a ) },
			              'aborted', -> *@a { $s.close(                 |@a ) },
		  'show-unmount-progress', -> *@a { $s.onShowUnmountProgress( |@a ) }
		);
	}

	method closeExistingDialog {
		return unless $!existingDialog;

		$!existingDialog.close;
		$!existingDialog = Nil;
	}

	method onAskQuestion ( *@a ($, $message, $choices) ) {
		self.closeExistingDialog;

		$!dialog = Gnome::Shell::MountOperation::QuestionDialog.new;
		$!dialog.response.tap(-> *@a ($, $choice) {
			$!mountOp.set-choice($choice);
			$!mountOp.reply(G_MOUNT_OPERATION_HANDLED);
			self.close;
		});
		$!dialog.update($message, $choices);
		$!dialog.open;
	}

	method onAskPassword ( *@a ($, $message, $, $, $flags) ) {
		if $!existingDialog {
			$!dialog = $!existingDialog;
			$!dialog.reaskPassword;
		} else {
			$!dialog = Gnome::Shell::MountOperation::PasswordDialog.new(
				$message, 
				$flags
			);
		}

		$!dialog.response.tap( 
			-> *@a ( $, $choice, $password, $remember, $hiddenV, $systemV, $pim) {
				if $choice == -1 {
					$!mountOp.reply(G_MOUNT_OPERATION_ABORTED);
				} else {
					$!mountOp.set_password_save(
						$remember ?? G_PASSWORD_SAVE_PERMANENTLY 
						          !! G_PASSWORD_SAVE_NEVER
				  );

				  given $!mountOp {
				  	.set-password($password), 
				  	.set-is-tcrypt-hidden-volume($hiddenVolume),
				  	.set-is-tcrypt-system-volume($systemVolume),
				  	.set-pim($pim),
				  	.reply(G_MOUNT_OPERATION_HANDLED);
				  }
				}
			}
		);
		$!dialog.open;
	}

	method close ( *@a ) {
		self.closeExistingDialog;
		$!processesDialog = Nil;

		if $!dialog {
			$!dialog.close;
			$!dialog = Nil;
		}

		if $!notifier {
			$!notifier.done;
			$!notifier = Nil;
		}
	}

	method onShowProcesses2 ($op) {
		self.closeExistingDialog;

		my $message   = $!mountOp.get-show-processes-message;
		my $processes = $!mountOp.get-show-processes-pids;
		my $choices   = $!mountOp.get-show-processes-choices;
		
		unless $!processesDialog {
			$!dialog = $!processesDialog = 
				Gnome::Shell::MountOperation::ProcessesDialog;

			my $s = self;
			$!processesDialog.response.tap( -> *@a ($, $choice) {
				if $choice == -1 {
					$!mountOp.reply(G_MOUNTED_OPERATION_ABORTED);
				} else {
					$!mountOp.set-choice($choice);
					$!mountOp.reply(G_MOUNTED_OPERATION_HANDLED);
				}
				$s.close;
			});

			$!processDialog.open;
		}
		
		$!processDialog.update($message, $processes, $choices);	
	}

	method onShowUnmountProgress ($, $message, $, $bytesLeft) {
		$!notifier //= Gnome::Shell::MountOperation::UnmountNotifier.new;
		
		$bytesLeft ?? $!notifier.show($message) !! $!notifier.done($message);
	}

	method borrowDialog {
		.disconnectObject(self) with $!dialog;
		$!dialog;
	}

}

class Gnome::Shell::UI::MountOperation::UnmountNotifier {
	is Gnome::Shell::UI::MessageTray::Source
{
	has $!notification;

	submethod BUILD {
		( .title, .iconName ) = ('', 'media-removable') given self;

		UI<messageTray.add(self);
	}	

	method show ($message) {
		my ($header, $text) = $message.split(',')[^2];

		if $!notification.not {
			$!notification = Gnome::Shell::UI::MessageTray::Notification.new(
				self,
				$header,
				$text
			);
			.setTransient(True), .setUrgency(MESSAGE_TRAY_URGENCY_CRITICAL) 
				given $!notifification;
		} else {
			$notification.update($header, $text);
		}

		self.showNotification($!notification);
	}

	method done ($message) {
		if $!notification {
			$!notification.destroy;
			$!notification = Nil;
		}

		if $message {
			$!notification = Gnome::Shell::UI::MessageTray::Notification.new(
				self,
				$message
			);
			$!notification.setTransiet(True);
			self.showNotification($!notification);
		}
	}

}

class Gnome::Shell::UI::MountOperation::QuestionDialog
	is   Gnome::Shell::UI::ModalDialog
	does Signalling[
		[ 'response', [gint] ]
	]
{
	has @!oldChoices;
	has $!content;

	submethod BUILD {
		self.style-class = 'mount-question-dialog';
		$!content = Gnome::Shell::UI::Dialog::MessageDialogContent.new;
		self.contentLayout.add-child($!content);
	}

	method key-release-event is vfunc ($event) {
		if $event.keyval == CLUTTER_KEY_Escape {
			self.emit('response', -1);
			return CLUTTER_EVENT_STOP;
		}
		CLUTTER_EVENT_PROPAGATE;
	}

	method update ($message, $choices) {
		setLabelsForMessage($!content, $message);
		setButtonsForChoices(self, $!oldChoices, $choices);
		$!oldChoices = $choices;
	}

}

my $disksApp;
class Gnome::Shell::UI::MountOperation::PasswordDialog 
	is   Gnome::Shell::UI::ModalDialog
	does Signalling[
		[ 'response', [gint, Str, guint32, guint32, guint32] ]
	]
{

	submethod BUILD ( :$message, :$flags ) {
		my ($s, $title, $description) = self, |$message.lines[^2];

		$disksApp = Gnome::Shell::AppSystem.get-default.lookup-app(
			'org.gnome.DiskUtility.desktop'
		);

		my $content = Gnome::Shell::UI::MessageDialogContent.new(
			:$title,
			:$description
		);

		my $passwordGridLayouyt = Mutter::Clutter::GridLayout.new(
			orientation => CLUTTER_ORIENTATION_VERTICAL
		);

		my $passwordGrid = Gnome::Shell::ST::Widget.new(
			style-class    => 'prompt-dialog-password-grid',
			layout-manager => $passwordGridLayout
		);
		$passwordGridLayout.hookup-style($passwordGrid);

		my $rtl = $passwordGrid.get-text-direction == CLUTTER_TEXT_DIRECTION_RTL;

		my $curGridRow = 0;

		if $flags +& G_ASK_PASSWORD_TCRYPT {
			$!hiddenVolume = Gnome::Shell::UI::CheckBox.new('Hidden Volume');
			$!systemVolume = Gnome::Shell::UI::CheckBox.new(
				'Windows System Volume'
			);
			$!keyfilesCheckbox = Gnome::Shell::UI::CheckBox.new('Uses Keyfiles');
			$keyfilesCheckbox.clicked.tap( -> *@a {
				$s.onKeyfilesCheckboixClicked( |@a );
			}

			$!keyFilesLabel = Gnome::Shell::St::Label.new( visible => False );
			$!keyFilesLabel.clutter-text.set-markup( qq:to/MARK/.chomp );
				To unlock a volume that uses keyfiles, use the <i>{ 
				$disksApp.get-name }</i> utility instead.
				MARK
			( .ellipsize, .line-wrap ) = (PANGO_ELLIPSIZE_NONE, True)
				given $keyFilesLabel.clutter-text;

			$content.add-child($_) for $!hiddenVolume,     $!systemVolume, 
				                         $!keyfilesCheckbox, $!keyfilesLabel;

		  $!pimEntry = Gnome::Shell::St::PasswordEntry.new(
		  	style-class => 'prompt-dialog-password-entry',
		  	hint-text   => 'PIM Number',
		  	can-focus   => True,
		  	x-expand    => True
		  );
		  $!pimEntry.activate.tap( -> *@a { $s.onEntryActivate( |@a ) });
		  addContextMenu($!pimEntry);

			$passwordGridLayout.attach(
				$!pimEntry, 
				$rtl ?? 1 !! 0, 
				$curGridRow++,
				1,
				1
			);
		}

		$!passwordEntry = Gnome::Shell::St::PasswordEntry.new(
			style-class => 'prompt-dialog-password-entry',
			hint-text   => 'Password',
			can-focus   => True,
			x-expand    => True
		);
		$!passwordEntry.clutter-text.activate.tap( -> *@a {
			$s.onEntryActivate( |@a )
		});
		self.setInitialKeyFocus($!passwordEntry);
		addContextMenu($!passwordEntry);

		$!workSpinner = Gnome::Shell::UI::Animation::Spinner.new(
			WORK_SPINNER_ICON_SIZE,

			animate => True
		);

		$passwordGridLayout.attach(.value, .key, $curGridRow++, 1, 1)
			for ($rtl ?? ($!workSpinner, $!passwordEntry)
						    !! ($!passwordEntry, $!workSpinner) ).pairs;

		my $warningBox = Gnome::Shell::St::BoxLayout.new( vertical => True );

		my $capsLockWarning = Gnome::Shell::UI::ShellEntry::CapsLockWarning.new;

		$!errorMessageLabel = Gnome::Shell::St::Label.new(
			style-class => 'prompt-dialog-error-label',
			opacity     => 0
		);
		( .ellipsize, .line-wrap ) = (PANGO_ELLIPSIZE_NONE, True)
			given $!errorMessageLabel.clutter-text;
		$warningBox.add-child($_) for $capsLockWarning, $!errorMessageLabel;

		$passwordGridLayout.attach($warningBox, 0, $curGridRow, 2, 1);
		$content.add-child($passwordGrid);

		if $flags +& G_ASK_PASSWORD_SAVING_SUPPORTED {
			$!rememberChoice = Gnome::Shell::UI::CheckBox.new('Remember Password');
			$!rememberChoice.checked = Global.settings.get-boolean(
				REMEMBER_MOUNT_PASSWORD_KEY
			);
			self.content.add-child($!rememberChoice);
		}	else {
			$!rememberChoice = Nil;
		}

		self.contentLayout.add-child($content);

		@!defaultButtons = [
			{
				label  => 'Cancel',
				action => -> *@a { $s.onCancelButton( |@a ) },
				key    => CLUTTER_KEY_Escape
			},

			{
				label   => 'Unlock',
				action  => -> *@a { $s.onUnlockButton( |@a ) },
				default => True
			}
		];

		$!usesKeyfilesButtons = [
			{
				label  => 'Cancel',
				action => -> *@a { $s.onCancelButton( |@a ) },
				key    => CLUTTER_KEY_Escape
			},

			{
				label   => "Open { $disksApp.get-name }",
				action  => -> *@a { $s.onOpenDisksButton( |@a ) },
				default => True
			}
		];

		self.setButtons($!defaultButtons);
	}
		
	method new ($message, $flags) {
		self.bless( :$message, :$flags, :$styleClass = 'prompt-dialog' );
	}

	method reaskPassword {
		$!workSpinner.stop;

		$!passwordEntry.text     = '';
		$!errorMessageLabel.text = 'Sorry, that didn't work. Please try again.';

		$!errorMessageLabel.opacity = 255;
	}

	method onCancelButton {
		self.emit('response', -1, '', False, False, False, 0);
	}

	method onUnlockButton {
		self.onEntryActivate;
	}

	method onEntryActivate {
		my $pim = 0;
		if $!pimEntry {
			$pim = $!pimEntry.text;

			if $pim.Int ~~ Failure {
				$!pimEntry.text = '';
				( .text, .opacity ) = ('The PIM must be a number or empty', 255) 
					given $!errorMessageLabel;
				return;
			}

			$!errorMessageLabel.opacity = 0;
		}

		Global.settings.set-boolean(
			REMEMBER_MOUNT_PASSWORD_KEY,
			$!rememberChoice && $!rememberChoice.checked
		);

		$!workSpinner.play;
		self.emit(
			'response',
			1,
			$!rememberChoice && $!rememberChoice.checked,
			$!hiddenVolume   && $!hiddenVolume.checked,
			$!systemVolume   && $!systemVolume.checked,
			$!pim.Int
		);
	}

	method onKeyfilesCheckboxClicked {
		my $ukf = $!keyfilesCheckbox.checked;

		.reactive = .can-focus = $ukf.not 
			for $!passwordEntry, $!pimEntry, $!rememberChoice;

		$!keyfilesLabel.visible = $ukf;

		self.setButtons($ukf ?? @!usesKeyfilesButtons !! @!defaultButtons);
	}

	method onOpenDisksButton {
		$disksApp 
			?? $disksApp.activate
		  !! notifyError(
           "Unable to start { $disksApp.get-name }",
           "Couldn't find the { $disksApp.get-name } application"
         );
  }
}

class Gnome::Shell::UI::MountOperation::ProcessesDialog 
	is   Gnome::Shell::UI::ModalDialog
	does Signalling[
		[ 'response', [gint] ]
	]
{ 
	has @!oldChoices;
	has $!applicationSection;
	has $!content;

	submethod BUILD {
		self.style-class = 'processes-dialog';notification
		$!content = Gnome::Shell::UI::Dialog::MessageDialogContent.new;
		$!applicationSection = Gnome::Shell::UI::Dialog::ListSection.new;
		self.contentLayout.add-child($_) for $!content, $!applicationSection;
	}

	method key-release-event ($event) is vfunc {
		if $event.keyval == CLUTTER_KEY_Escape {
			self.emit('response', -1);
			return CLUTTER_EVENT_STOP;
		}
		CLUTTER_EVENT_PROPAGATE
	}

	method setAppsForPids ($pids) {
		$!applicationSection.list.destroy-all-children;

		my $tracker = Gnome::Shell::WindowTracker.get-default;
		for $pids[] {
			return unless ( my $app = $trafcker.get-app-from-pid($_) );

			my $listItem = Gnome::Shell::Dialog::ListSectionItem.new(
				icon-actor => $app.create-icon-texture(LIST_ITEM_ICON_SIZE),
				title      => $app.get-name
			);
			$!applicationSection.list.add-child($listItem);
		}

		$!applicationSection.visible = $!applicationSection.list.elems.so;
	}

	method update ($message, $processes, $choices) {
		self.setAppsForPids($processes);
		setLabelsForMessage($!content, $message);
		setButtonsForChoices(self, $!oldChoices, $choices);
		$!oldChoices = $choices;
	}
}

our $GnomeShellMountOpIface = loadInterfaceXML('org.Gtk.MountOperationHandler');

our enum MountOperationType is export <
	NONE 
	ASK_PASSWORD 
	ASK_QUESTION 
	SHOW_PROCESSES
>;

class Gnome::Shell::MountOperation::Handler {

	has $!currentId;
	has $!currentInvocation;
	has $!currentType;
	has $!dbusImpl;
	has $!dialog;

	submethod BUILD {
		$!dbusImpl = GIO::DBus::ExportedObject.wrapRakuObject(
			$GnomeShellMountOpIface,
			self
		);

		$dbusImpl.export(
			GIO::DBus::Connection.session, 
			'/org/gtk/MountOperationHandler'
		);
		GIO::DBus::Connection.session.bus_own_name_on_connection(
			'org.gtk.mountOperationHandler',
			G_BUS_NAME_OWNER_REPLACE
		);

		self.ensureEmptyRequest;
	}

	method ensureEmptyRequest {
		$!currentId  = $!currentInvocation = Nil;
		$!currenType = NONE;
	}

	method clearCurrentRequest ($response, $details) {
		if $!currentInvocation {
			$!currentInvocation.return-value(
				GLib::Variant.new('(ua{sv}', [$response, $details]
			);
		}

		self.ensureEmptyRequest
	}

	method setCurrentRequest ($invocation, $id, $type) {
		my ($oldId, $oldType) = ($!currentId, $!currentType);
		my  $requestId        = "{ $id }\@{ $invocation.get-sender }";

		self.clearCurrentRequest(G_MOUNT_OPERATION_UNHANDLED, {});

		$!currentInvocation = $invocation;
		$!currentId         = $requestId;
		$!currentType       = $type;

		$!dialog && ($oldId == $requestId) && ($oldType == $type);
	}

	method closeDialog {
		if $!dialog {
			$!dialog.close;
			$!dialog = Nil;
		}
	}

	# ... 589 AskPassword





