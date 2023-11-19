use v6.c;

use Method::Also;
use NativeCall;

use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::St::Theme::Node;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

our subset StThemeNodeAncestry is export of Mu
  where StThemeNode | GObject;

class Gnome::Shell::St::Theme::Node {
  also does GLib::Roles::Object;

  has StThemeNode $!sttn is implementor;

  submethod BUILD ( :$st-theme-node ) {
    self.setStThemeNode($st-theme-node) if $st-theme-node
  }

  method setStThemeNode (StThemeNodeAncestry $_) {
    my $to-parent;

    $!sttn = do {
      when StThemeNode {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StThemeNode, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::StThemeNode
    is also<StThemeNode>
  { $!sttn }

  multi method new (StThemeNodeAncestry $st-theme-node, :$ref = True) {
    return unless $st-theme-node;

    my $o = self.bless( :$st-theme-node );
    $o.ref if $ref;
    $o;
  }

  multi method new (
    StThemeContext()  $context,
    StTheme()         $theme,
    StThemeNode()    :$parent_node   = StThemeNode,
    Int()            :$element_type  = Str,
    Str()            :$element_id    = Str,
    Str()            :$element_class = Str,
    Str()            :$pseudo_class  = Str,
    Str()            :$inline_style  = Str
  ) {
    samewith(
      $context,
      $parent_node,
      $theme,
      $element_type,
      $element_id,
      $element_class,
      $pseudo_class,
      $inline_style
    );
  }
  multi method new (
    StThemeContext() $context,
    StThemeNode()    $parent_node,
    StTheme()        $theme,
    Int()            $element_type,
    Str()            $element_id,
    Str()            $element_class,
    Str()            $pseudo_class,
    Str()            $inline_style
  ) {
    my GType $e = $element_type;

    my $st-theme-node = st_theme_node_new(
      $context,
      $parent_node,
      $theme,
      $element_type,
      $element_id,
      $element_class,
      $pseudo_class,
      $inline_style
    );

    $st-theme-node ?? self.bless( :$st-theme-node ) !! Nil;
  }

  proto method adjust_for_height (|)
    is also<adjust-for-height>
  { * }

  multi method adjust_for_height {
    samewith($);
  }
  multi method adjust_for_height ($for_height is rw) {
    my gfloat $f = 0e0;

    st_theme_node_adjust_for_height($!sttn, $f);
    $for_height = $f;
  }

  proto method adjust_for_width (|)
    is also<adjust-for-width>
  { * }

  multi method adjust_for_width {
    samewith($);
  }
  multi method adjust_for_width ($for_width is rw) {
    my gfloat $f = 0e0;

    st_theme_node_adjust_for_width($!sttn, $f);
    $for_width = $f;
  }

  proto method adjust_preferred_height (|)
    is also<adjust-preferred-height>
  { * }

  multi method adjust_preferred_height {
    samewith($, $);
  }
  multi method adjust_preferred_height (
    $min_height_p     is rw,
    $natural_height_p is rw
  ) {
    my gfloat ($m, $n) = 0e0 xx 2;

    st_theme_node_adjust_preferred_height($!sttn, $m, $n);
    ($min_height_p, $natural_height_p) = ($m, $n);
  }

  proto method adjust_preferred_width (|)
    is also<adjust-preferred-width>
  { * }

  multi method adjust_preferred_width {
    samewith($, $);
  }
  multi method adjust_preferred_width (
    $min_width_p     is rw,
    $natural_width_p is rw
  ) {
    my gfloat ($m, $n) = 0e0 xx 2;

    st_theme_node_adjust_preferred_width($!sttn, $m, $n);
    ($min_width_p, $natural_width_p) = ($m, $n);
  }

  method equal (StThemeNode() $node_b) {
    so st_theme_node_equal($!sttn, $node_b);
  }

  method geometry_equal (StThemeNode() $other) is also<geometry-equal> {
    so st_theme_node_geometry_equal($!sttn, $other);
  }

  proto method get_background_color (|)
    is also<get-background-color>
  { * }

  multi method get_background_color {
    samewith(Mutter::Clutter::Color.alloc);
  }
  multi method get_background_color (
    MutterClutterColor()  $color,
                         :$raw    = False
  ) {
    st_theme_node_get_background_color($!sttn, $color);
    propReturnObject($color, $raw, |Mutter::Clutter::Color.getTypePair);
  }

  proto method get_background_gradient (|)
    is also<get-background-gradient>
  { * }

  multi method get_background_gradient {
    samewith($, Mutter::Clutter::Color.alloc, Mutter::Clutter::Color.alloc);
  }
  multi method get_background_gradient (
                          $type    is rw,
    MutterClutterColor()  $start,
    MutterClutterColor()  $end,
                         :$raw            = False
  ) {
    my StGradientType $t = 0;

    st_theme_node_get_background_gradient($!sttn, $type, $start, $end);
    $type = $t;

    for $start, $end -> $_ is raw {
      $_ = propReturnObject(
        $start,
        $raw,
        |Mutter::Clutter::Color.getTypePair
      )
    }

    ($type, $start, $end);
  }

  method get_background_image ( :$raw = False ) is also<get-background-image> {
    propReturnObject(
      st_theme_node_get_background_image($!sttn),
      $raw,
      |GIO::File.getTypePair
    );
  }

  method get_background_image_shadow ( :$raw = False )
    is also<get-background-image-shadow>
  {
    propReturnObject(
      st_theme_node_get_background_image_shadow($!sttn),
      $raw,
      |Gnome::Shell::Shadow.getTypePair
    );
  }

  proto method get_background_paint_box (|)
    is also<get-background-paint-box>

  { * }
  multi method get_background_paint_box (MutterClutterActorBox() $allocation) {
    samewith($allocation, Mutter::Clutter::ActorBox.alloc);
  }
  multi method get_background_paint_box (
    MutterClutterActorBox()  $allocation,
    MutterClutterActorBox()  $paint_box,
                            :$raw         = False
  ) {
    st_theme_node_get_background_paint_box($!sttn, $allocation, $paint_box);
    propReturnObject($paint_box, $raw, |Mutter::Clutter::ActorBox.getTypePair);
  }

  proto method get_border_color (|)
    is also<get-border-color>
  { * }

  multi method get_border_color (Int() $side) {
    samewith($side, Mutter::Clutter::Color.alloc);
  }
  multi method get_border_color (
    Int()                 $side,
    MutterClutterColor()  $color,
                         :$raw    = False
  ) {
    my StSide $s = $side;

    st_theme_node_get_border_color($!sttn, $side, $color);
    propReturnObject($color, $raw, |Mutter::Clutter::Color.getTypePair)
  }

  method get_border_image ( :$raw = False ) is also<get-border-image> {
    propReturnObject(
      st_theme_node_get_border_image($!sttn),
      $raw,
      |Gnome::Shell::Image.getTypePair
    );
  }

  method get_border_radius (Int() $corner) is also<get-border-radius> {
    my StCorner $c = $corner;

    st_theme_node_get_border_radius($!sttn, $c);
  }

  method get_border_width (Int() $side) is also<get-border-width> {
    my StSide $s = $side;

    st_theme_node_get_border_width($!sttn, $side);
  }

  method get_box_shadow ( :$raw = False ) is also<get-box-shadow> {
    propReturnObject(
      st_theme_node_get_box_shadow($!sttn),
      $raw,
      |Gnome::Shell::Shadow.getTypePair
    );
  }

  proto method get_color (|)
    is also<get-color>
  { * }

  multi method get_color (Str() $property_name) {
    samewith($property_name, Mutter::Clutter::Color.alloc);
  }
  multi method get_color (
    Str()                 $property_name,
    MutterClutterColor()  $color,
                         :$raw            = False
  ) {
    st_theme_node_get_color($!sttn, $property_name, $color);
    propReturnObject($color, $raw, |Mutter::Clutter::Color.getTypePair);
  }

  proto method get_content_box (|)
    is also<get-content-box>
  { * }

  multi method get_content_box (MutterClutterActorBox() $allocation) {
    samewith($allocation, Mutter::Clutter::ActorBox.alloc);
  }
  multi method get_content_box (
    MutterClutterActorBox()  $allocation,
    MutterClutterActorBox()  $content_box,
                            :$raw          = False
  ) {
    st_theme_node_get_content_box($!sttn, $allocation, $content_box);
    propReturnObject(
      $content_box,
      $raw,
      |Mutter::Clutter::ActorBox.getTypePair
    );
  }

  method get_double (Str() $property_name) is also<get-double> {
    st_theme_node_get_double($!sttn, $property_name);
  }

  method get_element_classes is also<get-element-classes> {
    CArrayToArray( st_theme_node_get_element_classes($!sttn) );
  }

  method get_element_id is also<get-element-id> {
    st_theme_node_get_element_id($!sttn);
  }

  method get_element_type is also<get-element-type> {
    st_theme_node_get_element_type($!sttn);
  }

  method get_font ( :$raw = False ) is also<get-font> {
    propReturnObject(
      st_theme_node_get_font($!sttn),
      $raw,
      |Pango::Font::Description.getTypePair
    );
  }

  method get_font_features is also<get-font-features> {
    st_theme_node_get_font_features($!sttn);
  }

  method get_foreground_color (MutterClutterColor() $color, :$raw = False)
    is also<get-foreground-color>
  {
    st_theme_node_get_foreground_color($!sttn, $color);
    propReturnObject($color, $raw, |Mutter::Clutter::Color.getTypePair);
  }

  method get_height is also<get-height> {
    st_theme_node_get_height($!sttn);
  }

  method get_horizontal_padding is also<get-horizontal-padding> {
    st_theme_node_get_horizontal_padding($!sttn);
  }

  method get_icon_colors ( :$raw = False ) is also<get-icon-colors> {
    propReturnObject(
      st_theme_node_get_icon_colors($!sttn),
      $raw,
      |Gnome::Shell::IconColors.getTypePair
    );
  }

  method get_icon_style is also<get-icon-style> {
    StIconStyleEnum( st_theme_node_get_icon_style($!sttn) )
  }

  method get_length (Str() $property_name) is also<get-length> {
    st_theme_node_get_length($!sttn, $property_name);
  }

  method get_letter_spacing is also<get-letter-spacing> {
    st_theme_node_get_letter_spacing($!sttn);
  }

  method get_margin (Int() $side) is also<get-margin> {
    my StSide $s = $side;

    st_theme_node_get_margin($!sttn, $s);
  }

  method get_max_height is also<get-max-height> {
    st_theme_node_get_max_height($!sttn);
  }

  method get_max_width is also<get-max-width> {
    st_theme_node_get_max_width($!sttn);
  }

  method get_min_height is also<get-min-height> {
    st_theme_node_get_min_height($!sttn);
  }

  method get_min_width is also<get-min-width> {
    st_theme_node_get_min_width($!sttn);
  }

  proto method get_outline_color (|)
    is also<get-outline-color>
  { * }

  multi method get_outline_color {
    samewith( Mutter::Clutter::Color.alloc );
  }
  multi method get_outline_color (MutterClutterColor() $color, :$raw = False) {
    st_theme_node_get_outline_color($!sttn, $color);
    propReturnObject($color, $raw, |Mutter::Clutter::Color.getTypePair)
  }

  method get_outline_width is also<get-outline-width> {
    st_theme_node_get_outline_width($!sttn);
  }

  method get_padding (Int() $side) is also<get-padding> {
    my StSide $s = $side;

    st_theme_node_get_padding($!sttn, $s);
  }

  proto method get_paint_box (|)
    is also<get-paint-box>
  { * }

  multi method get_paint_box (MutterClutterActorBox() $allocation) {
    samewith($allocation, Mutter::Clutter::ActorBox.alloc);
  }
  multi method get_paint_box (
    MutterClutterActorBox()  $allocation,
    MutterClutterActorBox()  $paint_box,
                            :$raw         = False
  ) {
    st_theme_node_get_paint_box($!sttn, $allocation, $paint_box);
    propReturnObject($paint_box, $raw, |Mutter::Clutter::ActorBox.getTypePair);
  }

  method get_parent is also<get-parent> {
    CArrayToArray( st_theme_node_get_parent($!sttn) );
  }

  method get_pseudo_classes is also<get-pseudo-classes> {
    st_theme_node_get_pseudo_classes($!sttn);
  }

  method get_shadow (Str() $property_name, :$raw = False)
    is also<get-shadow>
  {
    propReturnObject(
      st_theme_node_get_shadow($!sttn, $property_name),
      $raw,
      |Gnome::Shell::Shadow.getTypePair
    )
  }

  method get_text_align is also<get-text-align> {
    StTextAlignEnum( st_theme_node_get_text_align($!sttn) );
  }

  method get_text_decoration is also<get-text-decoration> {
    StTextDecorationEnum( st_theme_node_get_text_decoration($!sttn) );
  }

  method get_text_shadow ( :$raw = False ) is also<get-text-shadow> {
    propReturnObject(
      st_theme_node_get_text_shadow($!sttn),
      $raw,
      |Gnome::Shell::Shadow.getTypePair
    );
  }

  method get_theme ( :$raw = False ) is also<get-theme> {
    propReturnObject(
      st_theme_node_get_theme($!sttn),
      $raw,
      |Gnome::Shell::Theme.getTypePair
    );
  }

  method get_transition_duration is also<get-transition-duration> {
    st_theme_node_get_transition_duration($!sttn);
  }

  method get_url (Str() $property_name) is also<get-url> {
    st_theme_node_get_url($!sttn, $property_name);
  }

  method get_vertical_padding is also<get-vertical-padding> {
    st_theme_node_get_vertical_padding($!sttn);
  }

  method get_width is also<get-width> {
    st_theme_node_get_width($!sttn);
  }

  method hash {
    st_theme_node_hash($!sttn);
  }

  method invalidate_background_image is also<invalidate-background-image> {
    st_theme_node_invalidate_background_image($!sttn);
  }

  method invalidate_border_image is also<invalidate-border-image> {
    st_theme_node_invalidate_border_image($!sttn);
  }

  proto method lookup_color (|)
    is also<lookup-color>
  { * }

  multi method lookup_color (
    Str()                 $property_name,
    Int()                 $inherit
  ) {
    samewith($property_name, $inherit, Mutter::Clutter::Color.alloc)
  }
  multi method lookup_color (
    Str()                 $property_name,
    Int()                 $inherit,
    MutterClutterColor()  $color,
                         :$raw            = False
  ) {
    my gboolean $i = $inherit.so.Int;

    st_theme_node_lookup_color($!sttn, $property_name, $inherit, $color);
    propReturnObject($color, $raw, |Mutter::Clutter::Color.getTypePair)
  }

  proto method lookup_double (|)
    is also<lookup-double>
  { * }

  multi method lookup_double (
    Str() $property_name,
    Int() $inherit
  ) {
    samewith($property_name, $inherit, $);
  }
  multi method lookup_double (
    Str() $property_name,
    Int() $inherit,
          $value is rw
  ) {
    my gdouble  $v = 0e0;
    my gboolean $i = $inherit.so.Int;

    st_theme_node_lookup_double($!sttn, $property_name, $inherit, $v);
    $value = $v;
  }

  proto method lookup_length (|)
    is also<lookup-length>
  { * }

  multi method lookup_length (
    Str() $property_name,
    Int() $inherit        = 0
  ) {
    samewith($property_name, $inherit, $);
  }
  multi method lookup_length (
    Str() $property_name,
    Int() $inherit,
          $length is rw
  ) {
    my gboolean $i = $inherit.so.Int;
    my gdouble  $l = 0e0;

    st_theme_node_lookup_length($!sttn, $property_name, $i, $l);
    $length = $l;
  }

  proto method lookup_shadow (|)
    is also<lookup-shadow>
  { * }

  multi method lookup_shadow (
    Str                         $property_name,
    Int()                       $inherit,
  ) {
    samewith( $property_name, $inherit, newCArray(StShadow) );
  }
  multi method lookup_shadow (
    Str                         $property_name,
    Int()                       $inherit,
    CArray[Pointer[StShadow]]   $shadow,
                               :$raw = False
  ) {
    my gboolean $i = $inherit.so.Int;

    st_theme_node_lookup_shadow($!sttn, $property_name, $inherit, $shadow);
    propReturnObject( ppr($shadow), $raw, |Gnome::Shell::Shadow.getTypePair );
  }

  proto method lookup_time (|)
    is also<lookup-time>
  { * }

  multi method lookup_time (
    Str() $property_name,
    Int() $inherit
  ) {
    samewith($property_name, $inherit, $);
  }
  multi method lookup_time (
    Str() $property_name,
    Int() $inherit,
          $value          is rw
  ) {
    my gboolean $i = $inherit.so.Int;
    my gdouble  $v = 0e0;

    st_theme_node_lookup_time($!sttn, $property_name, $inherit, $v);
    $value = $v;
  }

  proto method lookup_url (|)
    is also<lookup-url>
  { * }

  multi method lookup_url (
    Str()          $property_name,
    Int()          $inherit
  ) {
    samewith( $property_name, $inherit, newCArray(GFile) )
  }
  multi method lookup_url (
    Str()          $property_name,
    Int()          $inherit,
    CArray[GFile]  $file,
                  :$raw            = False
  ) {
    my gboolean $i = $inherit.so.Int;

    st_theme_node_lookup_url($!sttn, $property_name, $i, $file);
    propReturnObject( ppr($file), $raw, |GIO::File.getTypePair );
  }

  method paint (
    StThemeNodePaintState() $state,
    MutterCoglFramebuffer() $framebuffer,
    MutterClutterActorBox() $box,
    Int()                   $paint_opacity,
    Num()                   $resource_scale
  ) {
    my guint8 $p = $paint_opacity;
    my gfloat $r = $resource_scale;

    st_theme_node_paint($!sttn, $state, $framebuffer, $box, $p, $r);
  }

  method paint_equal (StThemeNode() $other) is also<paint-equal> {
    so st_theme_node_paint_equal($!sttn, $other);
  }

  method to_string is also<to-string> {
    st_theme_node_to_string($!sttn);
  }

}


our subset StThemeNodePaintStateAncestry is export of Mu
  where StThemeNodePaintState | GObject;

class Gnome::Shell::St::Theme::Node::PaintState {
  also does GLib::Roles::Object;
  
  has StThemeNodePaintState $!sttnps is implementor;

  submethod BUILD ( :$st-theme-node-paint-state) {
    self.setStThemeNodePaintState($st-theme-node-paint-state)
      if $st-theme-node-paint-state
  }

  method setStThemeNodePaintState (StThemeNodePaintStateAncestry $_) {
    my $to-parent;

    $!sttnps = do {
      when StThemeNodePaintState {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StThemeNodePaintState, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::StThemeNodePaintState
    is also<StThemeNodePaintState>
  { $!sttnps }

  multi method new (
    StThemeNodePaintStateAncestry  $st-theme-node-paint-state,
                                  :$ref                        = True
  ) {
    return unless $st-theme-node-paint-state;

    my $o = self.bless( :$st-theme-node-paint-state );
    $o.ref if $ref;
    $o;
  }

  method copy (StThemeNodePaintState() $other, :$raw = False) {
    propReturnObject(
      st_theme_node_paint_state_copy($!sttnps, $other),
      $raw,
      |self.getTypePair
    );
  }

  method free {
    st_theme_node_paint_state_free($!sttnps);
  }

  method init {
    st_theme_node_paint_state_init($!sttnps);
  }

  method invalidate {
    st_theme_node_paint_state_invalidate($!sttnps);
  }

  method invalidate_for_file (GFile() $file) is also<invalidate-for-file> {
    st_theme_node_paint_state_invalidate_for_file($!sttnps, $file);
  }

  method set_node (StThemeNode() $node) is also<set-node> {
    st_theme_node_paint_state_set_node($!sttnps, $node);
  }

}
