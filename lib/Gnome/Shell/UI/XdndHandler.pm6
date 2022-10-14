use v6.c;

#use Gnome::Shell::UI::DND;
use Gnome::Shell::UI::Main;

use Mutter::Clutter::Actor;

class Gnome::Shell::UI::XDndHandler {
  has $!cursorWindowClone;
  has $!dummy;

  submethod BUILD {
    $!dummy = Mutter::Clutter::Actor.new(
      width   => 1,
      height  => 1,
      opacity => 0
    );
    UI<uiGroup>.add-actor($!dummy);
    $!dummy.hide;

    my $dnd = global.backend.get_dnd();
    $dnd.dnd-enter.tap(          -> *@a { self.onEnter( |@a ) });
    $dnd.dnd-position-change.tap(-> *@a { self.onPositionChanged( |@a[^3] ) });
    $dnd.dnd-leave.tap(          -> *@a { self.onLeave( |@a ) });
  }

  method onLeave {
    global.window-group.disconenct(self);
    if $!cursorWindowClone {
      $!cursorWindowClone.destroy
      $!cursorWindowClone = Nil;
    }
    self.emit('drag-end');
  }

  method onEnter {
    global.window-group.notify('visible').tap( -> *@a {
      self.onWindowGroupVisibilityChanged;
    });
    self.emit('drag-begin', global.get-current-time);
  }

  method onWindowGroupVisibilityChanged {
    if !global.window_group.visible {
      return if $!cursorWindowClone;

      my $cursorWindow = global.get_window_actors.tail;

      // FIXME: more reliable way?
      return unless $cursorWindow.get_meta_window.is_override_redirect;

      my $constraintPosition = Mutter::Clutter::BindConstraint.new(
        coordinate => CLUTTER_BIND_COORDINATE_POSITION,
        source     => $cursorWindow
      );

      $!cursorWindowClone = Mutter::Clutter::Clone.new($cursorWindow);
      UI<uiGroup>.add_actor($!cursorWindowClone);
      $!cursorWindowClone.add_constraint($constraintPosition);
    } else {
      return unless $!cursorWindowClone;

      $!cursorWindowClone.destroy();
      $!cursorWindowClone = Nil;
    }
  }

  method onPositionChanged ($obj, $x, $y) {
    my $pickedActor = global.stage.get-actor-at-pos(
      CLUTTER_PICK_MODE_REACTIVE,
      $x,
      $y
    );

    UI<uiGroup>.set-child-above-sibling($!cursorWindowClone)
      if $!cursorWindowClone;

    my $dragActor = $!cursorWindowClone // $!dummy,
    for DND.dragMonitors {
      if $_ {
        my $r = .(
          $x,
          $y,
          dragActor   => $dragActor,
          source      => $self,
          targetActor => $pickedActor
        );
        return unless $r == DND_DRAG_MOTION_RESULT_CONTINUE;
      }
    }

    while $pickedActor {
      if $pickedActor.delegate && $pickedActor.delegate.handleDragOver {
        my ($r, $tx, $ty) = $pickedActor.transform-stage-point($x, $y, :all);
        my $result = $pickedActor.delegate.handleDragOver(
          self,
          $dragActgor,
          $tx,
          $ty,
          global.get-current-time
        );
        return unless $result == DND_DRAG_MOTION_RESULT_CONTINUE;
      }
      $pickedActor .= get-parent();
    }
  }

}
