use v6.c;

use Gnome::Shell::St::BoxLayout;

constant INDICATOR_INACTIVE_OPACITY       is export = 128;
constant INDICATOR_INACTIVE_OPACITY_HOVER is export = 255;
constant INDICATOR_INACTIVE_SCALE         is export = 2 / 3;
constant INDICATOR_INACTIVE_SCALE_PRESSED is export = 0.5;

### /home/cbwood/Projects/gnome-shell/js/ui/pageIndicators.js

class Gnome::Shell::UI::PageIndicators
  is Gnome::Shell::St::BoxLayout
{
  has $!orientation;
  has $!reactive;
  has $nPages;

  submethod BUILD ( :$!orientation ) {
    self.vertical    = $!orientation == CLUTTER_ORIENTATION_VERTICAL;
    self.style-class = 'page-indicators';
    self.x-expand    = self.y-expand = True;
    self x-align     = self.vertical ?? CLUTTER_ACTOR_ALIGN_END
                                     !! CLUTTER_ACTOR_ALIGN_CENTER;
    self.y-align     = self.vertical ?? CLUTTER_ACTOR_ALIGN_CENTER
                                     !! CLUTTER_ACTOR_ALIGN_END;

    self.Gnome::Shell::St::BoxLayout::reactive = $!reactive = True;

    self.clip-to-allocation = True;

    $!nPages = $!currentPosition = 0;
  }

  method reactive is rw {
    Proxy.new:
      FETCH => -> $, { self.reactive },

      STORE => -> $, Bool() \r {
        for self.get-children {
          .reactive = r
        }
        $!reactive = r;
      }
  }

  method n-pages is also<n_pages elems> is rw {
    Proxy.new:
      FETCH => -> $ { $!nPages },

      STORE => -> $, Int() \p {
        return if $!nPages == p;

        my $diff = $nPage - p;
        if $diff > 0 {
          for ^$diff {
            my $pageIndex = $!nPages + 1;
            my $indicator = Gnome::Shell::St::Button.new(
              style-class => 'page-indicator',
              button-mask => ST_BUTTON_MASK_ONE   +|
                             ST_BUTTON_MASK_TWO   +|
                             ST_BUTTON_MASK_THREE,
              reactive    => True
            );
            $indicator.child = Gnome::Shell::St::Widget.new(
              style-class => 'page-indicator-icon',
              pivot-point => Graphene::Point.new( x => 0, y => 0.5 )
            );
            $indicator.clicked.tap( -> *@a {
              self.emit('page-activated', $pageIndex);
            });
            $indicator.notify('hover').tap(- > *@a {
              self.updateIndicator($indicator, $pageIndex);
            });
            $indicator.notify('pressed').tap(- > *@a {
              self.updateIndicator($indicator, $pageIndex);
            });
            self.updateIndicator($indicator, $pageIndex);
            self.add-actor($indicator);
          }
        } else {
          .destroy for self.children.tail($diff);
        }
        $!nPages = p;
        self.visible = $!nPages > 1;
      }
  }

  method get_preferred_height ($forWidth) is vfunc {
    my ($, $natHeight) = callsame;
    (0, $natHeight);
  }

  method updateIndicator ($indicator, $pageIndex) {
    my $progress = max(
      1 - ($!currentPosition - $pageIndex.abs),
      0
    );

    my $inactiveScale   = $indicator.pressed
      ?? INDICATOR_INATIVE_SCALE_PRESSED !! INDICATOR_INACTIVE_SCALE;
    my $inactiveOpacity = $indicator.hover
      ?? INDICATOR_INACTIVE_OPACITY_HOVER !! INDICATOR_INACTIVE_OPACITY;

    my $scale   = $inactiveScale  + (1   - $inactiveScale)   * $progress;
    my $opacity = $inativeOpacity + (255 - $inactiveOpacity) * $progress;

    $indicator.child.set-scale($scale);
    $indicator.child.opacity = $opacity;
  }

  method setCurrentPosition ($currentPosition) {
    $!currentPosition = $currentPosition;
    for self.get_children.kv -> $i, $child {
      self.updateIndicator($child, $i);
    }
  }

}
