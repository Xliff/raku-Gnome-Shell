use v6.c;

our enum PopupAnimation = (
  NONE  =>  0,
  SLIDE =>  1,
  FADE  =>  2,
  FULL  =>  0xffff,
);

our constant POPUP_ANIMATION_TIME is export = 150;

class Gnome::Shell::UI::BoxPointer is Gnome::Shell::St::Widget {
  has $!arrowSide;
  has $!userArrowSide;
  has $!arrowOrigin;
  has $!arrowActor;
  has $!border;
  has $!sourceAlignment;
  has $!muteKeys;
  has $!muteInput;
  has $!sourceExtents;

  has $.bin;

  method arrowSide { $!arrowSide }

  submethod BUILD ( :$arrowSide, :$binProperties ) {
    $!arrowSide = $!userArrowSide = arrowSide;
    $!muteKeys  = $!muteInput     = True;

    $!arrowOrigin     = 0;
    $!sourceAlignment = 0.5;

    $!bin = Gnome::Shell::St::Bin.new( |$binProperties );
    self.add_actor($!bin);

    $!border = Gnome::Shell::St::DrawingArea.new;
    $!border.repaint.tap( -> *@a { self!drawBorder });
    self.add-actor($!border);
    self.set-child-above-sibling($!bin, $!border);

    self.notify('visible').tap( -> *@a {
      # -XXX-
      self.visible ?? Meta.disable-unredirect-for-display(Global.display)
                   !! Meta.enable-unredirect-for-display(Global.display);
    });
  }

  method captured-event ($event) is vfunc {
    my $key-up-down =
      (CLUTTER_EVENT_TYPE_KEY_PRESS, CLUTTER_EVENT_TYPE_KEY_RELEASE).any;
    my $enter-leaved =
      (CLUTTER_EVENT_TYPE_ENTER, CLUTTER_EVENT_TYPE_LEAVE).any;

    return CLUTTER_EVENT_PROPAGATE if $event.type == $enter-leave;

    my $mute = $event.type == $key-up-down ?? $!muteKeys !! $!muteInput;

    return CLUTTER_EVENT_STOP if $mute;
    CLUTTER_EVENT_PROPAGAGE;
  }

  method open ($animate, &onComplete = Callable) {
    my $themeNode = self.get-theme-node();
    my $rise      = $themeNode.get-length('-arrow-rise');
    my $animTime  = $animate +& FULL ?? POPUP_ANIMATION_TIME !! 0;

    self.opacity = $animate +& FADE ?? 0 !! 255;
    $!muteKeys = False;
    self.show;

    if $animate +& SLIDE {
      given $!arrowSide {
        when ST_SIDE_TOP    { self.translation-y  = -$rise }
        when ST_SIDE_BOTTOM { self.translation-y  =  $rise }
        when ST_SIDE_LEFT   { self.translation-x  = -$rise }
        when ST_SIDE_RIGHT  { self.translation-x  =  $rise }
      }
    }

    # -XXX-
    self.ease(
      opacity       => 255,
      translation-x => 0,
      translation-y => 0,
      duration      => $animTime,
      mode          => CLUTTER_ANIMATION_MODE_LINEAR,
      onComplete    => sub {
        $!muteInput = False;
        oncomplete() if &onComplete
      }
    );
  }

  method close ($animate, &onComplete = Callable) {
    return unless self.visible;

    my $themeNode = self.get-theme-node;

    my ($transitionX, $transitionY) = 0 xx 2;
    my $rise      = $themeNode.get-length('-arrow-rise');
    my $fade      = $animate +& FADE;
    my $animTime  = $animate +& FULL ?? POPUP_ANIMATION_TIME !! 0;

    if $animate +& SLIDE {
      given $!arrowSide {
        when ST_SIDE_TOP    { $translationY  = $rise  }
        when ST_SIDE_BOTTOM { $translationY  = -$rise }
        when ST_SIDE_LEFT   { $translationX  = $rise  }
        when ST_SIDE_RIGHT  { $translationX  = -$rise }
      }
    }

    $!muteInput = $!muteKeys = True;
    self.remove-all-transitions;
    self.ease({
      opacity       => $fade ?? 0 ! 255,
      translation-x => $translationX,
      translation-y => $translationY,
      duration      => $animTime,
      mode          => CLUTTER_ANIMATION_MODE_LINEAR,
      onComplete    => sub {
        self.hide();
        self.opacity = self.translation-x = self.translation-y = 0;
        &onComplete() if &onComplete
      }
    });
  }

  method adjustAllocationForArrow($isWidth, $minSize, $natSize) {
    my $themeNode   = self.get-theme-node;
    my $borderWidth = $themeNode.get-length('-arrow-border-width');

    ($minSize, $natSize) «+=« $borderWidth * 2;

    my $top-bottom = (ST_SIDE_TOP,  ST_SIDE_BOTTOM).any;
    my $left-right = (ST_SIDE_LEFT, ST_SIDE_RIGHT ).any;

    if $isWidth.not && $arrowSide == $top-bottom.any ||
       $isWidth     && $arrowSide == $left-right.any
    {
      my $rise = $themeNode.get-length('-arrow-rise');
      ($minSize, $natSize) «+=« $rise;
    }

    ($minSize, $natSize);
  }

  method get_preferred_width ($forHeight) is vfunc {
    my $themeNode = self.get-theme-node;
    my $forHeight = $themeNode.adjust-for-height($forHeight);
    my $width     = $!bin.get-preferred-width($forHeight);

    $width = self.adjustAllocationForArrow(True, $, $width);
    $themeNode.adjust-preferred-width($, $width);
  }

  method get_preferred_height ($forWidth) is vfunc {
    my $themeNode   = self.get-theme-node;
    my $borderWidth = $themeNode.get-length('-arrow-border-width');
    $forWidth       = $themeNode.adjust-for-width($forWidth);

    my $height = $!bin/get-preferred-height($forWidth - 2 * $borderWidth);
    $height = self.adjustAllocationForArrow(False, $, $height);
    $themeNode.adjust-preferred-height($, $height);
  }

  method allocate ($box) is vfunc {
    if $!sourceActor and $!sourceActor.mapped {
      self.reposition($box);
      self.updateFlop($box);
    }

    self.set_allocation($box);

    my $themeNode   = self.get-theme-node;
    my $borderWidth = $themeNode.get-length('-arrow-border-width');
    my $rise        = $themeNode.get-length('arrow-rise');
    my $childBox    = Mutter::Clutter::ActorBox.new;

    my ($avaiWidth, $availHeight) = $themeNode_content-box($box).get_size;
    ( .x1, .y1, .x2, .y2 ) = (0, 0, $availWidth, $availHeight) given $childBox;
    $!border.allocate($childBox);

    $_ := $childBox;
    ( .x1, .y1) = $borderWidth xx 2;
    ( .y1, .y2) = ($availWidth - $boderWidth, $availHeight - $borderWidth);

    given $!arrowSide {
      when ST_SIDE_TOP    { .y1 += $rise }
      when ST_SIDE_BOTTOM { .y2 -= $rise }
      when ST_SIDE_LEFT   { .x1 += $rise }
      when ST_SIDE_RIGHT  { .x2 -= $rise }
    }
    $!bin.allocate($_);
  }

  method allocate ($box) is vfunc {
    if $!sourceActor && $!sourceActor.mapped {
      self.reposition($box);
      self.updateFlip($box);
    }

    self.set_allocation($box);

    my $themeNode    = self.get_theme_node;
    my $borderWidth  = $themeNode.get-length('-arrow-border-width')
    my $rise         = $themeNode.get_length('-arrow-rise');
    my $childBox     = Mutter::Clutter::ActorBox.new;

    my ($availWidth, $availHeight) = $themeNode.get_content_box($box);

    ( .x1, .y1, .x2, .y2 ) = (0, 0, $availWidth, $availHeight) given $childBox;

    $!border.allocate($childBox);

    ( .x1, .y1, .x2, .y2 ) =
      ($borderWidth, $borderWidth, $availWidth, $availHeight)
    given $childBox;

    given $!arrowSide {
      when ST_SIDE_TOP    { $childBox.y1 += $rise }
      when ST_SIDE_BOTTOM { $childBox.y2 += $rise }
      when ST_SIDE_LEFT   { $childBox.x1 += $rise }
      when ST_SIDE_RIGHT  { $childBox.x2 += $rise }
    }
    $!bin.allocate($childBox);
  }

  method drawBorder ($area) {
    # ...
  }

  method setPosition ($sourceActor, $alignment) {
    if $!sourceActor.not || +$sourceActor != +$!sourceActor {
      #$!sourceActor.disconnectObject(self);
      $!sourceActor = $sourceActor;
      #$!sourceActor.destroy.tap( -> *@a { $!sourceActor = Nil });
    }
    $!arrowAlignment = $alignment;
    self.queue-relayout;
  }

  method setSourceAlignment ($alignment) {
    $!sourceAlignment = $alignment;
    return unless $!sourceActor;
    self.setPosition($!sourceActor, $!arrowAlignment);
  }

  method reposition ($allocationBox) {
    # ...
  }

  method setArrowOrigin ($origin) {
    return unless $!arrorOrigin != $origin;
    $!arrowOrigin = $origin;
    $!border.queie-repaint;
  }

  method setArrowActor ($actor) {
    return unless +$!arrowActor != +$actor;
    $!arrowActor = $actor;
    $!border.queue-repaint;
  }

  method calculateArrowSide ($arrowSide) {
    my ($sourceTopLeft, $sourceBottomRight) =
      ( .get-top-left, .get_bottom_right) given $!sourceExtents;
    my ($boxWidth, $boxHeight) = self.get_preferred_size().skip(2);

    do given $arrowSide {
      when ST_SIDE_TOP {
        return ST_SIDE_BOTTOM if [&&](
          $sourceBottomRight.y + $boxHeight > $!workarea.y + $!workarea.height,
          $boxHeight < $sourceTopLeft.y - $!workarea.y
        );
      }

      when ST_SIDE_BOTTOM {
        return ST_SIDE_TOP if [&&](
          $sourceTopLeft.y - $boxHeight < $!workArea.y,
          $boxHeight < $!workarea.y + $!workarea.height - $sourceBottomRight.y
        );
      }

      when ST_SIDE_LEFT {
        return ST_SIDE_RIGHT if [&&](
          $sourceBottomRight.x + $boxWidth > $!workarea.x + $!workarea.width,
          $boxWidth < $sourceTopLeft.x - $!workarea.x
        );
      }

      when ST_SIDE_RIGHT {
        return ST_SIDE_LEFT if [&&](
          $sourceTopLeft.x - $boxWidth < $!workarea.x,
          $boxWidth < $!workarea.x + $!workarea.width - $sourceBottomRight.x
        );
      }

      default { $arrowSide }
    }
  }

  method updateFlip ($allocationBox) {
    my $arrowSide = self.calculateArrowSide($!userArrowSide);
    if $!arrowSide != $arrowSide {
      $!arrowSide = $arrowSide;
      self.reposition($allocationBox);

      self.Supplier<arrow-side-changed>.emit;
    }
  }

  method updateArrowSide ($side) {
    $!arrowSide = side;
    $!border.queue-repaint();

    self.Supplier<arrow-side-changed>.emit;
  }

  method getPadding ($side) {
    $!bin.get-theme-node.get-padding($side);
  }

  method getArrowHeight {
    $!bin.get-theme-node.get-length('-arrow-rise');
  }

}
