use v6.c;

use Gnome::Shell::St::Bin;

my \TC;

class Gnome::Shell::UI::UserWidgets::Avatar is Gnome::Shell::St::Bin {
	has $!iconSize;
	has $!user;

	submethod BUILD ( :$user, :$params ) {
		my %params = mergeHash(
			$params, 
			styleClass => user-icon,
			reactive   => False,
			iconSize   => AVATAR_ICON_SIZE
		);

		( .style-class, .reactive ) = %params<styleClass reactive> given self;

		self.bind_property(
			'reactive', 
			self, 
			'track-hover', 
			G_BINDING_SYNC_CREATE
		);

		self.bind_property(
			'reactive',
			self,
			'can-focus',
			G_BINDING_SYNC_CREATE
		);

	 	TC = Gnome::Shell::St.ThemeContext.get-for-stage(Global.stage);

		TC.notify('scale-factor').tap( -> *@a {
			self.update( |@a );
		})
	}

	method style-changed is vfunc {
		callsame;

		my  $node              = self.get-theme-node;
		my ($found, $iconSize) = $node.lookup-length('icon-size');
		return unless $found;

		$!iconSize = $iconSize * TC.scaleFactor ** -1;
		self.update;
	}

	method setSensitive ($sensitive) {
		self.reactive = $sensitive;
	}

	method update {
		my $iconFile;

		if $!user {
			$iconFile = $!user.get-icon-file;
			$iconFile = Nil unless $iconFile && $!iconFile.IO.e;
		}

		my $scaleFactor = TC.scale-factor;
		self.set-size($!iconSize * $scaleFactor, $!iconSize * $scaleFactor);

		if $iconFile {
			$!child = Nil;
			self.add-style-class-name('user-avatar');
			self.style = qq:to/STYLE/
				background-image: url("{ $iconFile }");
				background-size: cover;
				STYLE
			} else {
				self.style = Nil;
				$!child = Gnome::Shell::St::Icon.new(
					icon-name => 'avatar-default-symbolic',
					icon-size => $!iconSize
				);
			}
		}
	}

}

class Gnome::Shell::UI::UserWidget::Label is Gnome::Shell::St::Widget {

	has $!user           is built;
	has $!currentLabel;
	has $!realNameLabel;
	has $!userNameLabel;

	submethod BUILD ( :$!user )
		self.layout-manager = Mutter::Clutter::BinLayout.new;

		$!realNameLabel = Gnome::Shell::St::Label.new(
			style-class => 'user-widget-label',
			y-align     => CLUTTER_ACTOR_ALIGN_CENTER,
		);
		self.add-child($!userNameLabel);

		$!user.notify('is-loaded').tap( -> *@a { self.updateUser });
		$!user.changed.tap(             -> *@a { self.updateUser });
		self.updateUser;
	}

	method allocate ($box) is vfunc {
		self.set-allocation($box);

		my $availWidth  = $box.x2 - $box.x1;
		my $availHeight = $box.y2 - $box.y1;

		my $natRealNameWidth = $!realNameLabel.get-preferred-size.tail;
		my $childBox         = Mutter::Clutter::ActorBox.new;

		my $hiddenLabel = do if $natRealNameWidth <= $availWidth {
			$!currentLabel = $realNameLabel;
			$!userNameLabel
		} else {
			$!currentLabel = $!userNameLabel;
			$!realNameLabel;
		}
		self.label-actor = $!currentLabel;
		$hiddenLabel.allocate($childBox);
		$childBox.set-size($availWidth, $availHeight);
		$!currentLabel.allocate($childBox)
	}

	method paint ($paintContext) is vfunc {
		$!currentLabel.paint($paintContext);
	}

	method updateUser {
		$!realNameUserLabel.text = $!user.is-loaded ?? $!user.get-real-name !! '';
		$!userNameLabel.text     = $!user.is-loaded ?? $!user.get-user-name !! '';
	}

}

class Gnome::Shell::UI::UserWidget is Gnome::Shell::St::BoxLayout {

	has $!user           is built;
	has $!label;
	has $!avatar;
	has $!userLoadedId;
	has $!userChangedId;

	submethod BUILD ( :$!user ) {
		my ($vertical, $orientation) = CLUTTER_ORIENTATION_VERTICAL xx 2;

		my  $xAlign = $vertical ?? CLUTTER_ACTOR_ALIGN_CENTER 
		                        !! CLUTTER_ACTOR_ALIGN_START;

		my $styleClass = 'user-widget ' ~ $vertical ?? 'vertical' !! 'horizontal';

		( .style-class,  .vertial, .x-align ) = ($styleClass, $vertical, $xAlign)
			given self;

		if $user {
			$!label = Gnome::Shell::UserWidget::Label.new($!user);
			self.add-child($!label);

			$!label.bind_property(
				'label-actor', 
				self, 
				'label-actor',
				G_BINDING_SYNC_CREATE
			);

			$!user.notify('is-loaded').tap( -> *@a { self.updateUser });
			$!user.changed.tap(             -> *@a { self.updateUser });
		} else {
			self.add-child(
				$!label = Gnome::Shell::St::Label.new(
					style-class => 'user-widget-label',
					text        => 'Empty User',
					opacity     => 0
				)
			);
		}

		self.updateUser;
	}

	method updateUser {
		$!avatar.update;
	}

}
