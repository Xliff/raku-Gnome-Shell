use v6.c;

use Method::Also;
use NativeCall;

use Gnome::Shell::Raw::Types;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

our subset StThemeNodeTransitionAncestry is export of Mu
  where StThemeNodeTransition | GObject;

class Gnome::Shell::St::Theme::Node::Transition {
  also does GLib::Roles::Object;

  has StThemeNodeTransition $!sttnt is implementor;

  submethod BUILD ( :$st-node-transition ) {
    self.setStThemeNodeTransition($st-node-transition) if $st-node-transition;
  }

  method setStThemeNodeTransition (StThemeNodeTransitionAncestry $_) {
    my $to-parent;

    $!sttnt = do {
      when StThemeNodeTransition {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StThemeNodeTransition, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Mutter::Cogl::Raw::Definitions::StThemeNodeTransition
    is also<StThemeNodeTransition>
  { $!sttnt }

  multi method new (
    StThemeNodeTransitionAncestry  $st-node-transition,
                                  :$ref                 = True
  ) {
    return unless $st-node-transition;

    my $o = self.bless( :$st-node-transition );
    $o.ref if $ref;
    $o;
  }
  multi method new (
    StThemeNode()           $from_node,
    StThemeNode()           $to_node,
    StThemeNodePaintState() $old_paint_state,
    Int()                   $duration
  ) {
    my guint $d = $duration;

    my $st-node-transition = st_theme_node_transition_new(
      $from_node,
      $to_node,
      $old_paint_state,
      $d
    );

    $st-node-transition ?? self.bless( :$st-node-transition ) !! Nil;
  }

  method completed {
    self.connect($!sttnt, 'completed');
  }

  method new-frame is also<new_frame> {
    self.connect($!sttnt, 'new-frame');
  }

  method get_new_paint_state is also<get-new-paint-state> {
    st_theme_node_transition_get_new_paint_state($!sttnt);
  }

  proto method get_paint_box (|)
    is also<get-paint-box>
  { * }

  multi method get_paint_box (MutterClutterActorBox() $allocation) {
    samewith($allocation, Mutter::Clutter::ActorBox.alloc)
  }
  multi method get_paint_box (
    MutterClutterActorBox   $allocation,
    MutterClutterActorBox   $paint_box,
                           :$raw         = False
  ) {
    st_theme_node_transition_get_paint_box($!sttnt, $allocation, $paint_box);

    propReturnObject($paint_box, $raw, |Mutter::Clutter::ActorBox.getTypePair);
  }

  method paint (
    MutterCoglFramebuffer() $framebuffer,
    MutterClutterActorBox() $allocation,
    Int()                   $paint_opacity,
    Num()                   $resource_scale
  ) {
    my gint8  $o = $paint_opacity;
    my gfloat $r = $resource_scale;

    st_theme_node_transition_paint($!sttnt, $framebuffer, $allocation, $o, $r);
  }

  method update (StThemeNode() $new_node) {
    st_theme_node_transition_update($!sttnt, $new_node);
  }

}

### /home/cbwood/Projects/gnome-shell/src/st/st-theme-node-transition.h

sub st_theme_node_transition_get_new_paint_state (
  StThemeNodeTransition $transition
)
  returns StThemeNodePaintState
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_transition_get_paint_box (
  StThemeNodeTransition $transition,
  MutterClutterActorBox $allocation,
  MutterClutterActorBox $paint_box
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_transition_new (
  MutterClutterActor    $actor,
  StThemeNode           $from_node,
  StThemeNode           $to_node,
  StThemeNodePaintState $old_paint_state,
  guint                 $duration
)
  returns StThemeNodeTransition
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_transition_paint (
  StThemeNodeTransition $transition,
  MutterCoglFramebuffer $framebuffer,
  MutterClutterActorBox $allocation,
  guint8                $paint_opacity,
  gfloat                $resource_scale
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_theme_node_transition_update (
  StThemeNodeTransition $transition,
  StThemeNode $new_node
)
  is native(gnome-shell-st)
  is export
{ * }
