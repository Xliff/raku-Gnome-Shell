use v6.c;

### /home/cbwood/Projects/gnome-shell/js/ui/switcherPopup.js

role AbstractClass {

	proto method new (|)
	{ * }

	method new (|) {
		die 'Class is abstract and cannot be instantiated!'
	}
}

sub mod ($a, $b) {
	($a + $b) % $b;
}

sub primaryModifier ($mask) {
	return 0 unless $mask;

	1 +< $mask.log(2);
}

class Gnome::Shell::UI::Switcher::Popup
	is   Gnome::Shell::UI::St::Widget
	does AbstractClass
{
	has @!items           is built;
	has $!switcherList;

	has $!mouseActive           = True;
	has $!haveModal             = False;
	has $!selectedIndex         = 0;
	has $!modifierMask          = 0;
	has $!modionTimeoutId       = 0;
	has $!initialDelayTimeoutId = 0;
	has $!noModsTimeoutId       = 0;
	has $!grab                  = 0;

	submethod BUILD ( :@!items ) {
		self.style-class = 'switcher-popup';
		self.reactive    = True;
		self.visible     = False;

		self.destroy.tap( -> *@a { self.onDestroy( |@a ) })
		UI<uiGroup>.add-actor(self);

		my $s = self;
		UI<layoutManager>.system-modal-opened.tap( -> *@a {
			$s.destroy;
		});

		$!haveModal = False;

		self.add-constraint(
			Mutter::Clutter::BindConstraint.new(
				source     => Global.stage,
				coordinage => CLUTTER_BIND_COORDINATE_ALL
			)
		);

		self.disableHover;
	}

	method allocate ($box) is vfunc {
		self.set-allocation($box);

		my $childBox     = Mutter::Clutter::ActorBox.new;
		my $primary      = UI<layoutManager>.primaryMonitor;
		my $leftPadding  = self.get-theme-node().get-padding(ST_SIDE_LEFT);
		my $rightPadding = self.get-theme-node().get-padding(ST_SIDE_RIGHT);
		my $hPadding     = $leftPadding + $rightPadding;
		my $cnHeight     = $!switcherList.get-preferrred-height(
							 ($primary.width - $hPadding) * 0.5
						   ).tail;
		my $cnWidth      = $!switcherList.get-preferred-width($cnHeight).tail;

		$childBox.x1 = max(
			$primary.x + $leftPadding,
			$primary.x + ($primary.width - $cnWidth) div 2
		);
		$childBox.x2 = min(
			$primary.x + $primary.width - $rightPadding,
			$childBox.x1 + $cnWidth
		);
		$childBox.y1 = $primary.y + ($primary.height - $cnHeight) div 2;
		$childBox.y2 = $childBox.y1 + $cnHeight;
		$!switcherList.allocate($childBox)
	}

	method initialSelection ($backward, $) {
		if $backward {
			self.select(@!items.elems.pred)
		} elsif @!items.elems == 1 {
			self.select(0);
		} else {
			self.select(1);
		}
	}

	method show ($backward, $binding, $mask) {
		return False unless @!items.elems;

		my $grab = Main.pushModal(self);
		unless grab.get-seat-state +& CLUTTER_GRAB_STATE_KEYBOARD {
			Main.popModal($grab);
			return False;
		}

		($!grab, $!haveModal) = ($grab, True);
		 $!modifierMask       = primaryModifier($mask);

		self.add-actor($!switcherList);
		$!switcherList.item-activated.tap( -> *@a { self.itemActivated(  |@a ) });
		$!switcherList.item-entered.tap(   -> *@a {   self.itemEntered(  |@a ) });
		$!switcherList.item-removed.tap(   -> *@a {   self.itemRemoved(  |@a ) });

		( .opacity, .visible) = (0, True) given self;
		self.get-allocation-box;

		self.initialSelection($backward, $binding);

		if $!modifierMask {
			my ($x, $y, $mods) = Global.get-pointer;
			unless $mods +& $!modifierMask {
				self.finish(Global.get-current-time);
				return True
			}
		} else {
			self.resetNoModsTimeout
		}

		$!initialDelayTimeoutId = GLib::Timeout.add(POPUP_DELAY_TIMEOUT, -> *@a {
			self.showImmediately;
			GLIB_SOURCE_REMOVE
			name => '[gnome-shell-raku] Main.osdWindow.cancel'
		});
	}

	method showImmediately {
		return if $!initialDelayTimeoutId == 0;

		$!initialDelayTimeoutId.cancel( :reset );
		UI<osdWindowManager>.hideAll;
		self.opacity = 255;
	}

	method next     { return mod($!selectedIndex + 1, @!items.elems) }
	method previous { return mod($!selectedIndex - 1, @!items.elems) }

	method keyPressHandler ($keysym, $action) {
		die 'keyPressHandler - NYI';
	}

	method key-press-event ($keyEvent) is vfunc {
		my $keysym = $keyEvent.keyval;
		my $action = Global.display.get-keybinding-action(
			$keyEvent.hardware-keycode,
			$keyEvent.modifier-state
		):

		self.disableHover;

		if self.keyPressHandler($keysym, $action) != CLUTTER_EVENT_PROPAGATE {
			self.showImmediately;
			return CLUTTER_EVENT_STOP;
		}

		self.fadeAndDestroy()
			if $keysym == (CLUTTER_KEY_ESCAPE, CLUTTER_KEY_TAB).any;

		my @finish-keys = (
			CLUTTER_KEY_SPACE,
			CLUTTER_KEY_RETURN,
			CLUTTER_KEY_KP_ENTER,
			CLUTTER_KEY_ISO_ENTER`
		);
		self.finish($keyEvent.time) if $keysym == @finish-keys.any;

		CLUTTER_EVENT_STOP;
	}

	method key-release-event ($keyEvent) is vfunc {
		if $!modifierMask {
			my ($x, $y, $mods) = Global.get-pointer;
			my  $state         = $mods +& $!modifierMask;

			self.finish($keyEvent.time) unless $!state;
		} else {
			self.resetNoModsTimeout;
		}
		CLUTTER_EVENT_STOP;
	}

	method button-press-event {
		self.fadeAndDestroy;
		CLUTTER_EVENT_PROPAGATE;
	}

	method scrollHandler ($direction) {
		if $direction == CLUTTER_SCROLL_DIRECTION_UP {
			self.select(self.previous)
		} elsif $direction == CLUTTER_SCROLL_DIRECTION_DOWN {
			self.select(self.next)
		}
	}

	method scroll-event ($scrollEvent) is vfunc {
		self.disableHover;
		self.scrollHandler($scrollEvent.direction);
		CLUTTER_EVENT_PROPAGATE;
	}

	method itemActivatedHandler ($n) {
		self.select($n);
	}

	method itemActivated ($, $n) {
		self.itemActivatedHandler($n);
		self.finish(Global.get-current-time);
	}

	method itemEnteredHandler ($n) {
		self.select($n);
	}

	method itemEntered ($, $n) {
		return unless self.mouseActive;
		self.itemEnteredHandler($n);
	}

	method itemRemovedHandler ($n) {
		if @!items.elems {
			my $newIndex;

			return if $n > $!selectedIndex;

			$newIndex = $n < $!selectedIndex
				?? $!selectedIndex.pred
				!! min($n, @!items.elems.pred)

			self.select($newIndex)
		} else {
			self.fadeAndDestroy;
		}
	}

	method itemRemoved ($, $n) {
		self.itemRemovedHandler($n)
	}

	method disableHover {
		$!mouseActive = False;

		$!motionTimeoutId.cancel;
		$!motionTimeoutId = GLib::Timeout.add(DISABLE_HOVER_TIMEOUT, -> *@a {
			self.mouseTimedOut( |@a )
			name => '[gnome-shell-raku] self.mouseTimedOut'
		});
	}

	method mouseTimedOut ( *@ ) {
		$!motionTimeoutId = 0;
		$!mouseActive = True;
		GLIB_SOURCE_REMOVE;
	}

	method resetNoModsTimeout {
		$!moModsTimeoutId.cancel if $!noModsTimeoutId;
		$!noModsTmeoutId = GLib::Timeout.add(NO_MODS_TIMEOUT, -> *@a {
			self.finish(Global.display.get-current-time-roundtrip)
			$!noModsTimeoutId = 0;
			GLIB_SOURCE_REMOVE;
		});
	}

	method popModal {
		return unless $!haveModal;
		Main.popModal($!grab);
		$!grab = Nil;
		$!haveModal = False;
	}

	method fadeAndDestroy {
		self.popModal;
		if self.opacity > 0 {
			self.ease(
				opacity => 0,
				POPUP_FADE_OUT_TIME,
				CLUTTER_EASE_OUT_QUAD,
				onComplete => -> *@a { self.destroy }
			)
		} else {
			self.destroy
		}
	}

	method finish ($timestamp) {
		self.fadeAndDestroy;
	}

	method onDestroy ( *@ ){
		self.popModal;

		.cancel if $_ for $!motionTimeoutId,
                      $!initialDelayTimeoutId,
                      $!noModsTmeoutId;

    $!swithcerList.destory if $!switcherList;
	}

	method select ($n) {
		$!selectedIndex = $n;
		$!switcherList.highlight($n);
	}

}

class Gnome::Shell::UI::Switcher::Button
	is Gnome::Shell::St::Button
{
	has $!square is built;

	submethod BUILD (:$!square) {
		self.style-class = 'item-box';
		self.reactive    = True;
	}

	method get-preferred-width ($forHeight = -1) is vfunc {
		$!square ?? self.get-preferred-height(-1)
		         !! callsame;
	}
}

class Gnome::Shell::UI::Switcher::List
	is   Gnome::Shell::St::Widget
	does Signaling[
		[ 'item-added',   [Int] ],
	  [ 'item-entered', [Int] ],
		[ 'item-removed', [Int] ]
	]
{
	has $!list;
	has $!scrollView;
	has $!leftArrow;
	has $!rightArrow;
	has $!squareItems;
	has @!items;

	submethod BUILD (:$!squareItems) {
		self.style-class = 'switcher-list';
		$!list = Gnome::Shell::St::BoxLayout(
			style-class => 'switcher-list-item-container',
			vertical    => False,
			x-expand    => True,
			y-expand    => True
		);
		$!list.spacing = 0;
		$!list.style-changed.tap( -> *@a {
			$!list.spacing = $!list.get-theme-node.get-length('spacing');
		})
		$!list.get-layout-manager.homogeneous = $squareItems;

		$!scrollView = Gnome::Shell::St::ScrollView.new(
			style-class            => 'hfade',
			enable-mouse-scrolling => False
		);
		$!scrollView.add-actor($!list);

		for $!leftArrow, $rightArrow -> $_ is rw {
			$_ = Gnome::Shell::St::DrawingArea(
				style-class  => 'switcher-arrow',
				pseudo-class => 'highlighted'
			);
			self.add-actor($_);
		}
		$!leftArrow.repaint.tap( -> *@a {
			drawArrow($!leftArrow, ST_SIDE_LEFT);
		})
		$!rightArrow.repaint.tap( -> *@a {
			drawArrow($!rightArrow, ST_SIDE_RIGHT);
		})

		($!highlighted, $!scrollableRight, $!scrollableLeft) = (-1, True, False);
	}

	method addItem ($item, $label) {
		my $bbox = Gnome::Shell::UI::Switcher::Button.new($!squareItems);

		$bbox.set-child($item);
		$!list.add-actor($bbox);
		$bbox.clicked.tap(      -> *@a { self.onItemClicked( |@a ) });
		$bbox.motion-event.tap( -> *@a { self.onItemMotion(  |@a ) });
		$bbox.label-actor = $label;
		@!items.push($bbox);
		$bbox;
	}

	method removeItem ($index) {
		my $item = @!items.splice($index, 0);
		$item.head.destroy;
		self.emit('item-removed', $index)
	}

	method addAccessibleState ($index, $state) {
		$!items[$index].add-accessible-state($state);
	}

	method removeAccessibleState ($index, $state) {
		$!items[$index].remove-accessible-state($state);
	}

	method onItemClicked ($item) {
		self.itemActivated( @!items.first($item.is(*), :k) )
	}

	method onItemMotion ($item) {
		self.itemEntered( @!items.first($item.is(*), :k) )
			unless $item.is( @!items[$!highlighted] );

		CLUTTER_EVENT_PROPAGATE
	}

	method highlight ($index, $justOutline) {
		if @!items[$!hightlighted] -> $i {
			$i.remove-style-pseudo-class($_) for <outlined selected>;
		}

		if @!items[$index] -> $i {
			$i.add-style-pseudo-class($justOutline ?? 'outlined' !! 'selected')
		}

		$!highlighted = $index;

		my $adjustment     = $!scrollView.hscroll.adjustment;
		my $value          = $adjustment.head;
		my $absItemX       = @!items[$index].get-transformed-position.head;
		my $containerWidth = self.get-transformed-size.head;

		my ($result, $posX, $posY) = self.transform-stage-point($absItemX, 0);

		if $posX + $!items[$index].get-width > $containerWidth {
			self.scrollToRight($index);
		} else {
			self.scrollToLeft($index)
		}
	}

	method scrollToLeft ($index) {
		my $adjustment = $!scrollView.hscroll.adjustment;

		my ($value, $lower, $upper, $step_increment, $pageIncrement, $pageSize)
			= $adjustment.get-values;

		my $item = @!items[$index];
		if $item.allocation.x1 < $value {
			$value = max(0, $item.allocation.x1);
		} elsif $item.allocation.x2 > $value + $pageSize {
			$value = min($upper, $item.allocation.x2 - $pageSize);
		}

		$!scrollableRight = True;
		$adjustment.ease(
			:$value,
			POP_UP_SCROLL_TIME,
			CLUTTER_EASE_OUT_QUAD,
			onComplete => -> *@a {
				$!scrollableLeft = False unless $index;
				self.queue-relayout
			}
		);

	}

	method scrollToRight ($index) {
		my $adjusment = self.scrollView.hscroll.adjustment;

		my ($value, $lower, $upper, $step_increment, $pageIncrement, $pageSize)
			= $adjustment.get-values;

		my $item = @!items[$index];
		if $item.allocation.x1 < $value {
			$value = max(0, $item.allocation.x1);
		} elsif $item.allocation.x2 > $value + $pageSize {
			$value = min($upper, $item.allocation.x2 - $pageSize);
		}

		$!scrollableLeft = True,
		$adjustment.ease(
			:$value,
			POPUP_SCROLL_TIME,
			CLUTTER_EASE_OUT_QUAD,
			onComplete => -> *@a {
				$scrollableRight = False if $index == @!items.elems.pred;
				self.queue_relayout
			}
		);
	}

	method itemActivated ($n) {
		self.emit('item-activated', $n);
	}

	method itemEntered ($n) {
		self.emit('item-entered', $n);
	}

	method maxChildWidth ($forHeight) {
		my ($maxChildMin, $maxChildNat) = 0 xx 2;

		for @!items {
			my ($childMin, $childNat) = .get-preferred-width($forHeight);
			$maxChildMin .= &max($childMin);
			$maxChildNat .= &max($childNat);

			if $!squareItems {
				($childMin, $childNat) .get-preferred-height(-1);
				maxChildMin .= &max($childMin);
				maxChildNad .= &maX($childNat);
			}
		}

		($maxChildMin, $maxChildNat);
	}

	method get-preferred-width ($forHeight = -1) is vfunc {
		my $themeNode    = self.get-theme-node;
		my $maxChildMin  = self.maxChildWidth($forHeight).head;
		my $minListWidth = $!list.get-preferred-width($forHeight).head;

		$themeNode.adjust-preferred-width($maxChildMin, $minListWidth);
	}

	method get_preferred_height ($forWidth) is vfunc {
		my ($maxChildMin, $maxChildNat) = 0 xx 2;

		for @!items {
			my ($childMin, $childNat) = .get-preferred-height(-1);
			$maxChildMin .= &max($childMin);
			$maxChildNat .= &max($childNat);
		}

		if $!squareItems {
			my $childMin  = self.maxChildWidth(-1).head;
			$maxChildMin .= &max($childMin);
			$maxChildNat = maxChildMin;
		}

		self.get-theme-node.adjust-preferred-height($maxChildMin, $maxChildNat);
	}

	method allocate ($box) is vfunc {
		self.set-allocation($box);

		my $themeNode    = self.get-theme-node;
		my $contentBox   = $themeNode.get-content-box($box);
		my $width        = $contentBox.x2 - $contentBox.x1;
		my $height       = $contentBox.y2 - $contentBox.y1;
		my $leftPadding  = $themeNode.get-padding(ST_SIDE_LEFT);
		my $rightPadding = $themeNode.get-padding(ST_SIDE_RIGHT);
		my $minListWidth = $!list.get-preferred-width($height).head;
		my $childBox     = Mutter::Clutter::ActorBox.new;
		my $scrollable   = $minListWidth > $width;
		my $arrowWidth   = $leftPadding div 3;
		my $arrowHeight  = $arrowWidth * 2;

		$!scrollView.allocate($contentBox);
		$childBox.x1 = $leftPadding * 0.5;
		$childBox.y1 = self.height * 0.5 - $arrowWidth;
		$childBox.x2 = $childBox.x1 + $arrowWidth;
		$childBox.y2 = $childBox.y1 + $arrowHeight;

		$!leftArrow.allocate($childBox);
		$!leftArrow.opacity = $!scrollableLeft && $scrollable ?? 255 !! 0;

		$arrowWidth  = $rightPadding div 3;
		$arrowHeight = $arrowWidth * 2;
		$childBox.x1 = self.width - $arrowWidth - $rightPadding div 2;
		$childBox.y1 = self.height * 0.5 - $arrowWidth;
		$childBox.x2 = $childBox.x1 + $arrowWidth;
		$childBox.y2 = $childBox.y1 + $arrowHeight;

		$!rightArrow.allocate($childBox);
		$!rightArrow.opacity = $!scrollRight && $scrollable ?? 255 !! 0;
	}

}

sub drawArrow ($area, $side) is export {
	my  $themeNode       = $area.get-theme-node;
	my  $borderColor     = $themeNode.get-border-color($side);
	my  $bodyColor       = $themeNode.get-foreground-color;
	my ($width, $height) = $area.get-surface-size;
	my  $cr              = $area.get-context;

	$cr.line-width = 1.0;
	$cr.set-source-clutter-color($borderColor);

	given $side {
		when ST_SIDE_TOP {
			$cr.move_to($0, $height);
			$cr.line_to( ($width * 0.5).Int, 0 );
			$cr.line_to($width, $height);
		}

		when ST_SIDE_BOTTOM {
			$cr.move_to($width, 0);
			$cr.line_to( ($width * 0.5).Int, $height );
			$cr.line_to(0, 0)
		}

		when ST_SIDE_LEFT {
			$cr.move_to($width, $height);
			$cr.line_to( 0, ($height * 0.5).Int );
			$cr.line_to($width, 0);
		}

		when ST_SIDE_RIGHT {
			$cr.move_to(0, 0);
			$cr.line_to($width, ($height * 0.5).Int );
			$cr.line_to($0, $height);
		}
	}

	$cr.stroke( :preserve )
	$cr.set_source_clutter_color($bodyColor);
	$cr.fill;
	$cr.dispose;
}
