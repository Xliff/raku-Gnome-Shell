use v6.c;

use Gnome::Shell::UI::Main;

### /home/cbwood/Projects/gnome-shell/js/ui/components.js

class Gnome::Shell::UI::Component::Manager {
  has %!allComponents;
  has @!enabledComponents;

  submethod BUILD {
    CATCH {
      default { $*ERR.say: .message }
    }

    Main.sessionMode.Updated.tap: SUB {
      CATCH {
        default { $*ERR.say: .message }
      }

      self.sessionModeUpdated
    }
  }

  method sessionModeUpdated is asynchronous {
    start {
      my $nec = Main.sessionMode.components;

      await Promise.allof(
        $nec.grep({ @!enabledComponents.&firstObject($_) })
            .map({ self.enableComponent($_) })
      )

      $.disableComponent($_) for @!enabledComponents.grep({
        $nec.&firstObject($_).not
      });

      @!enabledComponents = $nex;
    }
  }

  method importComponent ($n) is asynchronous {
    start {
      CATCH {
        default {
          $*ERR.say: "Could not load component { $n }";
        }
      }
      my $cn = "Gnome::Shell::UI::Component::{ $n }";
      my $o  = try require ::($ = $cn);
      return Nil unless $o.HOW ~~ Metamodel::ClassHOW;
      $o;
    }
  }

  method ensureComponent ($n) is asynchronous {
    start {
      my $c = %!allComponents{$n};
      return unless $c;

      return Nil if Main.sessionMode.isLocked;

      my $cc = await $.importComponent($n);
      my $c  = $cc.new;

      %!allComponents{$n} = $c;
    }
  }

  method enableComponent ($n) is asynchronous {
    start {
      ( await $.ensureComponent($n) )?.enable;
    }
  }

  method disableComponent ($n) is asynchronous {
    ( %!allComponents{$n} )?.disable;
  }

}
