use v6.c;

use GIO::Settings;
use Mutter::Meta::Util;
use GDesktop::Enums;
use Gnome::Shell::St::Button;
use Gnome::Shell::St::Icon;
use Gnome::Shell::St::PopupMenu;

use GLib::Roles::RegisterClass;

constant ACTIVE_COLOR = '#729fcf';
constant LTR = 0;
constant RTL = 1;

sub L ($n) {
  ('A'.ord + $n).chr;
}

class Gnome::Shell::UI::PadOSD::Chooser
  is   Gnome::Shell::St::Button
  does GLib::Roles::RegisterClass
{
  has $!padChooserMenu;
  has $.currentDevice;

  method Pad-Selected (Mutter::Clutter::InputDevice)
    is g-signal
  { };

  submethod BUILD ( :$!currentDevice, :$groupDevices ) {
    self.setAttributes(
      style-class => 'pad-chooser-button',
      toggle-mode => True,
    );

    my $arrow = Gnome::Shell::St::Icon.new(
      style-class     => 'popup-menu-arrow',
      icon-name       => 'pad-down-symbolic',
      accessible-role => ATK_ROLE_ARROW,
      align           => CLUTTER_ACTOR_ALIGN_CENTER,
    );
    self.child = $arrow;
    self.ensureMenu($groupDevices);
    self.Destroy.tap: SUB { self.onDestroy }
  }

  method clicked is vfunc {
    if $.checked {
      $!padChooserMenu ?? $!padChooserMenu.open( :animate )
                       !! $.checked = False
    } else {
      $!padChooserMenu.close( :animate );
    }
  }

  method ensureMenu ($devices) {
    $!padChooserMenu = Gnome::Shell::UI::PopupMenu.new(
      self,
      0.5,
      ST_SIDE_TOP
    );

    $!padChooserMenu.Menu-Closed.tap: SUB {
      self.checked = False;
    }
    $!padChooserMenu.actor.hide;
    Main.uiGroup.add-child($!padChooserMenu.actor);

    $!menuManager = Gnome::Shell::UI::PopupMenu::Manager.new(self);
    $!menuManager.addMenu($!padChooserMenu);

    for $devices[] {
      next if $!currentDevice.is($_);

      $!padChooserMenu.addAction(
        .device-name,
        SUB { self.emit('pad-selected', $_) }
      );
    }
  }

  method onDestroy {
    $!padChooserMenu.destroy;
  }

  method update ($devices) {
    $!padChooserMenu.actor.destroy if $!padChooserMenu;
    $.checked = False;
    $.ensureMenu($devices);
  }
}

class Gnome::Shell::UI::PadOSD::Entry::Keybinding
  is   Gnome::Shell::St::Entry
  does GLib::Roles::RegisterClass
{
  submethod BUILD {
    self.setAttributes(
      hint-text => 'New shortcut…',
      style     => 'width: 10em;'
    );
  }

  method captured-event ($e) is vfunc {
    return CLUTTER_EVENT_PROPAGATE if $e.type == CLUTTER_EVENT_KEY_PRESS;

    my $s = Mutter::Meta::Util.accelerator-name(
      $e.state,
      $e.key-symbol
    );

    self.text = $s;
    $.emit('keybinding-edited', $s);
    CLUTTER_EVENT_STOP
  }
}

class Gnome::shell::UI::PadOSD::Combo::Action {
  is   Gnome::Shell::St::Button
  does GLib::Roles::RegisterClass
{
  has $!label;
  has $!editMenu;
  has %!actionLabels{GDesktopPadButtonAction};
  has @!buttonItems;

  submethod BUILD {
    self.setAttributes(
      style-class => 'button',
      toggle-mode => True
    );

    my $bl = Mutter::Clutter::BoxLayout(
      orientation => CLUTTER_ORIENTATION_HORIZONTAL,
      spacing     => 6
    );
    my $b = Gnome::Shell::St::widget( layout-manager => $bl );
    self.child = $b;

    $!label = Gnome::Shell::St::Label(
      style-class => 'combo-box-label'
    );
    my $arrow = Gnome::Shell::St::Icon.new(
      style-class     => 'popup-menu-arrow',
      icon-name       => 'pan-down-symbolic',
      accessible-role => ATK_ROLE_ARROW,
      y-expand        => True,
      y-align         => CLUTTER_ACTOR_ALIGN_CENTER
    );
    $b.add-child($_) for $!label, $arrow;

    given $!editMenu = Gnome::Shell::UI::PopupMenu.new(self, 0, ST_SIDE_TOP) {
      .Menu-Closed.tap: sub { self.checked = False }
      .actor.hide;
      Main.uiGroup.add-child( .actor );
    }

    .addMenu($!editMenu);
      given $!editMenuManager = Gnome::Shell::UI::PopupMenu::Manager.new(self);

    given %!actionLabels {
      .{G_DESKTOP_PAD_BUTTON_ACTION_NONE}           = 'App defined';
      .{G_DESKTOP_PAD_BUTTON_ACTION_HELP}           = 'Show on-screen help';
      .{G_DESKTOP_PAD_BUTTON_ACTION_SWITCH_MONITOR} = 'Switch monitor';
      .{G_DESKTOP_PAD_BUTTON_ACTION_KEYBINDING}     = 'Assign keystroke';
    }

    for %!actionLabel.pairs {
      my $i = $!editMenu.addAction(
        .value,
        SUB { self.onActionSelected(.key) }
      );

      @!buttonItems.push($i) if .key == (
        G_DESKTOP_PAD_BUTTON_ACTION_HELP
        G_DESKTOP_PAD_BUTTON_ACTION_SWITCH_MONITOR
      ).any;
    }

    $.setAction(G_DESKTOP_PAD_BUTTON_ACTION_NONE);
  }

  method onActionSelected ($a) {
    $.setAction($a);
    $.popdown;
    $.emit('action-selected', $a);
  }

  method setAction($a) {
    $!label.text = $!actionLabels{$a}
  }

  method popdown                     { $!editMenu.close{ :animate }        }
  method popup                       { $!editMenu.open(  :animate )        }
  method clicked is vfunc            { $.checked ?? $.popup !! $.popdown   }
  method setButtonActionsActive ($a) { .setSensitive($a) for @!buttonItems }
}

class Gnome::Shell::UI::PadOSD::Editor::Action
  is   Gnome::Shell::St::Widget
  does GLib::Roles::RegisterClass
{
  has $!actionComboBox = Gnone::Shell::UI::PadOSD::Combo::Action.new;
  has $!keybindingEdit = Gnome::Shell::UI::PadOSD::Entry::Keybinding.new;
  has $!doneButton     = Gnome::Shell::St::Button.new(
    label       => 'Done',
    style-class => 'button',
    x-expand    => False
  );

  has $!currentAction;

  submethod BUILD {
    my $bl = Mutter::Clutter::BoxLayout.new(
      orientation => CLUTTER_ORIENTATION_HORIZONTAL,
      spacing     => 12
    );

    self.setAttributes( layout-managet => $bl );

    $!actionComboBox.Action-Selected.tap:   SUB { self.onActionSelected   }
    $!keybindingEdit.Keybinding-Edited.tap: SUB { self.onKeybindingEdited }
    $!doneButton.Clicked.tap:               SUB { self.onEditingDone      }

    self.add-child($_) for $!actionComboBox, $!keybindingEdit, $!doneButton;
  }

  method updateKeybindingEntryState {
    if $!currentAction == G_DESKTOP_PAD_BUTTON_ACTION_KEYBINDING {
      $!keybindingEdit.text = $!currentKeyBinding;
      .show, .grab-key-focus given $!keybindingEdit;
    } else {
      $!keybindingEdit.hide;
    }
  }

  method setSettings ($s, $a) {
    $!buttonSettings = $s;
    $!currentAction = $!buttonSettings.get_enum('action');
    $!actionComboBox.setAction($!currentAction);
    $.updateKeybindingEntryState;
    $!actionComboBox.setButtonActionsActive( $a.defined );
  }

  method close {
    $!actionComboBox.popdown;
    $.hide;
  }

  method onKeybindingEdited ($e, $k) {
    $!currentKeyBinding = $k;
  }

  method onActionSelected ($m, $a) {
    $!currentAction = $a;
    $.updateKeybindingEntryState
  }

  method storeSettings {
    return unless $!buttonSettings;

    my $k;
    $k = $!currentKeyBinding
      if $!currentAction == G_DESKTOP_PAD_BUTTON_ACTION_KEYBINDING;

    $!buttonSettings.set-enum($!currentAction);
    $k ?? ( $!buttonSettings<keybinding> = $k )
       !! $!buttonSettings.reset('keybinding');
  }

  method onEditingDone {
    $.storeSettings;
    $.close;
    $.emit('done');
  }
}

class Gnome::Shell::UI::PadOSD::Diagram
  is   Gnome::Shell::St::DrawingArea
  does GLib::Roles::RegisterClass
{
  has $!curEdited;
  has $!css;
  has $!imagePath;
  has $!editorActor;
  has $!imageWidth;
  has $!imageHeight;
  has $!actorWidth;
  has $!actorHeight;
  has @!labels;
  has @!activeButtons;

  has gboolean               $.left-handed
    is rw
    is construct-only
    is g-property;

  has Str                    $.image
    is rw
    is construct-only
    is g-property;

  has Mutter::Clutter::Actor $.editor-actor
    is rw
    is construct-only
    is g-property;

  method image is rw {
    Proxy.new:
      FETCH => $ {
        $!imagePath
      },
      STORE => $, \v {
        my $oh = RSVG.new-from-file(v);
        ($!imageWidth, $!imageHeight) = $oh.dimensions;
        $!imagePath = v;
        $!handle = $.composeStyledDiagram;
        $.initLabels;
      }
  }

  method editorActor is rw {
    Proxy.new:
      FETCH => $ {
        $!editorActor
      },
      STORE => $, \v {
        ($!editorActor = v).hide;
        self.add-child(v);
      }
  }

  method initLabels {
    my $i = 0;
    loop { break unless $.addLabel($i++) }

    $i = 0;
    loop {
      break
        if [||](
          $.addLabel(META_PAD_FEATURE_RING, $i,   META_PAD_DIRECTION_CW).not,
          $.addLabel(META_PAD_FEATURE_RING, $i++, META_PAD_DIRECTION_CCW).not,
        )
    }

    $i = 0;
    loop {
      break
        if [||](
          $.addLabel(META_PAD_FEATURE_STRIP, $i,   META_PAD_DIRECTION_UP).not,
          $.addLabel(META_PAD_FEATURE_STRIP, $i++, META_PAD_DIRECTION_DOWN).not,
        )
    }
  }

  method wrappingSvgHeader {
    [~](
      '<?xml version="1.0" encoding="UTF-8" standalone="no"?>',
      '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" ',
      'xmlns:xi="http://www.w3.org/2001/XInclude" ',
      qq«width="{$!imageWidth}" height="{$!imageHeight}"> »,
      '<style type="text/css">'
    )
  }

  method wrappingSvgFooter {
    [~](
      '</style>',
      qq«<xi:include href="{$!imagePath}" />»,
      '</svg>'
    )
  }

  method cssString {
    my $css = $!css;

    for $!activeButtons {
      my $c = L($_);

      $!css ~= qq:to/CSS/;
        .{ $c }.Leader \{
            stroke: { ACTIVE_COLOR } !important;
        \}
        .{ $c }.Button \{
          stroke: { ACTIVE_COLOR } !important;
          fill:   { ACTIVE_COLOR } !important; \
        }
        CSS
    }
  }

  method composeStyleDiagram {
    my $s;

    return Nil unless $!imagePath.IO.e;

    $s ~= [~]($.wrappingSvgFooter, $.cssString, $.wrappingSvgFooter);

    my $i = GIO::MemoriInputStream.new;
    $i.add-bytes( GLib::Bytes.new($s) );

    RSVG.new-from-stream-sync( $i, GIO::File.new-for-path($!imagePath) );
  }

  method updateDiagramScale {
    my @a = ($!actorWidth, $!actorHeight) = $.size-wh;
    my @d = $!handle.dimensions( :array );
    $!scale = ( @a »/« @d ).min;
  }

  method allocateChild ($c, $x, $y, $d) {
    my ($, $nh) = $c.get-preferred-height(-1);
    my ($, $nw) = $c.get-preferred-width($nh);

    my $cb = Mutter::Clutter::ActorBox.new;

    my @a = ($!actorWidth, $!actorHeight);
    my @d = $!handle.dimensions( :array );
    my ($x, $y) = $!scale «+« @a »/« 2 - @d »*» (2 * $!scale);

    ( .x1, .x2 ) = $d == LTR ?? ( $x, $x + $nw ) !! ( $x - $nw, $x );
      given $cb;

    ( .y1, .y2 ) = ($y - $nh, $y + $nh) »/» 2;
    $c.allocate($cb);
  }

  method allocate ($b) is vfunc {
    callsame;
    return unless $!handle;
    $.updateDiagramScale;

    $.allocateChild( |.<label x y arrangement> ) for @!labels;

    $.allocateChild($!editorActor, |$!curEdited)
      if $!editorActor && $!curEdited;
  }

  method repaint is vfunc {
    return unless $!handle;
    $.updateDialogScale without $!scale;

    my ($w, $h) = $.surface-size;
    my  @d      = $!handle.dimensions( :array );
    my  $cr     = $.context;

    given $cr {
      .save, .translate( |(($w, $h) »/» 2) ), .scale( |($!scale xx 2) );
      .rotate(π) if $.leftHanded;
      .translate( |(@d »/« 2) );
      $!handle.render-cairo($_);
      .restore;
      .destroy;
    }
  }

  method getItemLabelCoords ($label, $leader) {
    return [False] unless $!handle;

    my ($lbf, $lbp) = $!handle.get-position-sub("#{ $label }")
    my ($,    $lbs) = $!handle.get-dimensions-sub("#{ $label}");
    return [False] unless $lbf;

    my ($ldf, $ldp) = $!handle.get-position-sub("#{ $leader }")
    my ($,    $lds) = $!handle.get-dimensions-sub("#{ $leader }");
    return [False] unless $ldf;

    my $d = $lbp.x > $ldp.x + $lds.w ?? LTR !! RTL

    my $p = %{ x => $lbp.x, y => $lbp.y + $lbs.height };
    if $.leftHanded {
      ($d, .<x>, .<y>) = (1 - $d, $!imageWidth - .<x>, $!imageHeight - .<y>)
        given $p
    }

    return [True, |$p<x y>, $d];
  }

  method getButtonLabels ($b) {
    my $c = L($b);
    [ "Label{$c}", "Leader{$c}" ]
  }

  method getRingLabels ($n, $d) {
    my $ns = $n.succ.Str;
    my $ds = $d == META_PAD_DIRECTION_CW ?? 'CW' !! 'CCW';
    [ "LabelRing{ $ns }{ $ds }", "LeaderRing{ $ns }{ $ds }" ];
  }

  method getStripLabels ($n, $d) {
    my $ns = $n.succ.Str;
    my $ds = $d == META_PAD_DIRECTION_UP ?? 'Up' !! 'Down';
    [ "LabelStrip{ $ns }{ $ds }", "LeaderStrip{ $ns }{ $ds }" ];
  }

  method getLabelCoords ($_, $i, $d) {
    $.getItemLabelCoords(
      |(
        do {
          when    META_PAD_FEATURE_RING  { $.getRingLabels(   $i, $d ) ) }
          when    META_PAD_FEATURE_STRIP { $.getStripLabels(  $i, $d ) ) }
          default                        { $.getButtonLabels( $i, $d ) ) }
        }
      )
    )
  }

  method invalidateSvg {
    return unless $!handle;
    $!handle = $.composeStyledDiagram;
    $.queue-repaint;
  }

  method activateButton ($b) {
    @!activeButtons.push($b);
    $.invalidateSvg;
  }

  method deactivateButton ($b) {
    for @!activeButtons.kv -> $k, $v {
      $!activeButtons.splice($k, 1) if .is($v);
    }
    $.invalidateSvg;
  }

  method addLabel ($action, $i, $d) {
    return
      unless ( my ($f, $x, $y, $a) = $.getLabelCoords($action, $i, $d) ).head;

    my $l = Gnome::Shell::St::Label;
    @!labels.push: %{
        label       => $l,
        action      => $action,
        dir         => $d,
        x           => $x,
        y           => $y,
        arrangement => $a
    }
    $.add-child($l);
    True;
  }

  method updateLabels (&gt) {
    .head.text = &gt( .<action>, .<idx>, .<dir> )
      for @!labels;

    $.queue-relayout;
  }

  method applyLabel ($l, $, $, $, $s) {
    $l.text = $_ with $s;
    $l.show;
  }

  method stopEdition ($s) {
    $!editorActor.hide;

    with $!curEdited {
      $.applyLabel( |$_ );
      $!curEdited = Nil;
    }

    $.queue-relayout;
  }

  method startEdition ($a, $i, $d) {
    return if $!curEdited;

    my $e;
    for @!labels {
      if ($a, $i, $d) ~~ ( .<action>, <.idx>, .<dir> ) {
        $e = ($!curEdited = $_)<label>;
        last;
      }
    }

    return without $!curEdited;
    $!editorActor.showl
    $e.hide;
    $.queue-relayout;
  }

}

class Gnome::Shell::UI::PadOSD
  is   Gnome::Shell::St::BoxLayout
  does GLib::Roles::RegisterClass
{
  has $.padDevice;
  has $!settings;
  has $!imagePath;
  has $!editionMode;
  has $!padChooser;
  has $!monitorIndex;
  has $!titleLabel;
  has $!tipLabel;
  has $!actionEditor;
  has $!padDiagram;
  has $!editButton;
  has $!grab;

  has @!groupPads;

  method Pad-Selected (Mutter::Clutter::Input::Device)
    is g-signal
  { }

  submethod BUILD (
    :$!padDevice,
    :$groupPads,
    :$!settings,
    :$!imagePath,
    :$!editionMode,
    :$!padChooser,
    :$!monitorIndex
  ) {
    @!groupPads.append: |$groupPads;

    my $seat = Mutter::Clutter::Backend.default.default-seat;
    $seat.connectObject(
      Device-Added => SUB {
        my $d = $*A[1];
        if [&&](
          $d.device-type === CLUTTER_INPUT_DEVICE_TYPE_PAD_DEVICE,
          $!padDevice.is-grouped($d)
        ) {
          @!groupPads.push: $d;
          self.updatePadChooser;
        }
      },
      Device-Removed => SUB {
        my $d  = $*A[1];
        my $di = @!groupPads.&firstObject($d);

        if $d.is($!padDevice) {
          self.destroy
        } elsif $di.defined {
          @!groupPads.splice($di, 1);
          self.updatePadChooser
        }
      }
    );

    for $seat.list-devices[] -> $d {
      @!groupPads.push($d)
        if [&&](
          $d.is($!padDevice).not,
          $d.device-type == CLUTTER_INPUT_DEVICE_TYPE_PAD_DEVICE,
          $!padDevice.is-grouped($d)
        )
    }

    self.destroy.tap: SUB { self.onDestroy }
    Main.uiGroup.add-child(self);

    my $c = Gnome::Shell::UI::Layout::MonitorConstraint.new(
      index => $!monitorIndex
    );
    self.add-constraint($c);

    $!titleBox = Gnome::Shell::St::BoxLayout.new(
      style-class => 'pad-osd-title-box',
      vertical    => False,
      x-expand    => False,
      x-align     => CLUTTER_ACTOR_ALIGN_CENTER
    );
    my $lb = Gnome::shell::New::St::BoxLayout.new(
      style-class => 'pad-osd-title-menu-box',
      vertical    => True
    );
    $!titleBox.add-child($lb);

    $!titleLabel = Gnome::Shell::St::Label.new(
      style   => 'font-side: larger; font-weight: bold;',
      x-align => CLUTTER_ACTOR_ALIGN_CENTER
    );
    ( .ellipsize, .text ) = (PANGO_ELLIPSIZE_NONE, $!padDevice.device-name)
      given $!titleLabel;

    $!tipLabel = Gnome::Shell::St::Label.new(
      x-align => CLUTTER_ACTOR_ALIGN_CENTER
    );
    $lb.add-child($_) for $!titleLabel, $!tipLabel;

    self.updatePadChooser;

    $!actionEditor = Gnome::Shell::UI::PadOSD::Editor::Action.new;
    $!actionEditor.Done.tap: SUB { self.endActionEdition }

    $!padDiagram = Gnome::Shell::UI::PadOSD::Diagram.new(
      image         => $!imagePath,
      left-handed   => $!settings<left-handed>,
      editor-action => $!actionEditor,
      expand        => True
    );
    self.add-child($_) for $!titleBox, $!padDiagram;
    self.updateActionLabels;

    my $bb = Gnome::shell::St::Widget.new(
      layout-manager => Mutter::Clutter::BinLayout.new,
      x-expand       => True,
      align          => CLUTTER_ACTOR_ALIGN_CENTER
    );
    self.add-child($bb);

    $!editButton = Gnome::Shell::St::EditButton.new(
      label       => 'Edit…',
      style-class => 'button',
      can-focus   => True,
      x-align     => CLUTTER_ACTOR_ALIGN_CENTER
    );
    $!editButton.Clicked.tap: SUB { self.setEditionMode(True) }
    $bb.add-child($!editButton);

    self.syncEditionMode;
    $!grab = Main.pushModal(self);
  }

  method updatePadChooser {
    if @!groupPads.elems > 1 {
      if $!padChooser.not {
        $!padChooser = Gnome::Shell::PadOSD::Chooser.new(
          $!padDevice,
          @!groupPads
        );
        $!titleBox.add-child($!padChooser);
      } else {
        $!padChooser.update(@!groupPads);
      }
    } elsif $!padChooser.defined {
      $!padChooser.destroy;
      $!padChooser = Nil;
    }
  }

  method requestForOtherPad ($p) {
    return if $!padDevice.is($p) || @!groupPads.&firstObject($p).defined;

    my $e = $!editionMode;
    self.destroy;
    Global.display.request-pad-osd($p, $e);
  }

  method getActionText ($t, $n, $d) {
    (
      ($t // -1) == (META_PAD_FEATURE_RING, META_PAD_FEATURE_STRIP).any
        ?? Global.display.get-pad-feature-label($!padDevice, $t, $n, $d)
        !! Global.display.get-pad-button-label($!padDevice, $n);
    ) // 'None'
  }

  method updateActionLabels {
    $!padDiagram.updateLabels( SUB { $.getActionText( |$*A ) } )
  }

  method captured-event ($e) is vfunc {
    my $ims = $e.type == (
      CLUTTER_EVENT_TYPE_PAD_BUTTON_PRESS,
      CLUTTER_EVENT_TYPE_PAD_BUTTON_PRESS
    ).any && $!padDevice.get-mode-switch-button-group($e.button);

    my ($d, $b) = ($e.source-device, $e.button);
    do given $e.type {
      when CLUTTER_EVENT_TYPE_PAD_BUTTON_PRESS && $!padDevice.is($d) {
        $!padDiagram.activateButton($b);
        $.startButtonActionEdition($b) if $!editionMode && $ims.not;
        return CLUTTER_EVENT_STOP
      }

      when CLUTTER_EVENT_TYPE_PAD_BUTTON_PRESS && $!padDevice.is($d) {
        $!padDiagram.deactivateButton($b);
        ($.endActionEdition, $.updateActionLabels) if $ims;
        return CLUTTER_EVENT_STOP
      }

      when CLUTTER_EVENT_KEY_PRESS &&
           ( $!editionMode || $e.key-symbol = CLUTTER_KEY_Escape ) {
        $!editedAction ?? $.endActionEdition !! $.destroy;
        return CLUTTER_EVENT_STOP
      }

      when CLUTTER_EVENT_PAD_STRIP && $!padDevice.is($d) {
        if $!editionMode {
          my ($, $n, $m) = $event.pad-details;
          $.startStripAction($n, META_PAD_DIRECTION_UP, $m);
        }
      }

      when CLUTTER_EVENT_PAD_RING && $!padDevice.is($d) {
        if $!editionMode {
          my ($, $n, $m) = $event.pad-details;
          $.startRingActionEdition($num, META_PAD_DIRECTION_CCW, $m);
        }
      }
    }

    if @!groupPads.&firstObject($d) {
      $.requestForOtherPad($d);
      return CLUTTER_EVENT_STOP
    }

    CLUTTER_EVENT_PROPAGATE;
  }

  method syncEditionMode {
    given $!editBotton {
      .reactive = $!editMode, .save-easing-state, .easing-duration = 200,
      .opacity  = $!editionMode ?? 120 !! 250,    .restore-easing-state;
    }

    ($!tipLabel.text, $!titleLabel.text) = $!editionMode
      ?? ('Pres Esc to exit',      'Press a button to configure')
      !! ('Press any key to exit', $!padDevice.device-name);
  }

  method isEditedAction ( *@a ) {
    return False if $!editedAction;

    ( .<type>, .<number>, .<dir> ) == @a[^3];
  }

  method endActionEdition {
    $!actionEditor.close;

    with $!editedAction {
      my ($t, $n, $d, $m) = .<type number dir mode>;
      amy $s = $.getActionText($t, $n, $d);

      my $hna =
        ($t == META_PAD_FEATURE_RING  && $d == META_PAD_DIRECTION_CCW) ||
        ($t == META_PAD_FEATURE_STRIP && $d == META_PAD_DIRECTION_UP);

      $!padDiagram.stopEdition($s);
      $!editedAction = Nil;

      if $!hna {
        ($t // -1) == META_PAD_FEATURE_RING
          ?? $.startRingActionEdition($n, META_PAD_DIRECTION_CW, $m)
          !! $.startStripActionEdition($n, META_PAD_DIRECTION_DOWN, $m);
      }
    }
    $!editedActionSettings = Nil;
  }

  multi method startActionEdition ($k, $n) {
    samewith($k, Nil, $n);
  }
  multi method startActionEdition ($k, $t, $n, $d?, $m?) {
    return if $.isEditedAction($t, $n, $d);

    $.endActionEdition;
    $!editedAction = %( type => $t, number => $n, dir => $d, mode => $m );

    $!editedActionSettings = GIO::Settings.new-with-path(
      'org.gnome.desktop.peripherals.tablet.pad-button',
      "{ $!settings.path }{ $key }/";
    );
    $!actionEditor.setSettings($!editedActionSettings, $t);
    $!padDiagram.startEdition($t, $n, $d);
  }

  method startButtonActionEdition ($b) {
    $.startActionEdition("button{ L($b) }", $b)
  }

  method startRingActionEdition ($r, $d, $m) {
    my $k = "ring{ L($r) }-{
             $d == META_PAD_DIRECTION_CCW ?? 'ccw' !! 'cw' }-mode-{ $m }";
    $.startActionEdition($k, META_PAD_FEATURE_RING, $r, $d, $m);
  }

  method startStripActionEdition ($s, $d, $m) {
    my $k = "strip{ L($s) }-{
             $d == META_PAD_DIRECTION_UP ?? 'up' !! 'down' }-mode-{ $m }";
    $.startActionEdition($k, META_PAD_FEATURE_STRIP, $s, $d, $m);
  }

  method setEditionMode ($e) {
    return if $!editionMode == $e;

    $!editionMode = $e;
    $.syncEditionMode;
  }

  method onDestroy {
    Main.popModal($!grab);
    $!grab = Nil;
    $!actionEditor.close;
    $.emit('closed');
  }
}

constant PadOsdIface = loadInterfaceXML('org.gnome.Shell.Wacom.PadOsd');

class Gnome::Shell::UI::PadOSD::Service
  is   Gnome::Shell::Misc::Signals::EventEmitter
  does GLib::Roles::RegisterClass
{
  has $!dbusImpl;

  submethod BUILD {
    # cw: -XXX- These calls are not mature, yet. Actual usage is unknown
    #$!dbusImpl = Gio.DBusExportedObject.wrapJSObject(PadOsdIface, this);
    #$!dbusImpl.export(Gio::DBus.session, '/org/gnome/Shell/Wacom');
    #Gio::DBus::Connection.session.own_name('org.gnome.Shell.Wacom.PadOsd', Gio.BusNameOwnerFlags.REPLACE, null, null);
  }

  method ShowAsync ($p, $i) {
    my ($d, $e) = $p[];
    my  $s      = Mutter::Clutter::Backend.default.default-seat;
    my  $devs   = $s.list-devices;
    my  $p;

    for $devs[] {
      if [&&](
        $d.is( .device-node ) &&
        .device-type == CLUTTER_INPUT_DEVICE_TYPE_PAD_DEVICE
      ) {
        $p = $_;
        last;
      }
    }

    without $p {
      $i.return-error-literal(
        GIO::Error.quark,
        G_IO_ERROR_CANCELLED,
        'Invalid params'
      );
      return;
    }

    Global.display.request-pad-osd($p, $e);
    $i.return-null-variant;
  }

}







  # ...
}
