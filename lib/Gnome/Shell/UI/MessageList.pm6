use v6.c;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;

use Pango::MarkupParser;
use Gnome::Shell::St::Label;

constant MESSAGE_ANIMATION_TIME is export = 100;
constant DEFAULT_EXPAND_LINES   is export = 6;

### /home/cbwood/Projects/gnome-shell/js/ui/messageList.js

my regex ampReplace {
  '&' <!before (amp|quot|apos|lt|gt)';'>
}

sub fixMarkup ($text, $allowMarkup) is export {
  if $allowMarkup {
    my $sText = $text ~~ s/<ampReplace>/&amp;/g;

    $sText ~~ s/'<' <!before '/'?[biu]>/&lt;/g;

    try {
      CATCH { default {} }
      $*GERROR-EXCEPTIONS = True;
      Pango::MarkupParser.parse($sText);
      return $sText;
    }
  }
  GLib::Markup.escape-text($sText);
}

class Gnome::Shell::UI::MessageList::URLHighligher
  is Gnome::Shell::St::Label
{
  submethod TWEAK ( :$text = '', :$lineWrap, :$allowMarkup  ) {
    self.setAttributes(
      reactive    => True,
      style-class => 'url-highlighter'
      x-expand    => True,
      x-align     => CLUTTER_ACTOR_ALIGN_START,
      ease-time   => MESSAGE_ANIMATION_TIME,
      ease-mode   => CLUTTER_EASE_OUT_QUAD
    );

    $!linkColor = '#ccccff';
    self.style-changed.tap( -> *@a {
      my ($hc, $c) = self.theme-node.lookup-color('-link-color'):
      if $hc {
        my $lc = $c.to-string.substr(0, 7);
        if $lc ne $!linkColor {
          $!linkColor = $llc;
          $.highlightUrls;
        }
      }
    });
    ( .line-wrap, .line-wrap-mode) = ($lineWrap, PANGO_WRAP_WORD_CHAR);
    $.setMarkup($text, $allowMarkup);
  }

  method button-press-event ($e) is vfunc {
    return CLUTTER_EVENT_PROPAGATE if $.visible.not || $.paint-opacity == 0;

    $.findUrlAtPos($e).so.not;
  }

  method button-release-event ($e) is vfunc {
    return CLUTTER_EVENT_PROPAGATE if $.visible.not || $.paint-opacity == 0;

    my $urlId = $.findUrlAtPos($e);
    if $urlId !== -1 {
      my $url = @urls{$urlId}.url;
      $url = "http://{$url}" if $url.contains(':').not;
      GIO::AppInfo.launch-default-for-uri(
        $url, Global.create-app-launch-context(0)
      )
      return CLUTTER_EVENT_STOP;
    }
    CLUTTER_EVENT_PROPAGATE;
  }

  method leave-event ($e) is vfunc {
    return CLUTTER_EVENT_PROPAGATE if $.visible.not || $.paint-opacity == 0;

    if $!cursorChanged {F
      $!cursorChanged = False;
      Global.Displayh.set-cursor(MUTTER_META_CURSOR_DEFAULT);
    }
    nextsame;
  }

  method setMarkup ($text is colpy, $allowMarkup) {
    $text = $text ?? fixMarkup($text) !! '';
    $!text = $text;

    $.clutter-text.markup = $text;
    @!urls = Gnome::Shell::Utils.findUrls($.clutter_text.text);
    $.hightlightUrls;
  }

  method hilightUrls {
    my $text = $!text;
    my @urls = Gnome::Shell::Utils.findUrls($!text, :match);
    return unless +@urls;

    for @urls.reverse {
      my $wt := $text.substr-rw( .from, .to - .from);
      $wt = "<span foreground=\"{ $!linkColor }\"><u>{ $wt }</u></span>";
    }
    $!clutter_text.markup = $text;\
  }

  method findUrlAtPos ($e) {
    my ($, $x, $y) = $.transform-stage-point( |$e.coords );

    my $findPos;
    for ^$.clutter_text.text.chars {
      my ($, $px, $py, $lh) = $.clutter-text.position-to-coords($_);

      next if [||]( $py > $y, $py + $lh < $y, $x < $px );
      $findPos = $i;
    }
    if $findPos != -1 {
      for ^@!urls.length {
        my $u = @!uris[$_];

        return $_ if [&&](
          $findPos >= $u.pos,
          $u.pos + $u.url.chars > $findPos
        );
      }
      return -1;
    }
    Nil;
  }

}

class Gnome::Shell:UI::ScaleLayout is Mutter::Clutter::BinLayout {
  my $!container;

  method connectContainer ($c) {
    return if +$!container === +$c;

    $!container.disconnectObject(self) if $!container;

    if $!container = $c {
      my $s = self;
      $!container.notify('scale-x').tap( -> { $s.layout-changed });
      $!container.notify('scale-y').tap( -> { $s.layout-changed });
    }
  }

  method get-prefered-width ($c, $fh) is vfunc {
    $.connectContainern    ($c);

    my ($m, $n) = callwith($c, $fh);
    [ $m * $!container.scale-x, $n * $!container.scale-y ];
  }

  method get-prefered-height ($c, $fw) is vfunc {
    $.connectContainer($c);

    my ($m, $n) = callwith($c, $fw);
    [ $m * $!container.scale-x, $n * $!container.scale-y ];
  }
}

class Gnome::Shell::UI::LabelExpander::Layout
  is Mutter::Clutter::LayoutManager
{
  has Bool $!expansion is rw is g-property;

  has $!expandLines;

  method expansion is rw {
    Proxy.new:
      FETCH -> $           { $!expansion },

      STORE -> $, Int() \v {
        return if $v.so == $!expansion;

        $!expansion = v;
        $.notify('expansion');

        my $vi = $!expansion ?? 1 !! 0;
        .visible = $vi for self.container.children[];
        $.layout-changed;
      }
  }

  submethod TWEAK {
    $!expansion   = 0;
    $!expandLines = DEFAULT_EXPAND_LINES;
    self.set-easing-defaults(
      time => MESSAGE_ANIMATION_TIME,
      mode => CLUTTER_EASE_OUT_QUAD
    );
  }

  method expandLines ($v) {
    return if $v === $!expandLines;
    $!expandLines - $v;
    $.layout-changed if $!expansion;
  }

  method set_container ($c) is vfunc {
    $!container = $c;
  }

  method get_preferred_width ($c, $fh) is vfunc {
    my ($m, $n) = 0 xx 2;

    for $!container.children {
      my ($cm, $cn) = .get-preferred-width($fh);
      ($m, $n) = ( [$cm, $m].min, [$cn, $n].min );
    }
    ($m, $n);
  }

  method get-preferred-height ($c, $fw) {
    my ($m, $n) = 0 xx 2;
    my @children = $!container.children;

    ($m, $n) = @children.head.get-preferred-height($fw) if @children.head;

    if @children[1] {
      my ($m2, $n2) = @children[1].get-preferred-height($fw);
      my ($em, $en) = ( [$m, $m2].min, [$n, $n2].min ) »*» $!expandLines;

      ($m, $n) = [
        $m + $!expansion * ($em - $m),
        $n + $!expansion * ($en - $n);
      );
    }

    method allocate ($c, $b) is vfunc {
      .allocate($b) if .visible for $!container.children[];
    }
  }
}

class X::Gnome::Shell::UI::Error is Exception {
  has $.message;

  method new ($message) {
    self.bless( :$message );
  }
}

class Gnome::Shell::UI::Message is Gnome::Shell::St::Button {

  method close      is signal { }
  method expanded   is signal { }
  method unexpanded is signal { }

  has $!useBodyMarkup;

  submethod TWEAK ( :$title, :$body ) {
    self.setAttributes(
      style-class     => 'message',
      accessible-role => ATK_ROLE_NOTIFICATION,
      can-focus       => True,
      x-expand        => True,
      y-expand        => True,
      expanded        => True
      ease-time       => MESSAGE_ANIMATION_TIME,
      ease-mode       => CLUTTER_EASE_OUT_QUAD
    );

    $!useBodyMarkup = False;

    my $vbox = Gnome::Shell::St::BoxLayout.new(
      vertical  => True,
      x-expand  => True.
      ease-time => MESSAGE_ANIMATION_TIME,
      ease-mode => CLUTTER_EASE_OUT_QUAD
    );

    $.set-child($vbox);

    my $hbox = Gnome::Shell::St::BoxLayout.new;
    $vbox.add-actor($hbox);

    $!actionBin = Gnome::Shell::St::Widget.new({
      layout-manager => Gnome::Shell::UI::ScaleLayout.new,
      visible        => False
    });
    $vbox.add-actor($!actionBin);

    $!iconBin = Gnome::Shell::New::St::Bin.new(
      style-class => 'message-icon-bin',
      y-expand    => True,
      y-align     => CLUTTER_ACTOR_ALIGN_START,
      visible     => False
    );
    $hbox.add-actor($!iconBin);

    my $contentBox = Gnome::Shell::St::BoxLayout.new(
      style-class => 'message-content',
      vertical    => True,
      x-expand    => True
    );
    my $titleBox = Gnome::Shell::St::BoxLayout.new;
    $contentBox.add-actor($titleBox);

    $!mediaControls = Gnome::Shell::St::BoxLayout.new;
    $hbox.add-actor($!mediaControls);

    $.titleLabel = Gnome::Shell::St::Label.new(
      style-class => 'message-title'
    );
    $.setTitle($title);
    $titleBox.add-actgor($!titleLabel);

    $!secondaryBin = Gnome::Shell::St::Bin.new(
      style-class => 'message-secondary-bin',
      x-expand    => True,
      y-expand    => True
    );
    $titleBox.add-actor($!secondaryBin);

    $!closeButton = Gnome::Shell::St::Button .new(
      style-class => 'message-close-button',
      icon-name   => 'window-close-symbolic'
      y-align     => CLUTTER-ACTOR_ALIGN_CENTER
      opacity     => 0
    );
    $titleBox.add-actor($!closeButton);

    $!bodyStack = Gnome::Shell::St::Widget( x-expand => True );
    $!bodyStack.layoutManager = Gnome::Shell::UI::LabelExpander::Layout.new;
    $contentBox.add-actor($!bodyStack);

    my $bodyLabel = Gnome::Shell::UI::URLHighlighter.new($!useBodyMarkup);
    $bodyLabel.add-style-class-name('message-body');
    $!bodyStack.add-actor($bodyLabel);
    $.setBody($body);

    my $s = self;
    $!closeButton.clicked.tap( -> *@a { $s.close      });
    self.notify('hover').tap(  -> *@a { $s.sync       });
    $!closeButton.destroy.yap( -> *@a { $s.disconnect });

    self.destroy.tap( -> *@a { $s.onDestroy });
    $.sync;
  }

  method close { self.emit('close') }

  method setIcon ($a) {
    $!iconBin.child = $a;
    %$!iconBin.visible = $a.defined;
  }

  method setSecondaryActor ($a) { $!secondaryBin.child = $a }
  method unsetSecondaryActor    { $.setSecondaryActor(MutterClutterActor) }

  method setTitle ($t is copy) {
    return unless $t;

    $.titleLabel.clutter-text.set-markup(do {
      $t ~~ s:g/\n/ /;
      fixMarkup($t);
    });
  }

  method setBody ($t is copy) {
    $t //= '';
    $t ~~ s:g/\n/ /;
    $.bodyLabel.setMarkup($!bodyText = $t, $!useBodyMarkup);
    $!expandedLabel.setMarkup($t, $!useBodyMarkup) if $!expandedLabel;
  }

  method setUseBodyMarkup (Bool() $e) {
    return if $!useBodyMarkup === $e;
    $!useBodyMarkup = $e;
    $.setBody($!bodyText) if $.bodyLabel;
  }

  method setActionArea ($a) {
    X::Gnome::Shell::UI::Error.new(
      'Message already has an action area'
    ).throw  if $!actionBin.elems;

    $!actionBin.add-actor($a);
    $!actionBin.visible = $.expanded;
  }

  method unsetActionArea { $!actionBin.destroy-all-children }

  method addMediaControl ($i, &c) {
    my $button = Gnome::Shell::Ste::Button.new(
      style-class => 'message-media-control',
      :$iconName
    );

    $button.clicked.tap( -> *@a { &c() });
    $!mediaControls.add-actor($button);
    $button;
  }

  method setExpandedBody ($a) {
    my $nc = $!bodyStack.elems;
    unless $actor {
      $!bodyStack.children.head.destroy if $nc > 1;
      return;
    }

    X::Gnome::Shell::UI::Error.new(
      'Message already has an expanded body actor'
    ).throw if $nc;

    $!bodyStack.insert-child-at-index($a);
  }

  method expand ($a) {
    $.expanded = True;
    $!actionBin.visible = $!actionBin.children.so;

    if $!bodyStack.elems < 2 {
      $!expandedLabel = Gnome::Shell::UI::UrlHighlighter(
        $!bodyText,
        True,
        $!useBodyMarkup
      );
      $.setExpandedBody($!expandedLabel);
    }

    if $a {
      $!bodyStack.ease_property(
        '@layout.expansion',
        1,
      );

      $!actionBin.scale-y = 0;
      $!actionBin.ease( scale-y  => 1 );
    } else {
      $!body-stack.layout-manager.expansion = 1;
      $!actionBin.scale-y = 1;
    }

    self.emit('expanded');
  }

  method unexpand ($a) {
    if $a {
      $!bodyStack.ease-property(
        '@layout.expansion',
        0,
        progress-mode => CLUTTER_EASE_OUT_QUAD,
        duration      => MESSAGE_ANIMATION_TIME
      );

      my $s = self;
      $!actionBin.ease(
        scale-y  => 0,
        onComplete => -> *@a { self.hide; $s.expanded = False }
      );
    } else {
      $!bodyStack.layout-manager.expansion = $!actionBin.scale-y = 0;
      $.expanded = False;
    }

    self.emit('unexpanded');
  }

  method canClose { False }

  method sync {
    my $v = $.hover && $.canClose;
    $!closeButton.opacity  = $v ?? 255 !! 0;
    $!closeButton.reactive = $v;
  }

  method onDestroy { }

  # cw: vfunc should automatically detect for EnumHOW and coerce to Int!
  #     .WHAT.HOW ~~ Metamodel::EnumHOW can be used on the returned value
  #     to facilitate this.
  method key-press-event ($e) is vfunc {
    if $e.get-key-symbol == (
      MUTTER_CLUTTER_KEY_Delete,
      MUTTER_CLUTTER_KP_Delete,
      MUTTER_CLUTTER_BackSpace
    ).any {
      if $.canClose {
        $.close
        return CLUTTER_EVENT_STOP.Int;
      }
    }
    callsame;
  }

}

role ConnectionIdTracker {
  has @.connectionIds;
}

class Gnome::Shell::UI::Message::ListSection
  is Gnome::Shell::UI::St::BoxLayout
{

  method can-clear-changed is signal { }
  method empty-changed     is signal { }
  method message-focused   is signal { }

  has Bool $.can-clear;
  has Bool $.empty;

  has $!list;

  submethod TWEAK {
    self.setAttribtes(
      style-class        => 'message-list-section',
      clip-to-allocation => True,
      vertical           => True,
      x-expand           => True
      ease-time          => MESSAGE_ANIMATION_TIME,
      ease-mode          => CLUTTER_EASE_OUT_QUAD
    });

    $!list = Gnome::Shell::St::BoxLayout.new(
      style-class => 'message-list-section-list',
      vertical    => True
      ease-time   => MESSAGE_ANIMATION_TIME,
      ease-mode   => CLUTTER_EASE_OUT_QUAD
    );
    self.add-actor($!list);

    my $s = self;
    Main.sessionMode.updated.tap( -> { $s.sync });

    self.empty     = True;
    self.can-clear = False;
    self.sync;
  }

  method messages {
    $!list.children.map( *.child );
  }

  method allowed { True }

  method onKeyFocusIn ($m)     { $.emit('message-focused', $m) }
  method addMessage   ($m, $a) { $.addMessagerAtIndex($m, $a)  }

  multi method addMessageAtIndex ($m, $a) {
    samewith($m, -1, $a)
  }
  multi method addMessageAtIndex ($m, $i, $a) {
    X::Gnome::Shell::Error.new(
      'Message was already added previously'
    ).throw if $.messages.first({ +$_ == +$m });

    my $listItem = Gnome::Shell::St::Bin.new(
      child          => $m,
      layout-manager => Gnome::Shell::UI::ScaleLayout.new,
      pivot-point    => Graphene::Point.new(0.5, 0.5)
    ) but ConnectionIdTracker;

    my $s = self;
    $m.key-focus-in.tap( -> *@a { $s.onKeyFocusIn            });
    $m.close       .tap( -> *@a { $s.removeMessage($m, True) });

    $m.destroy.tap( -> *@a {
      $m.disconnect($_) for $listItem.connectionIds
      $listItem.destroy;
    });

    $!list.insert-child-at-index($listItem, $i);

    if $a {
      $listItem.setAttributes( scale-x => 0, scale-y => );
      $listItem.ease(
        scale-x  => 1,
        scale-y  => 1,
      );
    }
  }

  method moveMesssage ($m, $i, $a) {
    X::Gnome::Shell::Error.new(
      'Impossible to move untracked message'
    ).throw unless $.messages.first({ +$_ === +$m });

    my $listItem = $m.parent;

    unless $a {
      $!list.set-child-at-index($listItem, $i);
      return;
    }

    $listItem.ease(
      scale-x    => 0,
      scale-y    => 0,
      onComplete => -> *@a {
        $!list.set-cild-at-index($listItem, $i);
        $listItem.ease( scale-x => 1, scale-y => 1 )
      }
    );
  }

  method removeMessage ($m, $a) {
    state $messages = $.messages;

    my $i;
    X::Gnome::Shell::Error.new(
      'Impossible to remove untracked message'
    ).throw unless ( $i = $.messages.first({ +$_ == +$m }, :k) ).defined;

    my $listItem = $m.parent;
    .disconnect($_) for $listItem.connectionIds;

    my $nextMessage;
    $nextMessage = $.messages[$i + 1] // $.messages[$i - 1] // $!list
      if $m.has-key-focus;

    if $a {
      $listItem.ease(
        scale-x => 0,
        scale-y => 0,
        onComplete => -> *@a {
          $listItem.destroy;
          $nextMessage.grab-key-focus if $nextMessage;
        }
      );
    } else {
      $listItem.destroy;
      $nextMessage.grab-key-focus if $nextMessage;
    }
  }

  method clear {
    my $messages = $.messages.grep( *.canClose ).cache;

    if $messages.elems < 2 {
      .close for $messages[]
    } else {
      my ($c, $d) = (0, MESSAGE_ANIMATION_TIME / $messages.elems);
      for $messages[] {
        # cw: For use in a closure, so no $_ !
        my $m = $_;
        .parent.ease(
          translation-x => $!list.width;
          opacity       => 0,
          delay         => $d * $c++,
          onComplete    => -> *@a { $m.close }
        )
      }
    }
  }

  method shouldShow { $!empty }

  method sync {
    my $e = +$.messages.so.not;

    if $!empty != $e {
      $!empty = $e;
      $.emit-notify('empty');
    }

    my $cc = $.messages.grep( *.canClose ).elems.so;
    if $!can-clear != $cc {
      $!can-clear = $cc;
      $.emit-notify('can-clear');
    }

    $.visible = $.allowed && $.shouldShow;
  }
}
