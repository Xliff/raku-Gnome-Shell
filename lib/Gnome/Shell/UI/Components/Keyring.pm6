use v6.c;

use Gnome::Shell::UI::Dialog;
use Gnome::Shell::UI::ModalDialog;
use Gnome::Shell::UI::ShellEntry;
use Gnome::Shell::UI::CheckBox;
use Gnome::Shell::Misc:Util;

class Gnome::Shell::UI::Components::Keyring::Dialog 
	is Gnome::Shell::UI::ModalDialog
{
	has $!passwordEntry;
	has $!confirmEntry;
	has $!continueButton;
	has $.prompt;

	submethod BUILD {
		self.style-class = 'prompt-dialog';

		my $content;
		given ( self.prompt = Gnome::Shell::KeyringPrompt.new ) {
			.prompt.show-password.tap( -> *@a {	
				self.ensureOpen;
				self.updateSensitivity(True);
				$!passwordEntry.text = '';
				$!passwordEntry.grab-key-focus;
			})

			.prompt.show-confirm.tap( -> *@a {
				self.ensureOpen;
				self.updateSensitivity(True);
				$!confirmEntry.text = '';
				$!continueButton.grab-key-focus
			});

			.prompt.prompt-close.tap( -> *@a {
				self.close
			});
		}

		my $content = Gnome::Shell::UI::Dialog::MessageDialogContent.new;
		self.prompt.bind('message', $content, 'title', :create);
		self.prompt.bind('description', $content, :create);
		
		my $passwordBox = Gnome::Shell::St::BoxLayout.new(
			style-class => 'prompt-dialog-password-layout',
			vertical    => True
		);
		
		$!passwordEntry = Gnome::Shell::St::PasswordEntry.new(
			style-class => 'prompt-dialog-password-entry',
			can-focus   => True,
			x-align     => CLUTTER_ACTOR_ALIGN_CENTER
		);
		$!passwordEntry.clutter-text.activate.tap( -> *@a {
			$!prompt.confirm-visible ?? $!confirmEntry.grab-key-focus
			                         !! self.onContinueButton;
		});
		self.bind('password-visible', 
			$!passwordEntry.grab-key-focus,
			'visible',
			:create
		);

		addContextMenu($!passwordEntry);
		$passwordBox.add-child($!passwordEntry);

		$!confirmEntry = Gnome::Shell::St::PasswordEntry.new(
			style-class => 'prompt-dialog-password-entry',
			can-focus   => True,
			x-align     => CLUTTER_ACTOR_ALIGN_CENTER
		);
		addContextMenu($!confirmEntry);
		self.bind('confirm-visible', $!confirmEntry, 'visible', :create);
		$passwordBox.add-child($!confirmEntry);

		$!prompt.set-password-actor($!passwordEntry.clutter-text);
		$!prompt.set-confirm-actor($!confirmEntry.clutter-text);

		my $warningBox = Gnome::Shell::St::BoxLayout.new( :vertical );

		my $capsLockWarning = Gnome::Shell::UI::ShellEntry::CapsLockWarning.new;
		my &sclwVisibility  = -> { 
			$capsLockWarning.visible = .password-visible || .confirm-visible 
				given $!prompt
		};
		$!prompt.notify('password-visible').tap( -> *@a { &sclwVisibility() });
		$!prompt.notify('confirm-visible').tap(  -> *@a { &sclwVisibility() });
		$warningBox.add-child($capsLockWarning);

		my $warning = Gnome::Shjell::St::Label.new(
			style-class => 'prompt-dialog-error-label'
		);
		( .ellipsize, .line-wrap ) = (PANGO_ELLIPSIZE_MODE_NONME, True) 
			given $warning.clutter-text;
		$!prompt.bind('warning', $warning, 'text', G_BINDING_SYNC_CREATE);
		$!prompt.notify('warning-visible').tap( -> *@a { 
			$warning.opacity = $!prompt.warning-visible ?? 255 !! 0
		);
		$!prompt.notify('warning').tap( -> *@a {
			wiggle($!passwordEntry) if $!passwordEntry && $!prompt.warning ne '';
		});
		
		$warningBox.add-child($warning);
		$passwordBox.add-child($warningBox);
		$content.add-child($passwordBox);

		my $!choice = Gnome::Shell::UI::CheckBox.new;

		given $!prompt {
			.bind('choice-label', $!choice.getLabelActor, 'text', :create);
			.bind('choice-chosen', $!choice, 'checked', :create, :dual);
			.bind('choice-visible', $!choice, 'visible', :create);			
		}
		$content.add-child($!choice);

		self.contentLayout.add-child($content);

		$!cancelButton = self.addButton(
			label  => '',
			action => -> *@a { self.onCancelButton },
			key    => CLUTTER_KEY_ESCAPE
		);
		!$continueButton = self.addButton(
			label   => '',
			action  => -> *@a { self.onContinueButton },
			default => True
		);

		$!prompt.bind('cancel-label', $!cancelButton, 'label', :create);
		$!prompt.bind('continue-label', $!continueButton, 'label', :create);
	}

	method updateSensitivity ($sensitive) {
		.reactive = $sensitive if $_ for $!passwordEntry, $!confirmEntry;
		( .can-focus, .reactive ) = $sensitive xx 2 given $!continueButton;
	}

	method ensureOpen {
		return if self.open;

		$*ERR.say: 'keyringPrompt: Failed to show modal dialog.' 
		           ' Dismissing prompt request';
		$!prompt.cancel;
		False;
	}

	method onContinueButton {
		self.updateSensitivity(False);
		$!prompt.complete;
	}

	method onCancelButton {
		$!prompt.cancel;
	}

}

class Gnome::Shell::UI::Keyring::DummyDialog {
	has $.prompt;

	submethod BUILD {
		$!prompt = Gnome::Shell::UI::Components::KeyringPrompt.new;
		$!prompt.show-password.tap( -> *@a { self.cancelPrompt });
		$!prompt.show-confirm.tap(  -> *@a { self.cancelPrompt });
	}

	method cancelPrompt { $!prompt.cancel }
}

class Gnome::Shell::UI::Keyring::Prompter 
  is GCR::SystemPrompter
{
  has $!currentPrompt;
  has $!dbusId;
  has $!enabled;
  has $!registered;

  submethod BUILD {
    self.new-prompt.tap( -> *@a {
      my $dialog = (
        $!enabled ?? Gnome::Shell::Keyring::Dialog
                  !! Gnome::Shell::Keyring::DummyDialog
      ).new;
      @a.tail.r = $!currentPrompt = $dialog.prompt;
    });
  }

  method enable {
    unless $!registered {
      self.register(GIO::DBus::Connection.session);
      $!dbusId = GIO::DBus::Connection.session.own_name(
        'org.gnome.keyring.SystemPrompter',
        G_BUS_NAME_OWNER_ALLOW_REPLACEMENT
      );
      $!registered = True;
    }
    $!enabled = True;
  }

  method disable {
    $!enabled = False;
    $!currentPrompt.cancel if self.prompting ;
    $!currentPrompt = Nil;
  }

}



