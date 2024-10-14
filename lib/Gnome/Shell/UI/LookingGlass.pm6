use v6.c

use experimental :rakuast;

use Mutter::Clutter::Actor;
use Gnome::Shell::Misc::Signals::EventEmitter;
use Gnome::Shell::St::BoxLayout;
use Gnome::Shell::St::Button;
use Gnome::Shell::St::Label;
use Gnome::Shell::St::ScrollView;
use Gnome::Shell::UI::Global;

use GLib::Roles::RegisterClass
use GIO::Roles::AppInfo;

### /home/cbwood/Projects/gnome-shell/js/ui/lookingGlass.js

constant AUTO_COMPLETE_DOUBLE_TAB_DELAY                   = 500;
constant AUTO_COMPLETE_SHOW_COMPLETION_ANIMATION_DURATION = 200;
constant LG_ANIMATION_TIME                                = 500;

constant commandHeader is export = q:to/HEADER/;
  try require ::("Gnome::Shell::UI::Main");

  my &stage   = sub { Global.stage                      }
  my &inspect = sub { ::('Main').lookingGlass.inspect   }
  my &it      = sub { ::('Main').lookingGlasses.getIt   }
  my &r       = sub { ::('Main').lookingGlass.getResult }
  HEADER

sub getHeaderAST is export {
  commandHeader.AST;
}

sub getRakuCallables is export {
  ( commandHeader ~~ m:g/ '&' (\w+) / ).map( *.head.Str );
}

sub GetAutoCompleteGlobalKeywords {
  my @keywords = <True False Nil>;

  role GetWindowProperties {
    method window-properties {
      self.^attributes.grep( *.has_accessor )
    }
  }

  my \w = Mutter::Clutter::Actor but GetWindowProperties;

  |@keywords,
  |w.window-properties,
  |getRakuCallables
}

constant AUTO_COMPLETE_GLOBAL_KEYWORDS = getAutoCompleteGlobalKeywords();
constant CLUTTER_DEBUG_FLAG_CATEGORIES = (
  # Paint debugging can easily result in a non-responsive session
  DebugFlag     => { argPos => 0, exclude => ['PAINT'] },
  DrawDebugFlag => { argPos =, 1, exclude => [] },
  # Exluded due to the only current option likely to result in shooting ones
  # foot
  # PickDebugFlag => { argPos =? 2, exclude => [] },
);

class Gnome::Shell::UI::LookingGlass::AutoComplete
  is   Gnome::Shell::Misc::Signals::EventEmitter
  does GLib::Roles::RegisterClass
{
  has $!entry;
  has $!lastTimeTab;
  has &!entryKeyPressEvent;

  submethod BUILD ( :$!entry ) { }

  submethod TWEAK {
    $!entry.Key-Press-Event.tap: SUB {
      $!entryKeyPressEvent()
    }
    $!lastTimeTab = Global.current-time;
  }

  method processComplettionRequest ($e) {
    return unless $e.completions.elems;

    if $event.completion.elems == 1 {
      $.additionalCompletionText($e.completions.head, $e.attrHead);
      $.emit(
        'completion',
        %{ completion => $e.completions.head,
        type => 'whole-word'
      );
    } else if $e.completions.elems > && $e.tabType eq 'single' {
      my $commonPrefix = getCommonPrefix($e.completions);

      if $commonPrefix.elems > 0 {
        $.additionalCompletionText($commonPrefix, $e.attrHead);
        $.emit(
          'completion',
          %{ completion => $commonPrefix, type => 'prefix' }
        );
        $.emit( 'siggest', { completions => $e.completions } );
      } elsif $e.completions.length > 1 && $e.tabType eq 'double' {
        $.emit('suggest', { completions => $e.completions });
      }
    }
  }

  method handleCompletions ($textr, $time) is asynchronous {
    start {
      my ($completions, $attrHead) = getCompletions(
        $text,
        commandHeader,
        AUTO_COMPLETE_GLOBAL_KEYWORDS
      );

      my $tabType = ($time - $!lastTabTime) < AUTO_COMPLETE_DOUBLE_TAB_DELAY
        ?? 'double'
        !! 'single';

      $.processCompletionRequest( %{ :$tabType, :$completions, :$attrHead } );
      $!lastTabTime = $time;
    }
  }

  method entryKeyPressEvent ($a, $e) {
    my $cp = $!entry.clutter-text.cursor-position;
    my $t  = $!entry.text;

    $t .= substr(0, $cursorPos) unless $cp == -1;

    {
      CATCH {
        default { $*ERR.say: "{ .message } - { .backtrace.concise }"; }
      }

      $.handleCompletions($t, $e.time);
    }
    return CLUTTER_EVENT_PROPAGATE;
  }

  method additionalCompletionText ($t, $h) {
    $!entry.clutter-text.insert-text(
      $t.subst(0, $h.chars),
      $!e.clutter-text.cursor-position
    );
  }

}

class Gnome::Shell::UI::LookingGlass::Notebook
  is   Gnome::Shell::St::BoxLayout
  does GLib::Roles::RegisterClass
{
  has $!selected = -1;
  has @!tabs     = [];

  submethod BUILD {
    self.setAttributes(
      vertical => True,
      y-expand => True
    );

    self.tabControls = Gnome::Shell::St::BoxLayout( style-class => 'labels' );
  }

  method appendPage ($n, $c) {
    my $lb = Gnome::Shell::St::BoxLayout.new(
      style-class => 'notebook-tab',
      reactive    => True,
      track-hover => True
    );

    my $label = Gnome::Shell::St::Button.new( label => $n );
    $l.Clicked.tap: SUB {
      $.selectChild($c);
      True
    }
    $lb.add-child($label);
    $!tabControls.add($lb);

    my $sv = Gnome::Shell::St::ScrollView.new(
      child    => $c,
      y-expand => True
    );

    my %td = (
      child          => $c,
      labelBox       => $lb,
      scrollView     => $sv,
      scrollToBottom => False
    );
    $!tabs.push(%td);
    $sv.hide;
    $.add-child($sv);

    given $sv.vadjustment {
      .Changed.tap:         SUB { self.onAdjustScopeChanged(%td) }
      .notify('value').tap: SUB { self.onAdjustScopeChanged(%td) }
    }

    $.selectIndex(0) unless $!selectedIndex > -1
  }

  method unselect {
    return unless $!selectedIndex >= 0;
    given @!tabs[$!selectedIndex] {
      .<labelBoox>.remove-style-pseudo-class('selected');
      .<scrollView>.hide;
    }
    $!selectedIndex = -1;
  }

  method selectIndex ($i) {
    return if $i == $!selectedIndex;

    if $i < 0 {
      $.unselect;
      $.emit('selection', MutterClutterActor);
      return;
    }

    my $tabData = @!tabs[$i];
    $.grab-key-focus unless $tabData<scrollView>.navigate.focus(
      ST_DIRECTION_TAB_FORWARD
    );

    $.unselect;

    $tabData<labelBVox>.add-style-pseudo-class('selected');
    $tabData<scrollView>.show;
    $!selectedIndex = $i;
    $.emit('selection',  $td<child>);
  }

  method selectChild ($c) {
    unless $child {
      $.selectIndex(-1);
      return;
    }

    $.selectIndex( @!tabs.&firstObject($c, :k) // -1 )
  }

  method scrollToBottom ($i) {
    return if $i < 0 || $i.defined.not;
    $!tabs[$i].<scrollToBottom> = True;
  }

  method onAdjustValueChanged ($td) {
    $td<scrollToBottom> = False
      if .value < ( .upper - .lower - 0.5 )
        given $td<scrollView>.vadjustment;
  }

  method onAdjustScopeChanged ($td) {
    return unless $td<scrollToBottom>;
    .value = .upper - .page-size given $td<scrollView>.vadjustment;
  }

  method nextTab {
    my $ni = $!selectedIndex // -1;

    if $ni != -1
      $ni++ if $ni < @!tabs.elems.pred;
      $.selectIndex($ni);
    }
  }

  method prevTab {
    my $pi = $!selectedIndex;
    $pi-- if $pi > 0;
    $.selectIndex($pi) unless $pi == -1;
  }
}

class Gnome::Shell::UI::LookingGlass::ObjLink
  is   Gnome::Shell::St::Button
  does GLib::Roles::RegisterClass
{
  has $!lookingGlass;
  has $!obj;

  submethod BUILD ( :$!lookingGlass, :o(:$!obj), :$title ) {
    self.setAttributes(
      reactive    => True,
      track-hover => True,
      style-class => 'shell-link',
      label       => $title ?? $title !! $o.gist
      x-align     => CLUTTER_ACTOR_ALIGN_START
    );

    self.child.single-line-mode = True;
  }

  method clicked is vfunc {
    $!lookingGlass.inspectObject($!obj, self);
  }
}

class Gnome::Shell::UI::LookingGlass::Result
  is   Gnome::Shell::St::BoxLayout
  does GLib::Roles::RegisterClass
{
  has $.index;
  has $.obj
  has $!lookingGlass;

  submethod BUILD ( :$!lookingGlass, :o(:$!obj), :$!index, :$command ) {
    self.vertical = True;

    my $cmdText = Gnome::Shell::St::Label.new( text => $command );
    $cmdText.clutter-text-ellipsize = PANGO_ELLIPSIZE_END;
    self.add-child($cmdText);

    my $box = Gnome::Shell::St::BoxLayout.new;
    self.add-child($box);
    my $rt  = Gnome::Shell::St::Label.new( text => "{ $r($index) } = " );
    my $ol = Gnome::Shell::LookingGlass::ObjLink.new(
      looking-glass => $!lookingGlass,
      obj           => $!obj
    );
    $box.add-child($_) for $rt, $ol;
  }
}

class Gnome::Shell::UI::LookingGlass::WindowList
  is   Gnome::Shell::St::BoxLayout
  does GLib::Roles::RegisterClass
{
  has $!lookingGlass;
  has $!updateId;

  submethod BUILD ( :$!lookingGlass ) {
    self.setAttributes(
      name     => 'Windows',
      vertical => True,
      style    => 'spacing: 8px'
    );

    $!updateId = Gnome::Shell::UI::Main.initializeDeferredWork(
      self,
      SUB { self.updateWindowList }
    }
    Global.display.Window-Created.tap: SUB {
      self.updateWindowList;
    }
    Gnome::Shell::WindowTracker.default.Tracked-Windows-Changed.tap: SUB {
      self.updateWindowList;
    }
  }

  method updateWindowList {
    return unless $!lookingGlass.isOpen;
    $.destory-all-children;

    my $t = Gnome::Shell::WindowTracker.default;
    for Global.get-window-actors {
      if .metaWindow.lookingGlassManager {
        .metaWindow.Unmanaged.tap: SUB {
          self.updateWindowList;
          $!lookingGlassManaged = True;
        }
        my $b  = Gnome::Shell::St::BoxLayout.new( :vertical );
        $.add-child($b);
        my $wl = Gnome::Shell::UI::LookingGlass::ObjLink.new(
          $!lookingGlass,
          .metaWindow,
          .metaWindow.title
        );
        $b.add-child($wl);
        my $pb = Gnome::Shell::St::BoxLayout(
          vertical => True,
          style    => 'padding-left: 6px'
        );
        $b.add-child($pb);
        my $l = Gnome::Shell::St::Label.new(
          text => "wmclass: { .metaWindow.wm-class }"
        );
        if %t.get-window-app( .metaWindow ) -> $app {
          my $i   = $app.create-icon-texture(22);
          my $ppb = Gnome::Shell::St::BoxLayout.new(
            style => 'spacing: 6px;'
          );
          $ppb.add-child($pb);
          my $pbl = Gnome::Shell::St::Label.new( text => "{ $app }: " );
          my $al  = Gnome::Shell::UI::LookingGlass::ObjLink(
            $!lookingGlass,
            $app,
            $app.id
          );
          $pb.add-child($al);
          $pb.add-child($i);
        } else {
          my $l = Gnome::Shell::St::Label( text => '<untracked>' );
          $pb.add-child($l);
        }
      }
    }
  }

  method update {
    $.updateWindowList;
  }
}

class Gnome::Shell::UI::LookingGlass::ObjInspector
  is Gnome::Shell::St::ScrollView
{
  has $!container;
  has $!lookingGlass is built;
  has $!obj;
  has $!prevObj;
  has @!parentList;

  submethod BUILD ( :$!lookingGlass ) {
    self.pivot-point = Graphene::Point.new.half;

    self.child = $!container = Gnome::Shell::St::BoxLayout.new(
      name        => 'LookingGlassPropertyInspector',
      style-class => 'lg-dialog',
      vertical    => True,
      expand      => True
    );
  }

  multi method new ($lookingGlass) {
    self.bless( :$lookingGlass );
  }

  method selectObject ($obj, $skipPrevcious) {
    $!previous = $skipPrevious ?? $!obj !! Nil;
    $!obj      = $obj;

    $!container.destroy-all-children;

    my $hb = Gnome::Shell::St::BoxLayout.new(
      style-class => 'lg-obj-inspector-title'
    );
    $!container.add-child($hb);
    my $label = Gnome::Shell::St::Label.new(
      text     => "Inspecting { $!obj.^name }: { $!obj.gist }"
      x-expand => True
    );
    $label.single-line-mode = True;
    $hb.add-child($label);
    my $b = Gnome::Shell::St::Button.new(
      label       => 'Insert',
      style-class => 'lg-obj-inspector-button'
    );
    $b.clicked.tap: SUB { self.onInsert }

    without $!previousObj {
      $b = Gnome::Shell::St::Button.new(
        label       => 'Back',
        style-class => 'lg-obj-inspector-button'
      );
      $hb.add-child($b);
    }

    $b = Gnome::Shell::St::Button.new(
      style-class => 'window-close',
      icon-name => 'window-close-symbolic'
    );
    $b.clicked.tap: SUB { self.close }
    $hb.add-child($b);

    if $obj.WHAT === Any {
      for $obj.^attributes.sort {
        my $link;

        {
          CATCH {
            $link = Gnome::Shell::St::Label.new( text => '<error>' );
          }

          $link = Gnome::Shell::UI::LookingGlass::ObjLink.new(
            $!lookingGlass,
            $_
          );

          my $box = Gnome::Shell::St::BoxLayout.new;
          $box.add-child( Gnome::Shell::St::Label.new(
            text => "{ .^name.subst(2) }"
          );
          $box.add-child($link);
          $!container.add-child($box);
        }
      }
    }
  }

  method open ($source) {
    return if $.real-open;

    my $g = Main.pushModal(self, %{ SHELL_ACTION_MODE_LOOKING_GLASS });
    Main.popModal($g) unless $g.seat-state == CLUTTER_GRAB_STATE_ALL;

    ($!grab, $!previousObj, $!open) = ($g, Nil, True);
    if $source {
      $.set-scale(0, 0);
      $.ease(
        scale    => 1,
        mode     => CLUTTER_EASE_OUT_QUAD,
        duration => 200
      );
    } else {
      $.set-scale(1, 1);
    }
  }

  method close {
    return unless $!open;
    Main.popModal($!grab);
    ($!grab, $!previousObject, $!obj, $!open) = False, !(Nil xx 3);
    $.hide;
  }

  method key-press-event ($e) is vfunc {
    my $s = $e.key-symbol;
    if $s === CLUTTER_KEY_ESCAPE {
      $.close;
      return CLUTTER_EVENT_STOP;
    }
    nextsame;
  }

  method onInsert {
    $.close;
    $!lookingGlass.insertObect($!obj);
  }

  method onBack {
    $.selectObject($!previousObj, True);
  }
}

class Gnome::Shell::UI::LookingGlass::Effect::RedBorder
  is   Mutter::Clutter::Effect
  does GLib::Roles::RegisterClass
{
  has $!pipeline;

  method paint_node ($n, $pc) is also<paint-node> {
    my $a  = self.actor;
    my $an = Mutter::Clutter::Node::Actor.new($a);
    $node.add-child($an);

    unless $!pipeline {
      my $fb = $pc.framebuffer;
      my $cc = $fb.context;
      my $c  = Mutter::COGL::Color.new;

      $c.init-from-4f(1, 0, 0, 196 / 255);
      ( $!pipeline = Mutter::COGL::Pipeline.new($cc) ).color = $c;
    }

    my ($a, $w) = ($a.allocation-box, 2);
    my  $pn     = Mutter::Clutter::Node::Pipeline.new($!pipeline);
    $n.add-child($pn);

    my $b = Mutter::Clutter::ActorBox.new;
    .set-origin(0, 0), .set-size($a.width, $w) given $b;
    $pn.add-rectangle($b);

    .set-origin(0, $a.height - $w), .set-size($a.width - $w, $w) given $b;
    $pn.add-rectangle($b);

    .set-origin(0, $w), .set-size($w, $a.height - $w * 2) given $b;
    $pn.add-rectangle($b);
  }
}

class Gnome::Shell::UI::LookingGlass::Inspector
  is   Mutter::Clutter::Actor
  does GLib::Roles::RegisterClass
{
  has $!eventHandler;
  has $!displayText;
  has $!grab
  has $!target;
  has $!pointerTarget;
  has $!lookingGlass    is built;

  method closed                                        is g-signal { }
  method target (MutterClutterActor, gdouble, gdouble) is g-signal { }

  submethod BUILD ( :$!lookingGlass ) {
    self.setAttributes(
      width  => 0,
      height => 0
    );

    Main.uiGroup.add-child(self);

    $!eventHandler = my $e = Gnome:::Shell::St::BoxDialog.new(
      name     => 'LookingGlassDialog',
      vertical => False,
      reactive => True
    );
    $!displayText = Gnome::Shell::St::Label.new( x-expand => True );
    self.add-child($eventHandler);

    given $!eventHandler {
      .Key-Press-Event.tap:    sub ( |a ) { self.onKeyPressEvent( |a ) }
      .Button-Press-Event.tap: sub ( |a ) { self.onKeyPressEvent( |a ) }
      .Scroll-Event.tap:       sub ( |a ) { self.onKeyPressEvent( |a ) }
      .Motion-Event.tap:       sub ( |a ) { self.onKeyPressEvent( |a ) }
    }

    $!grab = Global.stage.grab($eventHandler);
  }

  multi method new ($lookingGlass) {
    self.bless( :$lookingGlass );
  }

  method allocate ($box) is vfunc {
    $.set-allocation($box);
    return unless $!eventHandler;

    my $p = Main.layoutManager.primaryMonitor;

    my ($, $, $nw, $nh) = $!eventHandler.get-preferred-size;

    given (my $cb = Mutter::Clutter::ActorBox.new) {
      .x1 = $primary<x> + (($p<w> - $nw) / 2).floor;
      .x2 = .x1 + $nw;
      .y1 = $primary<y> + (($p<h> - $nh) / 2).floor;
      .y2 = .y1 + $nh;
    }
    $!eventHandler.allocate($cb);
  }

  method close {
    if $!grab {
      $!grab.dismiss;
      $!grab = Nil;
    }
    $!eventHandler.destroy;
    $!eventHandler = Nil;
    $.emit('closed');
  }

  method onKeyPressEvent ($a, $e) {
    $.close if $e.key-symbol == CLUTTER_KEY_Escape;
    CLUTTER_EVENT_STOP;
  }

  method onButtonPressEvent ($a, $e) {
    $.emit('target', |$e.coords) if $!target;
    $.close;
    CLUTTER_EVENT_START;
  }

  method onScrollEvent ($a, $e) {
    given $e.scrol-direction {
      when CLUTTER_SCROLL_DIRECTION_UP {
        with self.parent -> $p {
          $!target = $p;
          self.update($e);
        }
      }

      when CLUTTER_SCROLL_DIRECTION_DOWN {
        if $!target.is($!pointerTarget) {
          my $c = $!pointerTarget;
          while $c {
            my $p = $c.parent;
            last if $p.is($!target);
            $c = $p;
          }
          with $c {
            $!target = $_;
            $.update($e);
          }
        }
      }
    }
    CLUTTER_EVENT_STOP
  }

  method onMotionEvent ($a, $e) {
    $.update($e);
    CLUTTER_EVENT_STOP;
  }

  method update ($e) {
    my ($x, $y) = $e.coords;
    my  $t      = Global.stage.get-actor-at-pos(CLUTTER_PICK_MODE_ALL, $x, $y);

    $!target           = $t unless $t.is($!pointerTarget);
    $!pointerTarget    = $t;
    $!displayText.text = "[inspect x: { $x } y: { $y }] { $!target }";

    $!lookingGlass.setBorderPaintTarget($!target);
  }

}

class Gnome::Shell::UI::LookingGlass::Extensions
  is   Gnome::Shell::St::BoxLayout
  does GLib::Roles::RegisterClass
{
  has $!lookingGlass  is built;
  has $!noExtensions;
  has $!numExtensions            = 0;
  has $!extensionsList;

  submethod BUILD ( :$!lookingGlass ) {
    self.setAttributes(
      vertical => True,
      name     => 'lookingGlassExtensions'
    );

    $!noExtensions = Gnome::Shell::St::Label.new(
      style-class => 'lg-extensions-none',
      text        => 'No extensions installed'
    );
    $!extensionsList = Gnome::Shell::St::BoxLayout.new(
      vertical    => True,
      style-class => 'lg-extensions-list'
    );
    $!extensionsList.add-child($!noExtensions);
    self.add-child($!extensionsList);

    self.loadExtension($_) for Main.extensionManager.getUuids[];
    Main.extensionManager.Extension-Loaded.tap: sub ( |a ) {
      self.loadExtension( |a )
    };
  }

  multi method new ($lookingGlass) {
    self.bless( :$lookingGlass );
  }

  multi method loadExtension ($uuid) {
    samewith(Nil, $uuid)
  }

  multi method loadExtension ($o, $uuid) {
    my $e = Main.extensionManager.lookup($uuid);

    return unless ( my $name = $e.metadata<name> );

    my $ed = $.createExtensionDisplay($e);
    $!extensionList.remove-child($!noExtensions) if +$!numExtensions;

    $!numExtensions++;
    my $p = $!extensionsList.children.first({
      ( .extension.metadata<name> cmp $name ) > 0, :k
    });

    $!extensionList.insert-child-at-index($ed, $p);
  }

  method onViewSource ($a) {
    my $u = $a.extension.dir.uri;
    GIO::AppInfo.launch_default_for_uri(
      $uri,
      Global.create-app-launch-context
    );
    $!lookingGlass.close
  }

  method onWebPageActor ($a) {
    GIO::AppInfo.launch_default_for_uri(
      $a.extension.metadata<url>,
      Global.create-app-launch-context
    );
    $!lookingGlass.close;
  }

  method onViewErros ($a) {
    my $e  = $a.extension;
    my $ss = $a.shouldShow;

    if $ss {
      my $ed = Gnome::Shell::St::BoxLayout.new( :vertical );
      my @el;
      if $e.errors && $e.errors.elems {
        for $e.errors[] {
          @el.push: Gnome::Shell::St::Label.new( text => $_ );
          $ed.add-child( @el.tail );
        }
      } else {
        @el.push: Gnome::Shell::St::Label.new(
          text => "{ $e.uuid } has not emitted any errors";

        );
        $ed.add-child( @el.tail );
      }
    } else {
      $a.errorDisplay.destroy;
      ( .label, .errDisplay ) = ('Show Errors', Nil) given $a;
    }
  }

  method stateToString ($extensionState) {
    do {
      when EXTENSION_STATE_ENABLED     |
           EXTENSION_STATE_DISABLED    |
           EXTENSION_STATE_ERROR       |
           EXTENSION_STATE_OUT_OF_DATE |
           EXTENSION_STATE_DOWNLOADING |
           EXTENSION_STATE_INITIALIZED |
           EXTENSION_STATE_UNINSTALLED
      {
        .Str.split('_').tail.lc.tc
      }

      default {
        '»Unknown«'
      }
    }
  }

  method createExtensionDisplay ($e) {
    my $b = Gnome::Shell:St:BoxLayout.new(
      style-class => 'lg-externsion',
      vertical    => True
    );
    $b<extension> = $e;
    my $n = Gnome::Shell::St::Label.new(
      style-class => 'lg-extension-name',
      text        => $e.metadata<name>,
      x-expand    => True
    );
    my $d = Gnome::Shell::St::Label.new(
      style-class => 'lg-extension-description',
      text        => $e.metadata<description> || 'No description',
      x-expand    => True
    );
    my $mb = Gnome::Shell::St::BoxLayout.new( style-class => 'lg-extension-meta' );
    my $s  = Gnome::Shell::St::Label.new( style-class => 'lg-extension-state' )
    my $vs = Gnome::Shell::St::Button.new(
      reactive    => True,
      track-hover => True,
      style-class => 'shell-link',
      label       => 'View Source'
    );
    $vs<extension> = $e;
    $vs.Clicked.tap: SUB { self.onViewSource($vs) }

    my $ve = Gnome::Shell::St::Button.new(
      reactive    => True,
      track-hover => True,
      style-class => 'shell-link',
      label       => 'Show Errors',
    );
    ( .<extension>. .<parentBox>, .<isShowing> ) = ($e, $b, False) given $ve;
    $ve.Clicked.tap: SUB { self.onViewErrors($ve) }

    $b.add-child($_)  for $n, $d,  $mb;
    $mb.add-child($_) for $s, $vs, $ve;
    $b;
  }

}

class Gnome::Shell::UI::LookingGlass::Actor::Link
  is Gnome::Shell::St::Button
  does GLib::Roles::RegisterClass
{
  method Inspect-Actor is g-signal('inspect-actor') { }

  has $!actor;
  has $!arrow;

  submethod BUILD ( :$!actor ) {
    $!arrow = Gnome::Shell::St::Icon.new(
      icon-name   => 'pan-end-symbolic',
      icon-size   => 0,
      align       => CLUTTER_ACTOR_ALIGN_CENTER,
      pivot-point => Graphene::Point.new-half
    );

    my $label = Gnome::Shell::St::Label.new(
      text    => $actor.gist,
      x-align => CLUTTER_ACTOR_ALIGN_START
    );

    my $ib = Gnome::shell::St::Button.new(
      icon-name => 'insert-object-symbolic',
      reactive  => True,
      x-expand  => True,
      x-align   => CLUTTER_ACTOR_ALIGN_START,
      y-align   => CLUTTER_ACTOR_ALIGN_CENTER
    );
    $ib.Clicked.tap: SUB { self.emit('inspect-actor') }

    my $b = Gnome::Shell::St::BoxLayout.new;
    $b.add-child($_) for $!arrow, $label, $ib;

    self.setAttributes(
      reactive    => True,
      track-hover => True,
      toggle-mode => True,
      style-class => 'actor-link',
      child       => $b,
      x-align     => CLUTTER_ACTOR_ALIGN_START
    );
  }

  method clicked {
    $!arrow.ease(
      rotation-angle-z => $!arrow.checked ?? 90 !! 0
      duration         => 250
    );
  }

}

class Gnome::Shell::UI::LookingGlass::Actor::TreeViewer {
  has $!lookingGlass;

  submethod BUILD ( :$!lookingGlass ) { }

  method actorData ($a) {
    self.data<actors>{ +$a }
  }

  method deleteActorData ($a) {
    self.data<actors>{ +$a }:delete
  }

  method showActorChildren ($a) {
    return unless $.actorData($a)<visible>;
    $.actorData($a)<visible> = True;

    $.actorData($a)<actorAddedId> = $a.Child-Added.tap: sub ($c, $ch) {
      self.addActor($.actorData($a)<children>, $ch);
    }

    $.actorData($a)<removedId> = $a.ChildRemoved.tap: sub ($c, $ch) {
      self.removeActor($ch);
    }

    $.addActor($.actorData($a)<children>, $_) for $a.children
  }

  method hideActorChildren ($a) {
    return unless $.actorData($a)<visible>;

    $.removeActor($_) for $.actorData($a)<children>[];

    $.actorData($a)<visible> = False;
    $.actorData($a){ $_ }.?clear for <actorAddedId actorRemovedId>;
    $.actorData($a)<children>.remove-all-children;
  }

  method addActor ($c, $actor) {
    return with    $.actorData($actor);
    return without $!lookingGlass;

    my $b = Gnome::Shell::UI::LookingGlass::Actor::Link.new( :$actor );
    $b.notify('checked').tap: SUB {
      $!lookingGlass.setBorderPaintTarget($actor);
      $b.checked ?? self.showActorChildren($actor)
                 !! self.hideActorChildren($actor);
    }
    $b.Inspect-Actor.tap: SUB {
      $!lookingGlass.inspectObject($actor, $b);
    }

    my $mc = Gnome::Shell::St::BoxLayout.new( :vertical );
    my $cc = Gnome::Shell::St::BoxLayout.new(
      vertical => True,
      style    => 'padding: 0 0 0 18px'
    );

    $mc.add-child($_) for $b, $cc;

    self.actorData($a)<actor> = %(
      button           => $b,
      container        => $mc,
      children         => $cc,
      visible          => False,
      actorAddedId     => 0,
      actorRemovedId   => 0,
      actorDestroyedId => $a.destroy.tap( SUB { self.removeActor($a) } )
    );

    my $bc = MutterClutterActor;
    my $ns = $a.get-next-sibling;
    $bc = $.actorData($ns).container if $ns && $.actorData($ns);

    $c.insert-child-above($mc, $bc);
  }

  method removeActor ($actor) {
    return without $.actorData($actor);

    $.removeActor($_) for $actor.children[];

    $.actorData{ "actor{ $_ }Id" }.?clear for <Added Removed Destroyed>;
    $.actorData<container>.destroy;
    $.deleteActorData($actor);
  }

  method map is vfunc {
    callsame;
    $.addActor(self, Global.stage);
  }

  method unmap {
    callsame;
    $.removeActor(Global.state);
  }

}

class Gnome::Shell::UI::LookingGlass::Flag::Debug
  is   abstract
  is   Gnome::Shell::St::Button
  does GLib::Roles::RegisterClass
{
  has $!flagSwitch;
  has $!stateHandler;

  submethod BUILD ( :$label ) {
    my $box = Gnome::Shell::St::BoxLayout.new( :x-expand );
    my $fl  = Gnome::Shell::St::Label.new(
      text     => $label,
      x-expand => True,
      x-align  => CLUTTER_ACTOR_ALIGN_START,
      y-align  => CLUTTER_ACTOR_ALIGN_CENTER
    );

    $!flagSwitch   = Gnome::Shell::UO::PopupMenu::Switch.new( :!state );
    $!stateHandler = $!flagSwitch.notify('state').tap: SUB {
      $!flagSwitch.state ?? $.enable !! $.disable
    }

    $!flagSwitch.notify('mapped').tap: sub {
      return unless $!flagSwitch.is-mapped;
      return if     self.isEnabled == $!flagSwitch.state;

      $!stateHandler.disable
      $!flagSwitch.state = self.isEnabled;
      $!stteHandler.enable;
    }

    self.setAttributes(
      style-class => 'lg-debug-flag-button',
      can-focus   => True,
      toggleMode  => True,
      child       => $box,
      label-actor => $fl,
      y-align     => CLUTTER_ACTOR_ALIGN_CENTER
    );

    self.Clicked.tap: SUB { $!flagSwitch.toggle }

    $box.add-child($_) for $fl, $fs;
  }

  method isEnabled {
    X::Method::NYI.new.throw
  }

  method enable {
    X::Method::NYI.new.throw
  }

  method disable {
    X::Method::NYI.new.throw
  }
}


class Gnome::Shell::UI::LookingGlass::Flag::Clutter::Debug
  is   Gnome::Shell::UI::LookingGlass::Flag::Debug
  does GLib::Roles::RegisterClass
{
  has $!argPos;
  has $!enumValue;

  submethod BUILD ( :$categoryName, :$flagName ) {
    $!argPos    = .{$categoryName}.argPos;
    $!enumValue = MutterClutterDebugFlagEnum.enums{$flagName}
  }

  method isEnabled {
    Meta::Util.get-clutter-debug-flags[$!argPos] +& $!enumValue
  }

  method getArgs {
    my $a = [0, 0, 0];
    $a[$!argPos] = $!enumValue;
    $a
  }

  method enable {
    Meta::Util.add-clutter-debug-flags( |$.getArgs );
  }

  method disable {
    Meta::Util.remove-clutter-debug-flags( |$.getArgs )
  }
}

class Gnome::Shell::UI::LookingGlass::Flag::Mutter::Paint::Debug
  is   Gnome::Shell::UI::LookingGlass::Flag::Debug
  does GLib::Roles::RegisterClass
{
  has $!enumValue;

  submethod BUILD ( :$flagName ) {
    $!enumValue = MutterMetaDebugPaintFlagEnum.enums{$flagName};
  }

  multi method new ( :flagName(:$label) ) {
    samewith($label);
  }
  multi method new ($label) {
    self.bless(
      label    => $label,
      flagName => $label
    );
  }

  method enable {
    Meta::Util.add-debug-paint-flag($!enumValue );
  }

  method disable {
    Meta::Util.remove-debug-paint-flag($!enumValue)
  }
}

class Gnome::Shell::UI::LookingGlass::Flag::Mutter::Topic::Debug
  is   Gnome::Shell::UI::LookingGlass::Flag::Debug
  does GLib::Roles::RegisterClass
{
  has $!enumValue;

  submethod BUILD ( :$flagName ) {
    $!enumValue = MutterMetaDebugTopicEnum.enums{$flagName}
  }

  multi method new ( :flagName(:$label) ) {
    samewith($label);
  }
  multi method new ($label) {
    self.bless(
      label    => $label,
      flagName => $label
    );
  }

  method enable {
    Meta::Util.add-verbose-topic($!enumValue);
  }

  method disable {
    Meta::Util.remove-verbose-topic($!enumValue);
  }

}

class Gnome::Shell::UI::LookingGlass::Flag::UnsafeMode::Debug {
  is   Gnome::Shell::UI::LookingGlass::Flag::Debug
  does GLib::Roles::RegisterClass
{
  method new {
    self.bless(
      label => 'unsafe-mode'
    )
  }

  method isEnabled { Global.context.unsafe-mode         }
  method enable    { Global.context.unsafe-mode = True  }
  method disable   { Global.context.unsafe-mode = False }
}

class Gnome::Shnell::UI::LookingGlass::DebugFlags
  is   Gnome::Shell::St::BoxLayout
  does GLib::Roles::RegisterClass
{

  submethod BUILD {
    self.setAttributes(
      name     => 'lookingGlassDebugFlags',
      vertical => True,
      x-align  => CLUTTER_ACTOR_ALIGN_CENTER
    );

    for CLUTTER_DEBUG_FLAG_CATEGORIES.pairs {
      my ($categoryName, $vals) = ( .key, .value );
      self.addHeader("Clutter{ $categoryName }");
      for self.getFlagNames($vals)[] -> $flagName {
        next if .<exclude>.first($flagName);
        self.add-child(
          Gnome::Shell::UI::LookingGlass::Flag::Clutter::Debug.new(
            :$categoryName,
            :$flagName
          )
        )
      }
    }

    self.addHeader('MetaDebugPaintFlag');
    self.add-child(
      Gnome::Shell::UI::LookingGlass::Flag::Mutter::Paint::Debug.new(
        .value
      )
    ) for self.getFlagNames(MutterMetaDebugPaintFlagEnum)[]

    self.addHeader('MetaDebugTopic');
    self.add-child(
      Gnome::Shell::UI::LookingGlass::Flag::Mutter::Topic::Debug.new( .value )
    ) for self.getFlagNames(MutterMetaDebugTopicEnum)[]

    self.addHeader('MetaContext');
    self.add-child(
      Gnome::Shell::UI::LookingGlass::Flag::UnsafeMode::Debug.new
    );

  }

  method addHeader ($title) {
    my $h = Gnome::Shell::St::Label.new(
      text        => $title,
      style-class => 'lg-debug-flags-header',
      x-align     => CLUTTER_ACTOR_ALIGN_START
    );
    $.add-child($h);
  }

  method getFlagNames (\enum) {
    enum.enums.pairs
  }

}

class Gnome::Shell::UI::LookingGlass
  is   Gnome::Shell::St::BoxLayout
  does GLib::Roles::RegisterClass
{
  has $!actorTreeViewer;
  has $!autoComplete;
  has $!borderPaintTarget;
  has $!debugFlags;
  has $!entry;
  has $!entryArea;
  has $!evalBox;
  has $!extensions;
  has $!history;
  has $!interfaceSettings;
  has $!maxItems;
  has $!notebook;
  has $!objInspector;
  has $!offset;
  has $!redBorderEffect;
  has $!resultsArea;
  has $!windowList;

  has $.open;
  has $.it;

  constant RB  = Gnone::Shell::UI::LookingGlass::Effect::RedBorder;
  constant N   = Gnome::Shell::UI::LookingGlass::Notebook;
  constant WL  = Gnome::Shell::UI::LookingGlass::WindowList;
  constant E   = Gnome::Shell::UI::LookingGlass::Extensions;
  constant AT  = Gnome::Shell::UI::LookingGlass::Actor::TreeViewer;
  constant D   = Gnome::Shell::UI::LookingGlass::Flags::Debug;
  constant AC  = Gnome::Shell::UI::LookingGlass::AutoComplete;
  constant R   = Gnome::Shell::UI::LookingGlass::Result;
  constant Sg  = Gnome::Shell::St::Settings;

  submethod BUILD {
    self.setAttributes(
      name        => 'LookingGlassDialog',
      style-class => 'lg-dialog',
      vertical    => True,
      visible     => True,
      reactive    => True
    );

    ($!open, $!redBorderEffect, $!offset, $!maxItems) =
      (False, RB.new, 0, 150);

    $!interfaceSettings = GIO::Settings.new('org.gnome.desktop.interface');
    $!interfaceSettings.Changed('monospace-font-name').tap: SUB {
      self.updateFont;
    }
    self.updateFont;

    .add-child(self), .set-child-below-sibling(
      self,
      Main.layoutManager.panelBox
    ) given Main.uiGroup;

    .notify('allocation').tap(
      SUB { self.queueResize }
    ) for Main.layoutManager.panelBox, Main.layoutManager.keyboardBox;

    $!objInspector = Gnome::Shell::UI::LookingGlass::ObjInspector.new(self);
    Main.uiGroup.add($!objInspector);
    $!objInspector.hide;

    my $toolbar = Gnome::Shell;:St::BoxLayout.new( name => 'Toolbar' );
    self.add-child($toolbar);
    my $ib = Gnome::Shell::St::Button.new(
      style-class => 'lg-toolbar-button',
      icon-name   => 'find-location-symbolic'
    );
    $toolbar.add-child($ib);
    $ib.Clicked.tap: SUB {
      my $i = Gnome::Shell::UI::LookingGlass::Inspector.new(self);
      $i.Target.tap: sub ($i, $t, $x, $y) {
        self.pushResult("inspect({ $x.round }, { $y.round })", $t);
      }
      $i.Closed.tap: SUB {
        self.show;
        Global.stage.set-key-focus($!entry);
      }
      self.hide;
      CLUTTER_EVENT_STOP;
    }

    my $gc = Gnome::Shell::St::Button.new(
      style-class => 'lg-toolbar-button',
      icon-name   => 'user-trash-full-symbolic'
    );
    $toolbar.add-child($gc);
    $gc.Clicked.tap: SUB {
      $gc.child.icon-name = 'user-trash-symbolic';
      System.gc;
      $!timeoutId = GLib::Timeout.add(
        500,
        name => '[gnome-shell] full trash gc.child.icon-name',
        $gc.child.icon-name = 'user-trash-full-symbolic';
        $!timeoutId.clear
        G_SOURCE_REMOVE
      );
      CLUTTER_EVENT_PROPAGATE
    }

    self.add-child($!notebook = N.new);
    $!notebook.appendPage(
      'Evaluator',
      $!evalBox = Gnome::Shell::St::BoxLayout.new(
        name    => 'EvalBox',
        verticl => True
      );
    );

    $!evalBox.add-child(
      $!resultsArea = Gnome::Shell::St::BoxLayout.new(
        name     => 'ResultsArea',
        vertical => True,
        y-expand => True
      )
    );

    $!evalBox.add-child(
      $!entryArea = Gnome::Shell::St::BoxLayout.new(
        name => 'EntryArea',
        y-align => CLUTTER_ACTOR_ALIGN_END
      )
    );

    $!entryArea.add-child(
      my $l = Gnome::Shell::St::Label( text => CHEVRON )
    );

    $!entryArea.add-child(
      $!entry = Gnome::Shell::St::Entry.new(
        can-focus => True,
        x-expand  => True
      )
    );
    ShellEntry.addContextMenu($!entry);

    $!notebook.appendPage('Windows',    $!windowList      = WL.new);
    $!notebook.appendPage('Extensions', $!extensions      = E.new);
    $!notebook.appendPage('Actors',     $!actorTreeViewer = AT.new);
    $!notebook.appendPage('Flags',      $!debugFlags      = D.new);

    $!entry.clutter-text.Activate.tap: sub ($o, $e, $r) {
      self.hideCompletions;
      my $t = $o.text.subst("\n", ' ', :g);

      {
        CATCH {
          default {
            $*ERR.say: "{ .message }\n{ .backtrace.concise }"
          }
        }

        self.evaluate($text)
      }
      $r.r = True
    }

    $!history = Gnome::Shell::Misc::HistoryManager {
      gsettingsKey => HISTORY_KEY,
      entry        => $!entry.clutter-text
    );

    ( $!autoComplete = AC.new($!entry) ).Suggest.tap: sub ($a, $e) {
      self.showCompletions($e.completions);
    }

    $!autoComplete.Completion.tap: sub ($a, $e) {
      self.hideCompletions if $e.type eq 'whole-word';
    }

    self.resize
  }

  method captured-event ($e) {
    return CLUTTER_EVENT_STOP if Main.keyboard.maybeHandleEvent($e);

    CLUTTER_EVENT_PROPAGATE;
  }

  method updateFont {
    my $n = $!interfaceSettings.get-string('monospace-font-name');
    my $d = Pango::FontDescription.from-string($n);
    my $s = $d.size / 1025;
    my $u = $size-is-absolute ?? 'px' !! 'pt';

    self.style = qq:to/CSS/.chomp;
      font-size:   { $s }{ $u };
      font-family: { $d.family };
      CSS
  }

  method setBorderPaintTarget ($o) {
    $!borderPaintTarget.remove-effect(self.redBorderEffect)
      with $!borderPaintTarget;
    $!borderPaintTarget = $o;
    $!borderPaintTarget.add-effect(self.redBorderEffect)
      with $!borderPaintTarget;
  }

  method pushResult ($c, $o) {
    my $r = R.new(
      lookingGlass => self,
      command      => CHEVRON ~ $c,
      obj          => $o,
      index        => $!resultsArea.elems + $!offset
    );

    self.setBorderPaintTarget($o) if $o ~~ Mutter::Clutter::Actor;

    if $!resultsArea.elems > $!maxItems {
      $!resultsArea.first-child.destroy;
      $!offset++;
    }
    $!it = $o;
    $!notebook.scrollToBottom(0);
  }

  method showCompletions ($c) {
    unless $!completionActor {
      $!completionActor = Gnome::Shell::St::Label.new(
        name        => 'LookingGlassAutoCompletionText',
        style-class => 'lg-completions-text'
      );
      ( .ellipsize, .line-wrap ) = (PANGO_ELLIPSIZE_NONE, True)
        given $!completionActor.clitter-text;

      $!evalBox.insert-child-below($!completionActor, $!entryArea);
    }

    ( .text, .height ) = ( $c.join(', '), -1 ) given $!completionActor;

    my ($, $nh) = $!completionActor.get-preferred-height($!resultsArea.width);

    if $!completionActor.visible {
      $!completionActor.height = $nh;
    } else {
      my $s = Sg.get;
      my $d = AUTO_COMPLETE_SHOW_COMPLETION_ANIMATION_DURATION /
              $s.slow-down-factor;
      given $!completionActor {
        .show, .remove-all-transitions,
        .ease(
          height   => $nh,
          opacity  => 255,
          duration => $d,
          mode     => CLUTTER_EASE_OUT_QUAD
        );
      }
    }
  }

  method hideCompletions {
    return unless $!completionActor;

    my $s = Sg.get;
    my $d = AUTO_COMPLETE_SHOW_COMPLETION_ANIMATION_DURATION /
            $s.slow-down-factor;

    given $!completionActor {
      .remove-all-transitions;
      .ease(
        height     => 0,
        opacity    => 0,
        duration   => $d,
        mode       => CLUTTER_EASE_OUT_QUAD,
        onComplete => SUB { $!completionActor.hide }
      );
    }
  }

  method evaluate ($c) {
    use MONKEY-SEE-NO-EVAL;

    start {
      my $cmd = $!history.addItem($c);
      return unless $cmd;
      $cmd = $commandHeader ~ $cmd;

      my $ro;
      try {
        CATCH {
          default {
            $ro = "<exception { $e.gist }">
          }
        }

        $ro = EVAL($cmd);
      }
      $!pushResult($cmd, $ro);
      $!entry.text = '';
    }

  }

  method inspect ($x, $y) {
    Global.stage.get-actor-at-pos(CLUTTER_PCK_MODE_REACTIVE, $x, $y);
  }

  method getResult ($i) {
    CATCH {
      default {
        X::Gnome::Shell::Error.new(
          "Unknown result at index { $i }: { .message }"
        ).throw
      }
    }

    $!resultsArea.get-child-at-index($i - $!offset).o
  }

  method toggle {
    $!open ?? $.close !! $.open;
  }

  method queueResize {
    Global.compositor.laters.add(
      sub {
        self.resize;
        G_SOURCE_REMOVE
      }
    );
  }

  method resize {
    my    $p  = Main.layoutManager.primaryMonitor;
    my    $mw = $p.width * 0.7;
    my    $ah = $p.height - Main.layoutManager.keyboardBox.height;
    my    $mh = min($p.height * 0.8, $ah * 0.9);
          $.x = $p.x + ($p.width - $mw) / 2;
    $!hiddenY = $p.y + Main.layoutManager.panelBox.height - $mh;
    $!targetY = $!hiddenY + $mh;
          $.y = $!hiddenY;
      $.width = $mw;
     $.height = $mh;

    $!objInspector.set-size( |(($mw, $mh) »*» 0.8)».Int );
    $!objInspector.set-position(
      $.x       + ($mw * 0.1).Int,
      $!targetX + ($mh * 0.1).Int
    );
  }

  method insertObject ($o) {
    $.pushResult('<insert>', $o);
  }

  method inspectObject ($o, $a) {
    .open($a), .selectObject($o) given $!ibjInspector;
  }

  method key-press-event ($e) is vfunc {
    given $e.key-symbol {
      when CLUTTER_KEY_Escape {
        $.close;
        return CLUTTER_EVENT_STOP;
      }

      when $e.state +& CLUTTER_MODIFIER_CONTROL_MASK {
        when CLUTTER_KEY_Page_Up   { $!notebook.prevTab }
        when CLUTTER_KEY_Page_Down { $!notebook.nextTab }
      }
    }
    nextsame
  }

  method open {
    return if $!open;

    my $g = Main.pushModal(
      self,
      %{ actionMode => SHELL_ACTION_MODE_LOOKING_GLASS }
    );
    if $g.seat-state == CLUTTER_GRAB_STATE_ALL {
      Main.popModal($g);
      return;
    }

    ($!grab, $!open) = ($g, True);
    $!notebook.selectIndex(0);
    $.show;
    $!history.lastItem;
    $.remove-all-transitions;

    my $d = LG_ANIMATION_TIME / Sg.get.slow-down-factor;
    $.ease(
      y        => $!targetY,
      duration => $d,
      mode     => CLUTTER_EASE_OUT_QUAD
    _;

    $!windowList.update;
    $!entry.grab-key-focus;
  }

  method close {
    return unless $!open;

    $!objInspector.hide;
    $.remove-all-transitions;
    $.unsetBorderPaintTarget;
    $!open = False;

    my $d = min(
      LG_ANIMATION_TIME / Sg.get.slow-down-factor,
      LG_ANIMATION_TIME
    )

    $.ease(
      y          => $!hiddenY,
      duraton    => $d,
      mode       => CLUTTER_EASE_OUT_QUAD,
      onComplete => SUB {
        Main.popModal($!grab);
        $!grab = Nil;
        $.hide
      }
    );
  }

}
