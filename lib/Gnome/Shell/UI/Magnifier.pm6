use v6;

use Mutter::Clutter::Color;
use Mutter::Clutter::PaintNodes;
use Gnome::Shell::Raw::Types;

use Gnome::Shell::UI::Background;

constant CROSSHAIRS_CLIP_SIZE      = [100, 100];
constant NO_CHANGE                 = 0.0;
constant POINTER_REST_TIME         = 1000;
constant MAGNIFIER_SCHEMA          = 'org.gnome.desktop.a11y.magnifier';
constant SCREEN_POSITION_KEY       = 'screen-position';
constant MAG_FACTOR_KEY            = 'mag-factor';
constant INVERT_LIGHTNESS_KEY      = 'invert-lightness';
constant COLOR_SATURATION_KEY      = 'color-saturation';
constant BRIGHT_RED_KEY            = 'brightness-red';
constant BRIGHT_GREEN_KEY          = 'brightness-green';
constant BRIGHT_BLUE_KEY           = 'brightness-blue';
constant CONTRAST_RED_KEY          = 'contrast-red';
constant CONTRAST_GREEN_KEY        = 'contrast-green';
constant CONTRAST_BLUE_KEY         = 'contrast-blue';
constant LENS_MODE_KEY             = 'lens-mode';
constant CLAMP_MODE_KEY            = 'scroll-at-edges';
constant MOUSE_TRACKING_KEY        = 'mouse-tracking';
constant FOCUS_TRACKING_KEY        = 'focus-tracking';
constant CARET_TRACKING_KEY        = 'caret-tracking';
constant SHOW_CROSS_HAIRS_KEY      = 'show-cross-hairs';
constant CROSS_HAIRS_THICKNESS_KEY = 'cross-hairs-thickness';
constant CROSS_HAIRS_COLOR_KEY     = 'cross-hairs-color';
constant CROSS_HAIRS_OPACITY_KEY   = 'cross-hairs-opacity';
constant CROSS_HAIRS_LENGTH_KEY    = 'cross-hairs-length';
constant CROSS_HAIRS_CLIP_KEY      = 'cross-hairs-clip';
constant MOUSE_WATCH_INTERVAL      = 1000 / 60;

class Gnome::Shell::UI::Magnifier::MouseSpriteContent
  does Mutter::Clutter;:Roles::Content
{
  has $!texture;

  method texture is rw {
    Proxy.new:
      FETCH => $     { $!texture           }
      STORE => $, \v { self.set_texture(v) }
  }

  method get-preferred-size is vfunc {
    return [False, 0, 0] unless $!texture;

    [ True, |$!texture.size ]
  }

  method paint-content ($actor, $node, $paintContext) is vfunc {
    return unless $!texture;

    my $color = Mutter::Clutter::Color.get-static(CLUTTER_COLOR_WHITE);

    my ($minF, $magF) = $actor.get-content-scaling-filters;

    my $tn = Mutter::Clutter::Paint::Node::Texture.new(
      $!texture,
      $color,
      $minF,
      $magF
    );
    $node.add-child($tn);
    $tn.add-rectangle($a.content-box);
  }

  method set_texture (CoglTexture() $t) {
    return if $!texture.is($t);

    my $ot = $!texture;
    $!texture = $t;
    self.invalidate;

    self.invalidate-size if [||](
      $ot.not,
      $t.not,
      $ot.size !~~ $tg.size
    );
  }
}

constant MSC = Gnome::Shell::UI::Magnifier::MouseSpriteContent;

class Gnome::Shell::UI::Magnifier
  is Gnome::Shell::Misc::Signals::EventEmitter
{
  has $.cursorTracker = Mutter::Meta::CursorTracker.get-for-display(
    Global.display
  );

  has $.zoomRegions = [];
  has $.cursorRoot  = Mutter::Clutter::Actor.new;
  has $.mouseSprite = Mutter::Clutter::Actor.new(
    request-mode => CLUTTER_REQUEST_CONTENT_SIZE
  );

  has $.mousePos;

  submethod TWEAK {
    self.cursorRoot.add-child( $.mouseSprite.content = MSC.new );
    $!mousePos = Global.get-pointer;
    self.zoomRegions.push: ( my $aRegion = ZR.new(self, self.cursorRoot) );
    self.settingsInit($aRegion);
    $aRegion.scroll-contents-to( |$.mousePos );

    my $s = self;
    Gnome::Shell::St::Settings.get.notify('magnifier-active').tap: SUB {
      $s.setActive( St::Settings.get.magnifier-active );
    }

    self.setActive( St::Settings.get.magnifier-active );
  }

  method showSystemCursor {
    my $s = Mutter::Clutter::Backend.get-default.get-default-seat;
    $s.uninhibit-unfocus if $s.is-unfocus-inhibited;

    if $.cursorVisibilityChangedId {
      $.cursorVisibilityChangedId.untap( :clear );
      $.cursorTracker.set-pointer-visible(True);
    }
  }

  method hideSystemCursor {
    my $s = Mutter::Clutter::Backend.get-default.get-default-seat;
    $s.inhibit-unfocus unless $s.is-unfocus-inhibited;

    unless $.cursorVisibilityChangedId {
      $.cursorTracker.set-pointer-visible(False);

      $!cursorVisibilityChangedId = $.cursorTracker.visibility-changed.tap:
        SUB {
          $!cursorTracker.set-pointer-visible(False)
            if $!cursorTracker.get-pointer-visible;
        };
    }
  }

  method setActive ($a) {
    my $isActive = $.isActive;

    .setActive($a) for $.zoomRegions[];

    return if $isActive == $a;

    if $a {
      my $s = self;
      $s.updateMouseSprite;
      $s.cursorTracker.connectObject(
        cursor-changed => SUB {
          $s.updateMouseSprite();
        }
      }
      Meta::Utils.disable-unredirect-for-display(Global.display);
      $.startTrackingMouse;
    } else {
      $.cursorTracker.disconnectObject(self);
      $.mouseSprite.content.texture = Nil;
      Meta::Utils::enable-unredirect-for-display(Global.display);
      $.stopTrackingMouse;
    }

    $.crossHairs.setEnabled($a) if $.crossHairs;
    $.showSystemCursor unless $a;

    $.emit('active-changed');
  }

  method isActive {
    +$.zoomRegions.elems ?? $.zoomRegions.head.isActive !! False;
  }

  method startTrackingMouse {
    return if $.pointerWatch;
    $!pointerWatch =
      PointerWatcher.getPointerWatcher.addWatch(MOUSE_WATCH_INTERVAL);
    $.scrollToMousePos;
  }

  method stopTrackingMouse {
    $!pointerWatch.remove if $pointerWatch;
    $!pointeWatch = Nil;
  }

  method isTrackingMouse {
    return $.mouseTrackingId.so;
  }

  multi method scrollToMousePos {
    samewith(Global.get-pointer);
  }
  multi method scrollToMousePos( $position ) {
    $!mousePos = $position;

    $zoomRegions.map( *.scrollToMousePos ).any
      ?? $.hideSystemCursor
      !! $.showSystemCursor;
  }

  method createZoomRegion ($xmf, $ymf, $roi, $viewport) {
    my $r = Gnome::Shell::UI::Magnifier::ZoomRegion.new(self, $!cursorRoot);
    $r.setViewPort($viewPort);
    ( my $fixedROI = $roi.clone )<width height)> =
      ($viewPort.width, $viewPort.height) »/« ($xf, $ymf);
    $r.sertROI($fixedROI);
    $r.addCrosshairs($.crossHairs);
    $r;
  }

  method addZoomRegion ($r) {
    return unless $r;
    $.zoomRegions.push: $r;
    $.startTrackingMouse unless $.isTrackingMouse
  }

  method clearAllZoomRegion {
    .setActive(False) for $.zoomRegions[];
    $.zoomRegions = [];
    $.stopTrackingMouse;
    $.showSystemCursor;
  }

  method addCrosshairs {
    $!crossHairs = Gnome::Shell::UI::Magnifier::Crosshairs.new(
      thickness => $.settings.get-int(CROSS_HAIRS_THICKNESS_KEY),
      color     => $.settings.get-string(CROSS_HAIRS_COLOR_KEY),
      opacity   => $.settings.get-double(CROSS_HAIRS_OPACITY_KEY),
      length    => $.settings.get-int(CROSS_HAIRS_LENGTH_KEY),
      clip      => $.settings.get-boolean(CROSS_HAIRS_CLIP_KEY)
    );

    .addCrosshairs($!crossHairs) for $.zoomRegions[];
  }

  method setCrosshairsVisible ($v) {
    if $v {
      $.addCrosshairs unless $!crossHairs;
      $.crossHairs.show;
    } else {
      $.crossHairs.hide;
    }
  }

  multi method setCrosshairsColor (Str $c) {
    samewith( Mutter::Clutter::Color.from-string($c) );
  }
  multi method setCrosshairsColor (MutterClutterColor $c) {
    return unless $.crosshairs;
    $.crossHairs.setColor($c);
  }
  multi method setCrosshairsColor ($_) {
    when Mutter::Clutter::Color      { samewith( .MutterClutterColor ) }
    when .^can('MutterClutterColor') { samewith( .MutterClutterColor ) }
    when .^can('Str')                { samewith( .Str )                }

    default {
      X::Gnome::Shell::InvalidObject.new($_).throw;
    }
  }

  method getCrosshairsColor {
    $!crossHairs ?? $.crossHairs.getColor.Str !! '#000000';
  }

  method setCrosshairsThickness ($t) {
    $!crossHairs?.setThickness($t);
  }

  method getCrosshairsThickness {
    $!crossHairs?.getThickness // 0;
  }

  method setCrosshairsOpacity ($o) {
    $!crossHairs?.setOpacity($o * 255);
  }

  method getCrosshairsOpacity {
    $!crossHairs?.getOpacity;
  }

  method setCrosshairsLength ($l) {
    $!crossHairs?.setLength(
      $l /
      Gnome::Shell::St::ThemeContext.get-for-stage(Global.stage).scale-factor
    );
  }

  method getCrosshairsLength {
    $!crossHairs?.getLength;
  }

  method setCrosshairsClip ($c) {
    return unless $!crossHairs;
    $!crossHairs.setClip( $c ?? CROSSHAIRS_CLIP_SIZE !! [0, 0] );
  }

  method getCrosshairsClip {
    return False unless $!crossHairs;
    $!crossHairs.getClip.all > 0
  }

  method updateMouseSprite {
    $.updateSpriteTexture;
    $!mouseSprite.set-position( |$!cursorTracker.get-hot );
  }

  method updateSpriteTexture {
    if $!cursorTracker.get-sprite -> $s {
      $!mouseSprite.content.texture = $s;
      $!mouseSprite.show;
    } else {
      $!mouseSprite.hide;
    }
  }

  method settingsInit ($r) {
    $!settings = GIO::Settings.new(MAGNIFIER_SCHEMA);

    my $s = self;
    $.settings.changed(SCREEN_POSITION_KEY).tap:
      SUB { $s.updateScreenPosition };
    $.settings.changed(MAG_FACTOR_KEY).tap:
      SUB { $s.updateMagFactor };
    $.settings.changed(LENS_MODE_KEY).tap:
      SUB { $s.updateLensMode };
    $.settings.changed(CLAMP_MODE_KEY).tap:
      SUB { $s.updateClampMode };
    $.settings.changed(MOUSE_TRACKING_KEY).tap:
      SUB { $s.updateMouseTrackingMode };
    $.settings.changed(FOCUS_TRACKING_KEY).tap:
      SUB { $s.updateFocusTrackingMode };
    $.settings.changed(CARET_TRACKING_KEY).tap:
      SUB { $s.updateCaretTrackingMode };
    $.settings.changed(INVERT_LIGHTNESS_KEY).tap:
      SUB { $s.updateInvertLightness }
    $.settings.changed(COLOR_SATURATION_KEY).tap:
      SUB { $s.updateColorSaturation }
    $.settings.changed(BRIGHT_RED_KEY).tap:
      SUB { $s.updateBrightness }
    $.settings.changed(BRIGHT_GREEN_KEY).tap:
      SUB { $s.updateBrightness }
    $.settings.changed(BRIGHT_BLUE_KEY).tap:
      SUB { $s.updateBrightness }
    $.settings.changed(CONTRAST_RED_KEY).tap:
      SUB { $s.updateContrast }
    $.settings.changed(CONTRAST_GREEN_KEY).tap:
      SUB { $s.updateContrast }
    $.settings.changed(CONTRAST_BLUE_KEY).tap:
      SUB { $s.updateContrast }

    $.settings.changed(SHOW_CROSS_HAIRS_KEY).tap: SUB {
      $s.setCrosshairsVisible(
        $s.settings.get_boolean(SHOW_CROSS_HAIRS_KEY)
      );
    });

    $.settings.changed(CROSS_HAIRS_THICKNESS_KEY).tap: SUB {
      $s.setCrosshairsThickness(
        $s.settings.get_int(CROSS_HAIRS_THICKNESS_KEY)
      );
    });

    $.settings.changed(CROSS_HAIRS_COLOR_KEY).tap: SUB {
      $s.setCrosshairsColor(
        $s.settings.get_string(CROSS_HAIRS_COLOR_KEY)
      );
    });

    $.settings.changed(CROSS_HAIRS_OPACITY_KEY).tap: SUB {
      $s.setCrosshairsOpacity(
        $s.settings.get_double(CROSS_HAIRS_OPACITY_KEY)
      );
    });

    $.settings.changed(CROSS_HAIRS_LENGTH_KEY).tap: SUB {
      $s.setCrosshairsLength(
        $s.settings.get_int(CROSS_HAIRS_LENGTH_KEY)
      );
    });

    $.settings.changed(CROSS_HAIRS_CLIP_KEY).tap: SUB {
      $s.setCrosshairsClip(
        $s.settings.get_boolean(CROSS_HAIRS_CLIP_KEY)
      );
    });

    if $r {
      if $.settings.get_double(MAG_FACTOR_KEY).round(0.01) -> $s {
        $r.setMagFactor($s, $s)
      }

      if $.settings.get_enum(SCREEN_POSITION_KEY) -> $s {
        $r.setScreenPosition($s)
      }

      $r.setLensMode( $.settings.get_boolean(LENS_MODE_KEY) );
      $r.setClampScrollingAtEdges(
        $.settings.get_boolean(CLAMP_MODE_KEY)
      );

      if $.settings.get_enum(MOUSE_TRACKING_KEY) -> $s {
        $r.setMouseTrackingMode($s);
      }

      if $.settings.get_enum(FOCUS_TRACKING_KEY) -> $s {
        $r.setFocusTrackingMode($s);
      }

      if $.settings.get_enum(CARET_TRACKING_KEY) -> $s {
        $r.setCaretTrackingMode($s);
      }

      if $.settings.get_boolean(INVERT_LIGHTNESS_KEY) -> $s {
        $r.setInvertLightness($s);
      }

      if $.settings.get_double(COLOR_SATURATION_KEY) -> $s {
        $r.setColorSaturation($s);
      }

      my @b = (
        $.settings.get_double(BRIGHT_RED_KEY),
        $.settings.get_double(BRIGHT_GREEN_KEY),
        $.settings.get_double(BRIGHT_BLUE_KEY)
      );
      $r.setBrightness( |@b );

      @b = (
        $.settings.get_double(CONTRAST_RED_KEY),
        $.settings.get_double(CONTRAST_GREEN_KEY),
        $.settings.get_double(CONTRAST_BLUE_KEY)
      );
      $f.setContrast( |@b );
    }

    $.addCrosshairs();
    $.setCrosshairsVisible(
      $.settings.get_boolean(SHOW_CROSS_HAIRS_KEY)
    )
  }

  method updateScreenPosition {
    return unless +$!zoomRegions;

    given $.settings.get-enum(SCREEN_POSITION_KEY) {
      $!zoomRegions.head.setScreenPosition($_);
      $.updateLensMode
        unless $_ == G_DESKTOP_MAGNIFIER_SCREEN_POSITION_FULL_SCREEN;
    }
  }

  method updateMagFactor {
    return unless +$!zoomRegions;

    my $f = $.settings.get_double(MAG_FACTOR_KEY).round(0.01);
    $.zoomRegions.head.setMagFactor( |( $f xx 2 ) );
  }

  method updateLensMode() {
    return unless +$!zoomRegions;

    $.zoomRegions.head.setLensMode( $.settings.get_boolean(LENS_MODE_KEY) );
  }

  method updateClampMode() {
    return unless +$!zoomRegions;

    $.zoomRegions.head.setLensMode(
      $.settings.get_boolean(CLAMP_MODE_KEY)
    );
  }

  method updateMouseTrackingMode {
    return unless +$!zoomRegions;

    $.zoomRegions.head.setMouseTrackingMode(
      $.settings.get_enum(MOUSE_TRACKING_KEY)
    );
  }

  method updateFocusTrackingMode {
    return unless +$!zoomRegions;

    $.zoomRegions.head.setFocusTrackingMode(
      $.settings.get_enum(FOCUS_TRACKING_KEY)
    );
  }

  method updateCaretTrackingMode {
    return unless +$!zoomRegions;

    $.zoomRegions.head.setCaretTrackingMode(
      $.settings.get_enum(CARET_TRACKING_KEY)
    );
  }

  method updateInvertLightness {
    return unless +$!zoomRegions;

    $.zoomRegions.head.setInvertLightness(
      $.settings.get_boolean(INVERT_LIGHTNESS_KEY)
    );
  }

  method updateColorSaturation {
    return unless +$!zoomRegions;

    $.zoomRegions.head.setColorSaturation(
      $.settings.get_double(COLOR_SATURATION_KEY)
    );
  }

  method updateBrightness {
    return unless +$!zoomRegions;

    $.zoomRegions.head.setBrightness(
      $.settings.get_double(BRIGHT_RED_KEY),
      $.settings.get_double(BRIGHT_GREEN_KEY),
      $.settings.get_double(BRIGHT_BLUE_KEY)
    );
  }

  method updateContrast {
    return unless +$!zoomRegions;

    $.zoomRegions.head.setBrightness(
      $.settings.get_double(CONTRAST_RED_KEY),
      $.settings.get_double(CONTRAST_GREEN_KEY),
      $.settings.get_double(CONTRAST_BLUE_KEY)
    );
  }
}

constant NO_CHANGE_DEFAULT = %(
  r => NO_CHANGE,
  g => NO_CHANGE,
  b => NO_CHANGE
);

class Gnome::Shell::UI::Magnifier::ZoomRegion {
  has $.magnifier;
  has $.magView;
  has $.background;
  has $.uiGroupClone;
  has $.mouseSourceActor;
  has $.mouseActor;
  has $.crossHairs;
  has $.crossHairsActor;
  has $.xCenter;
  has $.yCenter;
  has @.signalConnections;

  has $.focusCaretTracker     = Gnome::Shell::UI::FocusCaretTracker.new;
  has $.mouseTrackingMode     = G_DESKTOP_MAGNIFIER_MOUSE_TRACKING_MODE_NONE;
  has $.focusTrackingMode     = G_DESKTOP_MAGNIFIER_FOCUS_TRACKING_MODE_NONE;
  has $.caretTrackingMode     = G_DESKTOP_MAGNIFIER_CARET_TRACKING_MODE_NONE;
  has $.clampScrollingAtEdges = False;
  has $.lensMode              = False;
  has $.screenPosition        = G_DESKTOP_MAGNIFIER_SCREEN_POSITION_FULL_SCREEN;
  has $.invertLightness       = False;
  has $.colorSaturation       = 1.0;
  has $.brightness            = NO_CHANGE_DEFAULT.clone;
  has $.contrast              = NO_CHANGE_DEFAULT.clone;
  has $.viewPort              = Mutter::Clutter::ActorBox.new(0, 0, Global.screen-size);
  has $.xMagFactor            = 1;
  has $.yMagFactor            = 1;
  has $.followingCursor       = False;
  has $.xFocus                = 0;
  has $.yFocus                = 0;
  has $.xCaret                = 0;
  has $.yCaret                = 0;
  has $.pointerIdleMonitor    = Global.backend.core-idle-monitor;
  has $.scrollContentsTimerId = 0;

  submethod BUILD ( :$!magnifier, :$!mouseSourceActor ) { }

  method new ($magnifier, $mouseSourceActor) {
    self.bless( :$!magnifier, :$!mouseSourceActor )
  };

  submethod TWEAK {
    $.xCenter = self.viewPortWidth  / 2;
    $.yCenter = self.viewPortHeight / 2;
  }

  method centerPos is rw {
    ($!xCenter, $!yCenter);
  }

  method focusPos is rw {
    ($!xFocus, $!yFocus);
  }

  method caretPos is rw {
    ($!xCaret, $!yCaret);
  }

  method magFactor is rw {
    ($!xMagFactor, $!yMagFactor);
  }

  method viewPos is rw {
    ($!viewPort.x, $!viewPort.y);
  }

  method viewSize {
    ($.viewPort.w, $.viewPort.h);
  }

  method connectSignals() {
    return if +@.signalConnections;

    my $s = self;
    @.signalConnections.push: [
      Main.layoutManager,
      'monitors-changed',
      Main.layoutManager.monitors-changed.tap: SUB { $s.monitorsChanged }
    ];
    @.signalConnections.push: [
      $.focusCaretTracker,
      'caret-moved',
      $.focusCaretTracker.caret-moved.tap:     SUB { $s.updateCaret }
    ];
    @.signalConnections.push: [
      $.focusCaretTracker,
      'focus-changed',
      $.focusCaretTracker.focus-changed.tap:   SUB { $s.updateFocus }
    ]
  }

  method disconnectSignals {
    .head."{ .[1] }"().untap( .tail ) for @.signalConnections;
    @.signalConnections = ();
  }

  method updateScreenPosition {
    $.screenPosition == G_DESKTOP_MAGNIFIER_SCREEN_POSITION_NONE
      ?? $.setViewPort( |$.viewPos, |$.viewSize )
      !! $..setScreenPosition( $.screenPosition );
  }

  method convertExtentsToScreenSpace ($a, $e) {
    my \topLevelWindowTypes =
      (ATSPI_ROLE_FRAME, ATSPI_ROLE_DIALOG, ATSPI_ROLE_WINDOW).Set;

    try {
      CATCH {
        default {
          X::Gnome::Shell::Error.new(
            message => "Failed to validate parent{
                        $message ?? ": { $message }" !! '' }"
          ).throw;
        }
      }

      my ($app, $parentWindow);
      my  $iter = $a;
      while $iter {
        if $iter.role == ATSPI_ROLE_APPLICATION {
          $app = $iter;
          last;
        } elsif $iter.role ∈ topLevelWindowTypres {
          $parentWindow = $iter;
        }
        $iter .= $parent;
      }

      return $e if $app && $app.name eq 'gnome-shell';

      my $windowActive      = $parentWindow &&
                              ATSPI_STATE_ACTIVE ∈ $parentWindow.state-set;
      my $accessibleFocused = ATSPI_STATE_FOCUST ∈ $a.state-set;

      return unless $windowActive && $accessibleFocused;
    }

    my $focusWindow = Global.display.focusWindow;
    return unless $focusWindow;

    my $windowRect = $focusWindow.frame-rect;
    $windowRect = $focusWindow.frame-rect-to-client-rect($windowRect)
      unless $focusWindow.is-client-decorated;

    my $scaleFactor = Gnome::Shell::St::ThemeContext.get-for-stage(
      Global.stage
    ).scale-factor;

    AtspiRect.new(
      |( $windowRect.pos »+« $e.pos »*» $scaleFactor )
      |( $e.size »*» $scaleFactor )
    );
  }

  method updateFocus ($caller, $event) {
    my $component = $event.source.get-component-iface;
    return unless  $component && $event.detail1 == 1;

    my $extents;
    try {
      CATCH {
        default {
          $*ERR.say: "Failed to read extents of focused component: {
                      .message }";
          return'
        }
      }

      my $extents = $component.get_extents(ATSPI_COORD_TYPE_WINDOW);
      $extents = $.convertExtentsToScreenSpace($event.source, $extents);
      return unless $extents;
    }

    my $focus = $extents.pos »+« $extents.size »/» 2;

    unless $.focusPos ~~ $focus {
      $.focusPos = $focus;
      $.centerFromFocusPosition;
    }
  }

  method updateCaret ($caller, $event) {
    my $text = $event.source.get-text-iface;
    return unless $text;

    my $extents;
    try {
      CATCH {
        default {
          $*ERR.say: "Failed to read extents of text caret: {
                      .message }";
          return'
        }
      }

      my $extents = $text.get-character-extents($text.caret-offset);
      $extents = $.convertExtentsToScreenSpace($text, $extents);
      return unless $extents;
    }

    my $caret = $extents.pos;
    return if $extents.size».so.none;

    unless $.caretPos ~~ $caret {
      $.caretPos = $caret;
      $.centerFromCaretPosition;
    }
  }

  method setActive ($activate) {
    return if $activate == $.isActive;

    if $activate {
        $.createActors();
        $.magnifier.hideSystemCursor if $.isMouseOverRegion;
        $.updateScreenPosition;
        $.updateMagViewGeometry;
        $.updateCloneGeometry;
        $.updateMousePosition;
        $.connectSignals;
    } else {
      Main.uiGroup.opacity = 255;
      $.disconnectSignals();
      $.destroyActors();
    }

    $.syncCaretTracking;
    $.syncFocusTracking;
  }

  method isActive { $.magView.defined }

  multi method setMagFactor ($xMagXY) {
    samewith( |$xMagXY );
  }
  multi method setMagFactor ($xMagFactor, $yMagFactor) {
    $.changeROI(
      $xMagFactor,
      $yMagFactor,
      redoCursorTracking => $.followingCursor,
      animate            => True
    );
  }

  method getMagFactor { $.magFactor }

  method setMouseTrackingMode ($m) {
    $!mouseTrackingMode = $m
      if $m == GDesktopMagnifierFocusTrackingModeEnum.enums.values.any
  }

  method setFocusTrackingMode ($m) {
    $!focusTrackingMode = $m;
    $.syncFocusTracking;
  }

  method setCaretTracckingMode ($m) {
    $!caretTrackingMode = $m;
    $.syncCaretTracking;
  }

  method syncFocusTracking {
    $!focusTrackingMode != G_DESKTOP_MAGNIFIER_FOCUS_TRACKING_MODE_NONE &&
    $.isActive
      ?? $.focusCaretTracker.registerFocusListener
      !! $.focusCaretTracker.deregisterFocusListener;
  }

  method syncCaretTracking {
    $!focusTrackingMode != G_DESKTOP_MAGNIFIER_CARET_TRACKING_MODE_NONE &&
    $.isActive
      ?? $.focusCaretTracker.registerCaretListener
      !! $.focusCaretTracker.deregisterCaretListener;
  }

  method setViewPort ($v) {
    $.setViewPortReal($v);
    $.screenPosition = G_DESKTOP_MAGNIFIER_SCREEN_POSITION_NONE;
  }

  multi method setROI ($x, $y, $width, $height) {
    samewith( :$x, :$y, :$width, :$height );
  }
  multi method setROI (%roi) {
    samewith( |%roi );
  }
  multi method setROI ( :$x, :$y, :$width, :$height) {
    return unless ($width, $height)».so.all;

    $!followingCursor = False;
    $!centerPos = ($x, $y)   »+« ($width, $height) »/» 2
    $!magFactor = $!viewPort.size »/« ($width, $height);
    $.changeROI( |$.magFactor, |$.centerPos );
  }

  method getROI {
    my $roi = $!viewPort.size »/« $!magFactor;
    (
      |$!centerPos »-« $roi »/» 2,
      |$roi
    );
  }

  method setLensMode ($m) {
    $!lenseMode = $m;
    $.setScreenPosition($!screenPosition) unless $!lenseMode;
  }

  method isLensMode { $!lensMode }

  method setClamScrollingAtEdges ($c) {
    $!clampScrollingAtEdges = $c;
    $.changeROI if $c;
  }

  method getScreenDimensions ($window) {
    do given $window {
      when G_DESKTOP_MAGNIFIER_SCREEN_POSITION_TOP_HALF {
        0, 0 Global.screen.width, Global.screen.height / 2;
      }
      when G_DESKTOP_MAGNIFIER_SCREEN_POSITION_BOTTOM_HALF {
        my $yh = Global.screen.height / 2;
        0, $yh, Global.screen.width, $yh
      }
      when G_DESKTOP_MAGNIFIER_SCREEN_LEFT_HALF {
        0, 0 Global.screen.width / 2, Global.screen.height;
      }
      when G_DESKTOP_MAGNIFIER_SCREEN_POSITION_RIGHT_HALF {
        my $xw = Global.screen.$xw;
        $xw, 0, Global.screen.width / 2, $xw;
      }
      when G_DESKTOP_MAGNIFIER_SCREEN_POSITION_FULL_SCREEN {
        0, 0, |Global.screen.size;
      }
    }
  }

  method setScreenWindow ($p) {
    my $w = $.getScreenDimensions($p);
    X::Gnome::Shell::InvalidValue.new.throw unless $p;
    $.setViewPort( Mutter::Clutter::ActorBox.new( |$p );
    $!screenPosition = $p;
  }
  method setTopHalf {
    $.setScreenWindow(G_DESKTOP_MAGNIFIER_SCREEN_POSITION_TOP_HALF);
  }
  method setRightHalf {
    $.setScreenWindow(G_DESKTOP_MAGNIFIER_SCREEN_POSITION_RIGHT_HALF);
  }
  method setLeftHalf {
    $.setScreenWindow(G_DESKTOP_MAGNIFIER_SCREEN_POSITION_LEFT_HALF)
  }
  method setRightHalf {
    $.setScreenWindow(G_DESKTOP_MAGNIFIER_SCREEN_POSITION_RIGHT_HALF);
  }
  method setFullScreen {
    $.setScreenWindow(G_DESKTOP_MAGNIFIER_SCREEN_POSITION_FULL_SCREEN);
  }

  method setScreenPosition ($inPosition) {
    $.setViewPort(
      Mutter::Clutter::ActorBox.new( |$.getScreenDimensions($inPosition) )
    )
  }

  method clearScrollContentsTimer { $.scrollContentsTimerId.?clear }

  method scrollToMousePos {
    $!followingCursor = True;

    $!mouseTrackingMode = G_DESKTOP_MAGNIFIER_MOUSE_TRACKING_MODE_NONE
      ?? $.changeROI( :redo ) !! $.updateMousePosition;

    $.clearScrollContentsTimer;

    my $s = self;
    $.scrollContentsTimerId = GLib::Timeout.add(
      POINTER_REST_TIME,
      SUB {
        $!followingCursor = False;
        if ($!xDelayed, $!yDelayed).none {
          $s.scrollContentsToDelayed($!xDelayed, $!yDelayed);
          ($!xDelayed, $!yDelayed) = Nil xx 2;
        }
        $!scrollContentsTimerId.?clear;
        G_SOURCE_REMOVE.Int;
      }
    );
    $.isMouseOverRegion;
  }

  method scrollContentsTo ($x, $y) {
    return unless $x ~~ 0..Global.screen.width &&
                  $y ~~ 0..Global.screen.height;

    $.clearScrollContentsTimer;
    $!followingCursor = False;
    $.changeROI( :$x, :$y, :animate );
  }

  method addCrossHairs ($crossHairs) {
    $!crossHairs = $crossHairs;

    $!crossHairsActor = $crossHairs.addToZoomRegion(self, $!mouseActor)
      if $crossHairs && $!active;
  }

  method setInvertLightness ($flags) {
    $!invertLightness = $flag;
    $!magShaderEffects.setInvertLightness($!invertLightnes)
      if $!magShaderEffects;
  }

  method setColorSaturation ($saturation) {
    $!colorSaturation = $saturation;
    $!magShaderEffects.setColorSaturation($!colorSaturation)
      if $!magShaderEffects;
  }

  method setBrightness ($b) {
    $!brightness = $b;
    $!magShaderEffects.setBrightness($!brightness) if $!magShaderEffects;
  }

  method setContrast ($c) {
    $!contrast = $c;
    $!magShaderEffects.setContrast($!contrast) if $!magShaderEffects;
  }

  method createActors {
    my $mg = Mutter::Clutter::Actor.new( :clip-to-allocation );

    $!magView = Gnome::Shell::St::Bin.new(
      style-class => 'magnifier-zoom-region',
      child       => $mag
    );

    Global.stage.add-child($!magView);

    Gnome::Shell::Utils.set-hidden-from-pick($!magView, True);

    $!background = Gnome::Shell::UI::Background::System.new;
    mg.add-child($!background);

    $!uiGroupClone = Mutter::Clutter::CLone.new(
      source             => Main.uiGroup,
      clip-to-allocation => True
    );

    $!mouseActor ?? $!mouseSourceActor.parent.defined
      ?? Mutter::Clutter::Clone.new( source => $!mouseSourceActor )
      !! $!mouseSourceActor;
    mg.add-child($!mouseActor);

    $!crossHairsActor = $!crossHairs
      ?? $!crossHairs.addToZoomRegion(self, self.mouseActor)
      !! Nil;

    $!magShaderEffects = Gnome::Shell::UI::Magnifier::ShaderEffects.new(
      colorSaturation => $!colorSaturation,
      invertLightness => $!invertLightness,
      brigntness      => $!brightness,
      contrast        => $!contrast
    );
  }

  method destroyActors {
    $!mouseActor.parent.remove-child($!mouseActor)
      if $!mouseActor.is($!mouseSourceActor);

    $!crossHairs?.removeFromPairent($!crossHairsActor);

    $!magShaderEffects.destroyEffects;
    $!magView.destroy;

    $!magShaderEffects = $!magView         = $!background = $!uiGroupClone =
    $!mouseActor       = $!crossHairsActor = Nil;
  }

  method setViewPort($v, $f) {
    sub size-min ($a, $b) { my @a = ($a, $b); [ @a».head».min, @a».tail».min ] }
    sub size-max ($a, $b) { my @a = ($a, $b); [ @a».head».max, @a».tail».max ] }

    my ($w, $h) = ($viewPort, Global.Screen)».&size-min».Int;
    my ($x, $y) = ( $viewPort.pos-xy [Z] (0, 0) )».max».Int;

    ($x, $y) = ( [$x, $y], Global.screen »-« ($w, $h) ).&size-min».Int;

    $!viewPort = Mutter::Clutter::ActorBox.new( :$x, :$y, :$w, :$h );
    $.updateMagViewGeometry;

    $.changeROI( 'redo' => $!followingCursor ) if $f;
    $.magnifier.hideSystemCursor if $.isActive && $.isMouseOverRegion;

    Main.uiGroup.opacity = $.isActive && $.isFullScreen ?? 0 !! 255;
  }

  method changeROI (
    :mag( :$magFactor )         is copy = $.magFactor,
    :xMag(:$xMagFactor)         is copy = $.magFactor.head,
    :yMag(:$yMagFactor)         is copy = $.magFactor.tail,
    :c(:$center)                is copy = $.centerPos,
    :x(:$xCenter)               is copy = $.centerPos.head,
    :y(:$yCenter)               is copy = $.centerPos.tail,
    :redo(:$redoCursorTracking) is copy = False,
    :anim(:$animate)            is copy = False
  ) {
    $xMagFactor = $magFactor.head unless $xMagFactor;
    $yMagFactor = $magFactor.head unless $yMagFactor;

    $.magFactor = ( $xMagFactor, $yMagFactor );

    ( $xCenter, $yCenter ) = $.centerFromMousePosition
      if $redoCursorTracking &&
         $.mouseTrackingMode != G_DESKTOP_MAGNIFIER_MOUSE_TRACKING_MODE_NONE;

    if $.clamScrollingAtEdges {
      my $roi = $.viewPort.pos »/« $.magFactor;

      $xCenter .= &clamp( Global.screen.head - $roi.w .. $roi.w / 2 );
      $yCenter .= &clamp( Global.screen.tail - $roi.h .. $roi.h / 2 );
    }

    $.centerPos = ($xCenter, $yCenter);

    if $.lensMode && $.isFullScreen {
      $.setViewPort(
        Mutter::Clutter::Actorbox.new(
          |($.centerPos »-« $.viewPort.size »/» 2),
          |$viewPort.size
        ),
        True
      )
    }

    $.updateCloneGeometry;
  }

  method isMouseOverRegion {
    sub isge ($l) { $l.head >= $l.tail };

    do if $.isActive {
      my $o = $.viewPort.xy »+« $.viewPort.size;

      $mousePos.head >= $viewPort.head && $mousePos.tail >= $viewPort.tail &&
      $mousePos.head < $o.head         && $mousePos.tail < $o.tail;
    }
  }

  method isFullScreen {
    return False unless $viewPort.pos.all;
    return False unless $viewPort.size ~~ Global.screen.size;
    True;
  }

  method centerFromMousePosition {
    do given $!mouseTrackingMode.Int {
      when    0  { $.centerFromPointProportional( |$.magnifier.mousePos ) }
      when    1  { $.centerFromPointPush(         |$.magnifier.mousePos ) }
      when    2  { $.centerFromPointCentered(     |$.magnifier.mousePos ) }
      default    { Nil                                                    }
    }
  }

  method centerFromCaretPosition {
    do given $!caretTrackingMode.Int {
      when    0  { $.centerFromPointProportional( |$.caretPos ) }
      when    1  { $.centerFromPointPush(         |$.caretPos ) }
      when    2  { $.centerFromPointCentered(     |$.caretPos ) }
      default    { Nil                                          }
    }
  }

  method centerFromFocusPosition {
    do given $!focusTrackingMode.Int {
      when    0  { $.centerFromPointProportional( |$.focusPos ) }
      when    1  { $.centerFromPointPush(         |$.focusPos ) }
      when    2  { $.centerFromPointCentered(     |$.focusPos ) }
      default    { Nil                                          }
    }
  }

  method centerFromPointPush ($x, $y) {
    my @point      = ($x, $y);
    my @roi        = $.getROI;
    my $cursorSize = $.mouseSourceActor.size;
    my @pos        = @roi.head(2) »+« @roi.skip(2) »/« 2;
    my @roi-rb     = @roi »-« $cursorSize »+« @roi.skip(2);

    if    @point.head < @roi.head    { @pos.head -= @roi.head - @point.head  }
    elsif @point.head > @roi-rb.head { @pos.head += @pos.head - @roi-rb.head }

    if    @point.tail < @roi.tail    { @pos.tail -= @roi.tail - @point.tail  }
    elsif @point.tail > @roi-rb.tail { @pos.tail += @pos.tail - @roi-rb.tail }

    @pos;
  }

  method centerFromPointProportional ($x, $y) {
    my @point = ($x, $y);
    my @roi   = $.getROI;
    my @hs    = Global.screen.size »/« 2;
    my @up    = $viewPort.size.min / 5;
    my @pad   = ($up xx 2) »/« $.magFactor;
    my @pro   = (@point »-« @hs) »/« @hs;

    @point »-« @pro »*« ( @roi.skip(2) »/» 2 »-« @pad );
  }

  method centerFromPointCentered ($x, $y) {
    ($x, $y);
  }

  method updateMagViewGeometry {
    return unless $.isActive;

    $.isFullScreen ?? $.magView.add-style-class-name('full-screen')
                   !! $.magView.remove-style-class-name('full-screen');

    $.magView.set-size( |$.viewPort.size );
    $.magView.setPosition( |$.viewPort.pos );
  }

  method updateCloneGeometry ( :anim(:$animate) = False ) {
    return unless $.isActive;

    $.uiGroupClone.ease(
      |( <x y> Z $.screenToViewPort(0, 0).map( *.Int ) ).flat.Hash,

      scale    => $.magFactor,
      mode     => CLUTTER_EASE_IN_OUT_QUAD,
      duration => $animate ?? 100 !! 0
    );

    $.mouseActor.ease(
      |( <x y> Z $.getMousePosition ).flat.Hash,

      scale    => $.magFactor,
      mode     => CLUTTER_EASE_IN_OUT_QUAD,
      duration => $animate ?? 100 !! 0
    );

    $.crossHairsActor.ease(
      |( <x y> Z $.getCrossHairsPosition ).flat.Hash,

      mode     => CLUTTER_EASE_IN_OUT_QUAD,
      duration => $animate ?? 100 !! 0
    ) if $.crossHairsActor;
  }

  method updateMousePosition {
    $!mouseActor.set-position( |$.getMousePosition );
    $!crossHairsActor.set-position( |$.getCrossHairsPosition )
      if $!crossHairsActor;
  }

  method getMousePosition {
    $.screenToViewPort( |$.magnifier.mousePos )».Int;
  }

  method getCrossHairsPosition {
    $.getMousePosition »-« $.crossHairsActor.size »/» 2;
  }

  method monitorsChanged {
    $.background-size( |Global.screen.size );
    $.updateScreenPosition;
  }

}

class Gnome::Shell::UI::Magnidier::Crosshairs is Mutter::Clutter::Actor {
  my $groupSize = Global.screen.size »*» 3;

  has $.horizLeftHair     = Mutter::Clutter::Actor.new;
  has $.horizRightHair    = Mutter::Clutter::Actor.new;
  has $.vertTopHair       = Mutter::Clutter::Actor.new;
  has $.vertBottomHair    = Mutter::Clutter::Actor.new;
  has @.clipSize          = [0, 0];
  has @.clones            = [];
  has $.monitorsChangedId = 0;


  submethod TWEAK {
    ( .clip-to-allocation, .size-wh) = (False, $groupSize) given self;

    self.add-child($_) for self.horizLeftHair,
                           self.horizRightHair,
                           self.vertTopHair,
                           self.vertBottomHair;

    self.reCenter;
  }

  method monitorsChanged {
    $.size-wh = $groupSize;
    $.reCenter;
  }

  method setEnabled ($e) {
    if $e && $.monitorsChangedId.not {
      my $s = self;
      $.monitorsChangedId = Main.layout-manager.monitors-changed.tap: SUB {
        $s.monitorsChanged();
      }
    } elsif $e.not && $.monitorsChanged {
      $.monitorsChangedId.untap( :clear );
    }
  }

  method addToZoomRegion ($zoomRegion, $magnifiedMouse) {
    my $crosshairsActor;
    if $zoomRegion && $magnifiedMouse {
      if $magnifiedMouse.parent -> $c {
        $croshairsActor = self;
        if $.parent {
          $crosshairsActor = Mutter::Clutter::Clone.new( source => self );
          @!clonse.push($crossHairsActor);
          $.bind-property('visible', $crosshairsActor);
        }

        $c.add-child($crosshairsActor);
        $c.set-child-above-sibling($magnifiedMouse, $crosshairsActor);
        $crosshairsActor.set-position(
          $magnifiedMouse.position »-« $crossHairsActor.size-wh »/» 2
        );
      }
    }

    $crosshairsActor;
  }

  method removeFromParent ($childActor) {
    $childActor.is(self) ?? $childActor.parent.remove-child($childActor)
                         !! $childActor.destroy;
  }

  method setColor ($cc) {
    .background-color = $cc for self.horizLeftHair,
                                self.horizRightHair,
                                self.vertTopHair,
                                self.vertBottomHair;
  }

  method getColor {
    $.horizLeftaHair.color
  }

  method setThickness ($t) {
    .height = $t for self.horizLeftHair,
                     self.horizRightHair;
    .width = $t  for self.vertTopHair,
                     self.vertBottomHair;
    $.reCenter;
  }

  method getThickness {
    self.horiszLeftHair.height;
  }

  method setOpacity ($o is copy) {
    $o .= clamp( 0 .. 255 );

    .opacity = $o for self.horizLeftHair,
                      self.horizRightHair,
                      self.vertTopHair,
                      self.vertBottomHair;
  }

  method getOpacity {
    self.horizLeftHair.opacity;
  }

  method setLength ($l) {
    .width = $l   for self.horizLeftHair,
                      self.horizRightHair;
    .height = $l  for self.vertTopHair,
                      self.vertBottomHair;
    $.reCenter;
  }

  method getLength {
    self.horizLeftHair.width;
  }

  method setClipSize ($s) {
    $.clipSize = $s ?? $s !! 0 xx 2;
    $.reCenter;
  }

  method reCenter ($clipSize?) {
    my $group = $.size;
    my @ltl   = ($.horizLeftHair.width, $.vertTopHair.height);
    my $t     = $.horizLdeftHair.height;

    $.clipSize = $clipSize if $clipSize;
    my $c = $.clipSize;

    my @lt = $group »/» 2 + $c »/» 2 »-« @ltl »-» ($t / 2);
    my @rb = $group »/»2  + $c »/» 2 »+» $t / 2;

    $.horizLeftHair.set-position( @lt.head, $group.tail - $t / 2);
    $.horizRightHair.set-position( @rb.head, $group.tail - $t / 2);
    $.vertTopHair.set-position( $group.head - $t / 2, @lt.tail );
    $.vertBottomHair.set-positoin( $group.head - $t / 2, @rb.tail );
  }

}

class Gnome::Shell::UI::Magnifier::ShaderEffects {
  has $.magView;

  has $.inverse            = Gnome::Shell::InvertLightnessEffect.new;
  has $.brightnessContrast = Mutter::Clutter::BrightnessContrastEffect.new;
  has $.colorDesaturation  = Mutter::Clutter::DesaturateEffect.new;

  submethod TWEAK (:$uiGroupClone) {
    $.magView = $uiGroupClone;
    for $.inverse, $.brightnessContrast, $.colorDesaturation {
      .enabled = False;
      $magView.add-effect($_);
    }
  }

  method destroyEffects {
    $.magView.clear-effects;
    $.inverse = $.brightnessContrast = $.colorDesaturation = $.magView = Nil;
  }

  method setInvertLightness ($l) {
    $.inverse.enabled = $l;
  }

  multi method setBrightness ($_) {
    when Hash {
      samewith( Mutter::Clutter::Color.new( |$_ )
    }

    when .^can('MutterClutterColor') {
      samewith( .MutterClutterColor )
    }

    when MutterClutterColor {
      samewith($_);
    }

    default {
      X::Gnome::Shell::InvalidType.new( object => $_ ).throw;
    }
  }
  multi method setBrightness (MutterClutterColor $c) {
    # cw: -XXX- This wants any contrast value that isn't NO_CHANGE
    $.brightnessContrast.enabled = $c.defined;

    $.brightnessContrast.set-brightness-full($c) if $c.defined
  }

  multi method setContrast ($_) {
    when Hash {
      samewith( Mutter::Clutter::Color.new( |$_ )
    }

    when .^can('MutterClutterColor') {
      samewith( .MutterClutterColor )
    }

    when MutterClutterColor {
      samewith($_);
    }

    default {
      X::Gnome::Shell::InvalidType.new( object => $_ ).throw;
    }
  }
  multi method setColntrast (MutterClutterColor $c) {
    # cw: -XXX- This wants any brightness value that isn't NO_CHANGE
    $.brightnessContrast.enabled = $c.defined;

    $.brightnessContrast.set-contrast-full($c) if $c.defined
  }

}
