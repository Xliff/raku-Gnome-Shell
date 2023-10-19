use v6.c;

use Mutter::Clutter::ActorBox;
use Mutter::Clutter::Margin;
use Gnome::Shell::Raw::Types;
use Gnome::Shell::SquareBin;
use Gnome::Shell::St::Bin;
use Gnome::Shell::St::BoxLayout;
use Gnome::Shell::St::Label;
use Gnome::Shell::St::TextureCache;
use Gnome::Shell::St::ViewPort;

const PAGE_SWITCH_TIME = 300;

enum IconSize = (
  LARGE       => 96,
  MEDIUM      => 64,
  MEDIUM_SMALL=> 48,
  SMALL       => 32,
  SMALLER     => 24,
  TINY        => 16,
);

constant APPICON_ANIMATION_OUT_SCALE = 3;
constant APPICON_ANIMATION_OUT_TIME  = 250;
constant ICON_POSITION_DELAY         = 10;
constant LEFT_DIVIDER_LEEWAY         = 20;
constant RIGHT_DIVIDER_LEEWAY        = 20;

constant defaultGridModes = [
  ( rows => 8, columns => 3 },
  ( rows => 6, columns => 4 },
  ( rows => 4, columns => 6 },
  ( rows => 3, columns => 8 }
];

enum DragLocationEnum is export = (
  DRAG_LOCATION_INVALID     => 0,
  DRAG_LOCATION_START_EDGE  => 1,
  DRAG_LOCATION_ON_ICON     => 2,
  DRAG_LOCATION_END_EDGE    => 3,
  DRAG_LOCATION_EMPTY_SPACE => 4
);

sub zoomOutActor ($actor) is export {
  zoomOutActorAtPos( $actor, |$actor.transformed-position );
}

sub zoomOutActorAtPos ($actor, $x, $y) is export {
  my $monitor = Main.layoutManager.findMonitorForActor($actor);
  return unless $monitor;

  my $actorClone = $actor.clone.setAttributes(
    reactive    => False,
    size        => $actor.transformed-size,
    position    => $actor.position,
    opacity     => 255,
    pivot-point => (0.5, 0.5)
  );

  Main.uiGroup.add-actor($actorClone);
  my (  $w,   $h) = $actorClone.size);
  my ($sxw, $sxh) = ($w, $h) »*» APPICON_ANIMATION_OUT_SCALE;
  my ($sx,  $sy)  = ($sxw - $w, $sxh - $h) »/» 2;

  my $cx = $sx.&clamp($m.x .. $m.x + $m.width);
  my $cy = $sy.&clamp($m.y .. $m.y + $m.height);

  $actorClone.ease(
    scale       => APPICON_ANIMATION_OUT_SCALE,
    translation => ($cx - $sx, $cy - $sy),
    opacity     => 0,
    duration    => APPICON_ANIMATION_OUT_SCALE,
    mode        => CLUTTER_EASE_OUT_QUAD,
    onComplete => -> *@a { $actorClone.destroy }
  );
}

sub animateIconPosition ($icon, $box, $changed) is export {
  if $icon.has-allocation.not || $icon.allocation.equal($box) {
    $icon.allocate($box);
    return False;
  }

  $icon.save-easing-state;
  ( .easing-mode, .delay ) =
    (CLUTTER_EASE_OUT_QUAD, ICON_POSITION_DELAY * $changed);
  $icon.allocate($box);
  $icon.retore-easing-state;
  True;
}

sub swap ($value, $length) {
  $length - $value - 1;
}

class Gnome::Shell::UI::IconGrid::f.n is Gnome::Shell::SquareBin {
  has $.box     is rw;
  has $.iconBin is rw;

  submethod TWEAK ( :$label, :$param ) {
    $params<showLabel> //= True;

    my $style-class = 'overview-icon';
    $style-class ~= ' overview-icon-with-label' if $params<showLabel>;

    self.setAttributes( :$style-class );

    self.box = Gnome::Shell::St::BoxLayout.new(
      vertical => True,
      expand   => True
    );
    ( .child, .iconBox ) = ( .box, ICON_SIZE ) given self;
    $!iconBin = Gnome::Shell::St::Bin(
      x-align => CLUTTER_ACTOR_ALIGN_CENTER
    );

    self.box.add-actor($!iconBin);

    if $params<showLabel> {
      self.label = Gnome::Shell::St::Label.new( text => $label );
      self.label.clutter-text.setAttributes(
        align => CLUTTER_ACTOR_ALIGN_CENTER
      );
      self.box.add-actor(self.label);
    } else {
      self.label = Nil;
    }

    ($!createIcon, $!setSizeManually) = $params<createIcon setSizeManually>;
    self.icon = Nil;

    my $s     = self;
    my $cache = Gnome::Shell::St::TextureCache.default;
    $cache.icon-theme-changed.tap( -> *@a {
      $s.onIconThemeChanged( |@a );
    });
  }

  method createIcon ($s) {
    X::Gnome::Shell::NYI.new(
      ".createIcon is not implemented in { .^name }"
    ).throw;
  }

  method setIconSize ($size) {
    X::Gnome::Shell::Error.new(
      "Cannot set icon size in { .^name } because it is restricted!"
    ).throw;

    return if $size == $!iconSize;

    self.createIconTexture($size);
  }

  method createIconTexture ($size) {
    self.icon.destroy if self.icon;

    $!iconSize = $size;
    self.icon = self.createIcon($!iconSize);
    $!iconBin.child = self.icon;
  }

  method style-changed is vfunc {
    nextsame;
    my $size = $!setSizeManually ?? self.iconSize !! Nil;

    unless $!setSizemanually {
      $size = do if self.theme-node.lookup-length('icon-size') -> $l {
        $l / Gnome::Shell::St::ThemeContext.get-for-stage(
          Global.Stage
        ).scale-factor;
      } else {
        ICON_SIZE;
      }

      return if self.iconSize == $size && $!iconBin.child;

      self.createIconTexture($size);
    }

    method onIconThemeChanged {
      self.update;
    }

    method animateZoomOut {
      zoomOutActor(self.child);
    }

    method animateZoomOutAtPos ($x, $y) {
      zoomOutActorAtPos(self.child, $x, $y);
    }

    method update {
      self.createIconTexture(self.iconSize);
    }
  }

}

#| Gnome::Shell::UI::IconGrid::Layout
#|   Property Addendum
#|     - allow-incomplete-pages
class Gnome::Shell::UI::IconGrid::Layout
  is Mutter::Clutter::LayoutManager
{
  has $.pageSizeChanged = False;
  has $.pageHeight      = 0;
  has $.pageWidth       = 0;
  has $.nPages          = -1;
  has @.pages;
  has %.items;

  has $!containerDestroyedId   =  0;
  has @!updateIconSizesLaterId =  0;

  has $!childrenMaxSize;

  has gboolean $.allow-incomplete-pages is rw is g-property;
  has gint     $.column-spacing         is rw is g-property is default(0);
  has gint     $.columns-per-page       is rw is g-property is default(6);
  has gint     $.fixed-icon-size        is rw is g-property;
  has gint     $.icon-size              is rw is g-property;
  has gint     $.max-column-spacing     is rw is g-property;
  has gint     $.max-row-spacing        is rw is g-property;
  has gint     $.row-spacing            is rw is g-property is default(0);
  has gint     $.rows-per-page          is rw is g-property is default(4);

  has $.last-row-align
    is rw
    is g-property
    # is g-typed(Mutter::Raw::Enums::ClutterActorAlign.get_type);
    is default(CLUTTER_ACTOR_ALIGN_FILL);

  has $!orientation
    is g-property
    # is g-typed(Mutter::Raw::Enums::ClutterOrientation.get_type)
    is default(CLUTTER_ORIENTATION_VERTICAL);

  has $.page-halign
    is rw
    is g-property
    # is g-typed(Mutter::Raw::Enums::ClutterActorAlign.get_type)
    is default(CLUTTER_ACTOR_ALIGN_FILL);

  has $.page-padding
    is rw
    # is g-typed(MutterClutterMargin.get_type)
    is g-property;

  has $.page-valign
    is rw
    is g-property
    # is g-typed(Mutter::Raw::Enums::ClutterActorAlign.get_type);
    is default(CLUTTER_ACTOR_ALIGN_FILL);

  method pages-changed is g-signal { }

  method orientation is rw {
    Proxy.new:
      FETCH => $     { $!orientation },
      STORE => $, \v {
        return if $!orientation === v;

        $!request-mode = given v {
          when CLUTTER_ORIENTATION_HORIZONTAL {
            CLUTTER_REQUEST_WIDTH_FOR_HEIGHT
          }
          when CLUTTER_ORIENTATION_VERTICAL {
            CLUTTER_REQUEST_HEIGHT_FOR_WIDTH
          }
        }

        $!orientation = v;
        $.notify('orientation');
      }
  }

  method n-pages is
    also<
      n_pages
      elems
    >
  { $!nPages }

  submethod TWEAK (
    :$orientation,
    :page_padding(:$page-padding)
  ) {
    self.orientation  = $orientation  // CLUTTER_ORIENTATION_VERTICAL;
    self.page-padding = $page-padding // MutterClutterMargin.new;

    self.iconSize = self.fixed-icon-size !== -1
      ?? self.fixed-icon-size
      !! ICON_SIZE_LARGE
  }

  method pagePadding { $!page-padding }

  method findBestIconSize {
    my ($nColumns, $nRows) = ( .columns-per-page, .rows-per-page) given self;
    my ($cSPP, $rSPP) =
      ( .column-spacing, .row-spacing ) »*« ($nColumns, $nRows)».pred;
    my $firstItem = self.container.head;

    return self.fixed-icon-size if self.fixed-icon-size !== -1;

    my @iconSizes = IconSize.enums.values.sort(*);
    for @iconSizes {
      my ($uw, $uh) = do if $firstItem {
        $firstItem.icon.setIconSize($_);
        ($nColumns, $nRows) »*» $firstItem.preferred-size.max;
      } else {
        ($uw, $uh) »*» $_;
      }

      my $emptyHSpace = self.page-width - $uw - $cSPP -
        self.pagePadding.left - self.pagePadding.right;
      my $emptyVSpace = self.page-height - $uh - $rSPP -
        self.pagePadding.top - self.pagePadding.bottom;

      return $_ if $emptyHSpace == $emptyVSpace == 0;
    }

    return ICON_SIZE_TINY;
  }

  method getChildrenMaxSize {
    without $!childrenMaxSize {
      my ($minWidth, $minHeight) = 0 xx ;

      my $nPages = $!pages.elems;
      for $pages[] -> $page {
        my $nVisibleItems = $page.visibleChildren.elems;
        for $page.visibleChildren -> $item {
          my ($cmh, $cmw) =
            ( .get-preferred-height, .get-preferred-width )».head given $item;

          $minWidth  = max($minWidth, $cmw);
          $minHeight = max($minHeight, $cmh);
        }
      }

      $!childrenMaxSize = max($minWidth, $minHeight);
    }

    $!childrenMaxSize;
  }

  method updateVisibleChildrenForPage ($i) {
    $!pages[$i].visibleChildren = $!pages[$i].children.grep( *.visible );
    Nil;
  }

  method updatePages {
    .relocateSurplusItems($_) for $!pages;
  }

  method unlinkItem ($i) {
    with $!items.get($i) {
      $i.disconnect for .destroyId, .visibleId, .queueRelayoutId;
    }
    $!items.delete($i);
  }

  method removePage ($i) {
    .unlinkItem($i) for $!pages[$i].children[];

    .pageIndex-- if .pageIndex > $i for $i.values[];

    $!pages.splice($i, 1);
    self.emit('pages-changed');
  }

  method visible-page-items is also<visiblePageItems> ($i) {
    @!pages[$i].visibleChildren;
  }

  method items-per-page is also<itemsPerPage> {
    $!columns-per-page * $!row-rows-per-page
  }

  method is-rtl is also<isRtl> {
    Clutter::Main.get-default-text-direction == CLUTTER_TEXT_DIRECTION_RTL;
  }

  method fillItemVacancies ($i) {
    return unless $i < $!pages.elems;

    my $visiblePageItems = self.visiblePageItems($i);
    my $itemsPerPage     = self.items-per-page;

    return if $visiblePageItems == $itemsPerPage;

    my $visibleNextPageItems = $!pages[$i + 1].visibleChildren;

    my $nMissingItems = min(
      $itemsPerPage - $visiblePageItems.elems,
      $visibleNextPageItems.elems
    )

    for $visibleNextPageItems[ ^$nMissingItems ] {
      self.removeItemData($_);
      self.addItemToPage($_, $i);
    }
  }

  method removeItemData ($item) {
    my $itemData  = $!items.get($item);
    my $pageIndex = $itemData.pageIndex;
    my $page      = $!pages[$pageIndex];
    my $itemIndex = $page.children.first({ +$_ === +$item }, :k);

    self.unlinkItem($item);
    $page.children.splice($itemIndex, 1);

    self.updateVisibleChildrenForPage($pageIndex);

    my $visibleItems = $!pages[$pageIndex].visibleChildren;

    self.removePage($pageIndex)        unless $visibleItems;
    self.fillItemVacancies($pageIndex) unless $self.allow-incomplete-pages;
  }

  method relocateSurplusItems ($index) {
    return if $.visiblePageItems.elems <= $.itemsPerPage;

    my $nExtraItems = $.visiblePageItems.elems - $.itemsPerPage;
    for ^$nExtraItems {
      my $idx = $visiblePageItems.elems - .succ;
      $.removeItemData( $.visiblePageItems[$idx] );
      $.addItemToPage( $.visiblePageItems[$idx], $index.succ );
    }
  }

  method appendPage {
    @!pages.push: { children => [] };
    self.emit('pages-changed');
  }

  method addItemToPage ($item, $pageIndex is copy, $index is copy) {
    $.appendPage if @!pages.elems.not;
    $.appendPage if $pageIndex == @!pages.elems;

    $pageIndex = @!pages.elems.pred if $pageIndex === -1;

    $index = @!pages[$pageIndex].childen.elems if $index === -1;

    my $s = self;
    $item.destroy.tap( -> *@a { $s.removeItemData($item) });

    $item.notify('visible').tap( -> *@a {
      my $d = $!items.get($item);
      $s.updateVisibleChildrenForPage($id.pageIndex);
      $item.visible ?? $s.relocateSurplusItems($d.pageIndex);
                    !! $s.fillItemVacancies($d.pageIndex);
    });

    $item.queue-relayout.tap( -> *@a { $s.childrenMaxSize = -1 });

    # cw: So the point here is that we do not need to specifically track
    #     signal IDs now that we have the signals-manager interface to
    #     get them for us. Any ID in previously written code can be
    #     replaced with an expression like those, below
    $!items.child-set(
      $item,

      actor           => $item,
      pageIndex       => $pageIndex,
      destroyId       => $item.signals-manager<destroy>.tail,
      visibleId       => $item.signals-manager<notify::visible>.tail,
      queueRelayoutId => $item.signals-manager<queue-relayout>.tail
    );

    $.icon.setIconSize($!iconSize);
    @pages[$pageIndex].children.splice($index, 0, $item);
    $.relocateSurplusItems($pageIndex);
  }

method calculateSpacing ($childSize) {
  my ($nColums, $nRows) = ($!columns-per-page, $!rows-per-page);
  my ($usedWidth, $usedHeight) = ($nColumns, $nRows) »*» $childSize;

  my $colSPage = $!column-spacing * $nColumns.pred;
  my $rowSPP   = $!row-spacing    * $nRows.pred;

  my $emptyHSpace = $!page-width  - $usedWidth  - $colSPP - $!page-padding.aw;
  my $emptyVSpace = $!page-height - $usedHeight - $rowSPP - $!page-padding.ah;

  my ($leftEmptySpace, $topEmptySpace) = ( .left, .top ) given $!page-padding;

  my ($hSpacing, $vSpacing);

  $hSpacing = do given $!page-halign {
    when CLUTTER_ACTOR_ALIGN_START {
      $!column-spacing
    }
    when CLUTTER_ACTOR_ALIGN_CENTER {
      $leftEmptySpace += ($emptyHSpace / 2).floor;
      $!column-spacing;
    }
    when CLUTTER_ACTOR_ALIGN_END {
      $leftEmptySpace += $emptyHSpace;
      $!column-spacing;
    }
    when CLUTTER_ACTOR_ALIGN_FILL  {
      my $maxColumnSpacing;

      my $h-to-set = $!column-spacing + $emptyHSpace / $nColumns.pred;

      if $.max-column-spacing.defined && $h-to-set > $.max-column-spacing {
        my $extraHSpacing =
          ($.max-column-spacing - $.column-spacing) * $nColums.pred;

        $h-to-set = $.max-column-spacing;

        $leftEmptySpace = max(0, $emptyHSpace - $extraHSpacing);
      }

      $h-to-set;
    }

    $vSpacing = do given $!page-valign {
      when CLUTTER_ACTOR_ALIGN_START {
        $!row-spacing;
      }
      when CLUTTER_ACTOR_ALIGN_CENTER {
        $topEmptySpace += ($emptyVSpace / 2).floor;
        $!row-spacing;
      }
      when CLUTTER_ACTOR_ALIGN_END {
        $topEmptySpace += $emptyVSpace;
        $!row-spacing;
      }
      when CLUTTER_ACTOR_ALIGN_FILL   {
        my $maxRowSpacing;

        my $v-to-set = $!row-spacing + $emptyVSpace / $nRows.pred;

        if $.max-row-spacing && $v-to-set > $.max-row-spacing {
          my $extraVSpacing =
            ($.max-row-spacing - $.row-spacing) * $nRows.pred;

          $v-to-set = $.max-row-spacing;

          $topEmptySpace = max(0, $emptyVSpace - $extraVSpacing);
        }

        $v-to-set;
      }
    }

    ($leftEmptySpace, $topEmptySpace, $hSpacing, $vSpacing);
  }

  method getRowPadding ($align, $items, $itemIndex, $childSize, $spacing) {
    return 0
      if $align == (CLUTTER_ACTOR_ALIGN_START, CLUTTER_ACTOR_ALIGN_FILL).any;

    my $nRows = ($items.elems / $.columns-per-page).ceiling;

    my $rowAlign = 0;
    my $row      = ($itemIndex / $.columns-per-page).floor;

    return 0 if $row < $nRows.pred;

    my $rowStart = $row * $.columns-per-page;
    my $rowEnd   = min($row.succ * $.columns-per-page.pred, $items.elems.pred);
    my $inTheRow = $rowEnd - $rowStart + 1;
    my $nEmpty   = $.columns-per-page - $inTheRow;
    my $availW   = $nEmpty * ($spacing + $childSize);

    my $rowAlign = given $align {
      when CLUTTER_ACTOR_ALIGN_START | CLUTTER_ACTOR_ALIGN_FILL { $rowAlign }

      when CLUTTER_ACTOR_ALIGN_CENTER { $availW / 2 }
      when CLUTTER_ACTOR_ALIGN_END    { $availW     }
    }

    $.is-rtl ?? -$rowAlign !! $rowAlign;
  }

  method onDestroy {
    if $!updateIconSizesLaterId.defined {
      Global.compositor.get-laters.remove($!updateIconSizesLaterId);
      $!updateIconSizesLaterId = Nil;
    }
  }

  method set-container ($container) is also<set_container> is vfunc {
    $!container.disconnectObject(self) if $!container;
    $!container = $container;
    my $s = self;
    $!container.destroy.tap( -> *@a { $s.onDestroy }) if %$!container;
  }

  method get-preferred-width ($container, $forHeight) is vfunc {
    do given $!orientation {
      when CLUTTER_ORIENTATION_VERTICAL {
        (ICON_SIZE_TINY, $!page-width)
      }
      when CLUTTER_ORIENTATION_HOIZONTAL {
        ($!page-width * @!pages.elems) xx 2;
      }
    }
  }

  method get-preferred-height ($container, $forWidth) {
    do given $!orientation {
      when CLUTTER_ORIENTATION_VERTICAL {
        ($!page-height * @!pages.elems) xx 2
      }
      when CLUTTER_ORIENTATION_HORIZONTAL {
        (ICON_SIZE_TINY, $!page-height)
      }
    }
  }

  method allocate is vfunc {
    X::Gnome::Shell::BadSize.new(
      message => q«IconGridLayout.adapToSize wasn't called before allocation'»
    ).throw if ($!page-width, $!page-height).any == 0;

    my $childSize = $.getChildrenMaxSize;

    my ($leftEmptySpace, $topEmptySpace, $hSpacing, $vSpacing) =
      $.calculateSpacing($childSize);

    my $childBox = Mutter::Clutter::ActorBox.new;

    my ($cPP, $o)   = ( $.columns-per-page, $.orientation);
    my ($pW, $pH)   = ($.page-width, $.page-height);
    my ($pSC, $lRA) = ($.page-size-changed, $.last-row-aligned);
    my ($sEA, $nCI) = ($.should-ease-items, 0);

    for @!pages.kv -> $pi is rw, $p {
      $pi = @!pages.elems if $.is-rtl && $o == CLUTTER_ORIENTATION_HOIZONTAL;

      for $p.visibleChildren.kv -> $ii, $i {
        my $row = ($ii, $cPP).floor;
        my $col =  $ii % $cPP;

        $col = $cPP if $.is-rtl;

        my $rowPadding = $.getRowPadding(
          $lRA,
          $p.visibleChildren,
          $ii,
          $childSize,
          $hSpacing
        );

        my $x = $leftEmptySpace + $rowPadding + $col * ($childSize + $hSpacing);
        my $y = $topEmptySpace + $row * ($childSize + $vSpacing);

        $o == CLUTTER_ORIENTATION_HOIZONTAL ?? $x += $pi * $pW
                                            !! $y += $pi * $pH;

        $childBox.origin = ($x, $y)».floor;

        my ($, $, $nW, $nH) = $.get-preferred-size;
        $childBox.size( [$childSize, $nW], [$childSize, $nH] )».max );

        if $sEI || $pSC {
          $i.allocate($childBox);
        } elsif $.animateIconPosition($i, $childBox, $nCI) {
          $nCI++;
        }
      }
    }

    $.page-size-changed = $.should-ease-items = False;
  }

  method findBestPageToAppend ($sp) {
    for $sp ..^ @!pages.elems {
      return $_ if @!pages[$_] < self.items-per-page;
    }
    return @!pages.elems;
  }

  method addItem ($item, $page = Nil, $index = Nil) {
    X::Gnome::Shell::ItemExists.new(
      message => "Item { $item } already added to IconGridLayout"
    ).throw if @!items.first({ +$_ === +$item });

    X::Gnome::Shell::BadLength.new(
      message => "Page { $page } does not exist!"
    ).throw if $page > @!pages.elems;

    return unless $!container;

    $page = $.findBestPageToAppend($page) with $page && $index;

    $!should-ease-items = True;

    $!container.add-child($item);
    $.addItemToPage($item, $page, $index);
  }

  method appendItem ($item) { $.addItem($item) }

  method moveItem ($item, $newPage is copy, $newPosition) {
    X::Gnome::Shell::BadItem.new(
      message => "Item { $item } is not a part of the IconGridLayout"
    ).throw if @!items.first({ +$_ === +$item }).not;

    $!should-ease-items = True;

    $.removeItemData($item);

    $newPage = $.findBestPageToAppend($newPage) with $page && $newPosition;

    $.addItemToPage($item, $newPage, $newPosition);
  }

  method getItemsAtPage ($pageIndex) {
    X::Gnome::Shell::BadIndex.new(
      message => "IconGridLayout does not have a page { $pageIndex }"
    ).throw if $pageIndex >= @!pages.elems;

    @!pages.children.List;
  }

  method getItemPosition ($item);
    return Nil unless @!items.first({ +$_ === +$item });

    my $data = @!items.get($item);
    my $vi    = @!pages[$data.pageIndex].visibleChildren;

    ( $data.pageIndex, $visileItems.first({ +$_ === +$item }, :k) );
  }

  method getItemAt ($page, $position) {
    return Nil unless $page ~~ 0 .. @!pages.elems;

    my $visibleItems = $!pages[$page}.visibleChildren;

    return Nil unless $position ~~ 0 .. $visibleItems.elems;

    $visibleItems[$position];
  }

  method getItemPage ($item) {
    return Nil unless @!items.has($item);

    $items.get($item).pageIndex;
  }

  method ensureIconSizeUpdated {
    my $p;

    if $.updateIconSizesLaterId === 0 {
      my $p = Promise.new;
      $p.keep;

      return $p;
    }

    # XXX -
    # cw: Not sure how to transcribe this!
    #return new Promise(
    #       resolve => this._iconSizeUpdateResolveCbs.push(resolve));
  }

  method adaptToSize ($pageWidth, $pageHeight) {
    return if ($!pageWidth, $!pageHeight) eqv ($pageWidth, $pageHeight);

    ($!pageWidth, $!pageHeight) = ($pageWidth, $pageHeight);
     $!pageSizeChanged          = True;

    if $!updateIconSizesLaterId === 0 {
      my $s = self;
      $!updateIconSizesLaterId = Global.compositor.get-laters.add(
        META_LATER_BEFORE_REDRAW,
        -> *@a {
          my $is = $.findBestIconSize();

          unless $!icon-size == $is {
            $!icon-size = $is;

            .icon.setIconSize($is) for $!container;

            $s.notify('icon-size');

            $s.updateIconSizesLaterId = 0;
          }
        }
      )
    }
  }

  method getDropTarget ($x, $y) {
    my $childSize = $.getChildrenMaxSize;

    my %s;
    %s<l t h v> = $.calculateSpacing($childSize);

    my $is-v = $!orientation === CLUTTER_ORIENTATION_VERTICAL
    my $page = $is-v
      ?? ($y / $!page-height).floor
      !! ($x / $!page-width).floor;

    return [0, 0, DRAG_LOCATION_INVALID] if $page >= $pages.elems;

    $page = @!pages.elems if $.is-rtl && $is-v.not;

    my ($adjX, $adjY) = ($x, $y);
    $is-v.not ?? $adjX %= $!page-width !! $adjY %= $!page-height;

    my $gridW = $childSize * $.columns-per-page +
                %s<h> * $.columns-per-page.pred;
    my $gridH = $childSize * $.rows-per-page +
                %s<v> * $.rows-per-page.pred;

    my %in = (
      t => $adjY < %s<t>, b => $adjY > $s<t> + $gridH
      l => $adjX < %s<l>, r => $adjX > %s<l> + $gridW,
    );
    return [0, 0, DRAG_LOCATION_INVALID] if %in<t> || %in<b>;

    my ($halfH, $halfV, $vi) =
      ( %s<h> / 2, %s<v> / 2, @!pages[$page].visibleChildren );

    for $vi.elems.kv -> $i, $item {
      my $childBox = $iutem.allocation;

      my $first = ( $i % $.columns-per-page ).not
      my $last  =   $i % $.columns-per-page  === $.columns-per-page.pred;

      if (%in<l> && $first) || (%in<r> && last) {
        next if $y < ($childBox.y1 - $halfV) | |
                $y > ($childBox.y2 + $halfV);
      else {
        next if $x < ($childBox.x1 - $halfH) ||
                $x > ($childBox.x2 + $halfH);
      }

      my $dragLocation = do if $x < $childBox.x1 + LEFT_DIVIDER_LEEWAY {
        DRAG_LOCATION_START_EDGE;
      } elsif $x > $childBox.x2 - RIGHT_DIVIDER_LEEWAY {
        DRAG_LOCATION_END_EDGE
      } else {
        DRAG_LOGATION_ON_ICON
      }

      if $.is-rtl {
        if $dragLocation === DRAG_LOCATION_START_EDGE {
          $dragLocation = DRAG_LOCATION_END_EDGE
        } elsif $dragLocation === DRAG_LOCATION_END_EDGE {
          $dragLocation = DRAG_LOCATION_START_EDGE;
        }
      }

      return ($page, $i, $dragLocation);
    }

    return ($page, Nil, DRAG_LOCATION_EMPTY_SPACE);
  }

}

class Gnome::Shell::UI::IconGrid is Gnome::Shell::St::Layout {
  has $.layout-manager;
  has $.pagesChangedId;
  has $.currentMode;

  has $.gridModes   = defaultGridModes;
  has $!currentPage = 0;

  method layout_manager is also<layoutManager> { $!layout-manager }

  method items-per-page
    is also<
      items_per_page
      itemsPerPage
    >
  { $!layout-manager.items-per-page }

  method currentPage is rw {
    Proxy.new:
      FETCH => $     { $!currentPage },
      STORE => $, \v { $.goToPage(v) }
  }

  method current-page is rw is also<current_page> { $.currentPage }

  method nPages
    is also<
      elems
      n-pages
      n_pages
    >
  { $!layout-manager.nPages }

  submethod TWEAK (
    :layout-params(:layout-params(:$l))
  ) {
    self.layout-manager = Gnome::Shell::UI::IconGrid::Layout.new(
      orientation      => $l<orientation>      // CLUTTER_ORIENTATION_HORIZONTAL,
      columns-per-page => $l<columns-per-page> // 6,
      rows-per-page    => $l<rows-per-page>    // 4,
      page-halign      => $l<page-halign>      // CLUTTER_ACTOR_ALIGN_FILL,
      page-padding     => Mutter::Clutter::Margin.new,
      page-valign      => $l<page-valign>      // CLUTTER_ACTOR_ALIGN_FILL,
      last-row-align   => $l<last-row-align>   // CLUTTER_ACTOR_ALIGN_START,
      column-spacing   => $l<column-spacing>   // 0,
      row-spacing      => $l<row-spacing>      // 0
    );

    my $s = self;
    # XXX -
    # cw: We need to finalize the move to supplyish and it should return the
    #     signal id, so we don't have to expend an instruction through
    #     signals-manager to get it.
    self.layout-manager.pages-changed.tap( -> *@a {
      $s.emit('pages-changed');
    });
    my $pagesChangedId =
      self.layout-manager.signals-manager<pages-changed>.tail;

    self.actor-added.tap( -> *@a {
      $s.childAdded( |@a[1] );
    }
    self.actor-removed.tap( -> *@a {
      $s.childRemoved( @a[1] );
    }
    self.destroy.tap( -> *@a {
      $!layout-manager.disconnect($pagesChangedId);
    });
  }

  method pages-changed is g-signal { }

  method childAdded ($child) {
    my $s = self;
    $child.key-focus-in.tap( -> *@a {
      $s.ensureItemIsVisible($child);
    });
    $child.iconGridKeyFocusInId = $child.signals-manager<key-focus-in>.tail;
  }

  method ensureItemIsVisible ($item) {
    X::Gnome::Shell::BadItem.new("{ $item } is not a child of IconGrid").throw
      unless self.has($item);

    $.goToPage( $!layout-manager.getItemPage($item) );
  }

  method setGridMode ($modeIndex) {
    return if $!currentMode === $modeIndex;

    $!currentMode = $modeIndex;
    with $modeIndex {
      my $nm = $gridModes[$modeIndex];
      ( .rows-per-page, .colums-per-page ) = ( $nm.rows, $nm.columns )
        given $!layout-manager;
    }
  }

  method findBestModeForSize ($width is copy, $height is copy) {
    my $pp = $!layout-manager.pagePadding;

    $width  -= .left + .right  given $pp;
    $height -= .top  + .bottom given $pp;

    my $sr = $width / $height;
    my ($cr, $bm);

    for $!gridModes {
      my $mr = .columns / .rows;

      ($cr, $bm) = ($mr, $_) if ($sr - $mr).abs < ($sr - $cr).abs;
    }

    $.setGridMode($bm);
  }

  method childRemoved ($child) {
    $child.disconnect($child.iconGridKeyFocusInId);
  }

  method allocate ($box) is vfunc {
    my ($w, $h) = $box.size;

    $.findBestModeForSize($w, $h);
    $!layout-manager.adapToSize($w, $h);
    nextsame;
  }

  method style-changed is vfunc {
    callsame;

    my $node = self.theme-node;
    $!layout-manager.column-spacing = $node.get-length('column-spacing');
    $!layout-manager.row-spacing    = $node.get-length('row-spacing');

    $!layout-manager.max-column-spacing =
      $node.lookup-length('max-column-spacing');
    $!layout-manager.max-row-spacing =
      $node.lookup-length('max-row-spacing');

    my $padding = Mutter::Clutter::Margin.new;
    $padding."$_"() = $node.get-length("page-padding-{$_}")
      for <top right bottom left>;
    $!layout-manager.page-padding = $padding;
  }

  method addItem ($item, $page = Nil, $index = Nil) {
    X::Gnome::Shell::BadItem.new(
      'Only items with a BaseIcon property can be added to IconGrid'
    ).throw unless $item ~~ Gnome::Shell::UI::IconGrid::BaseIcon;

    $!layout-manager.addItem($item, $page, $index);
  }

  method appendItem ($item) {
    $!layout-manager.appendItem($item);
  }

  method moveItem ($item, $newPage, $newPosition) {
    $!layout-manager.moveItem($item, $newPage, $newPosition);
    $.queie-relayout;
  }

  method removeItem ($item) {
    X::Gnome::Shell::BadItem.new(
      "Item { $item } is not a part of IconGrid"
    ).throw unless self.contains($item);

    $!layout-manager.remove($item);
  }

  method goToPage ($pageIndex, $animate = True) {
    X::Gnome::Shell::BadPage.new(
      "IconGrid does not have page { $pageIndex }"
    ).throw unless $pageIndex < $.nPages;

    my ($nv, $adj) = do given $!layout-manager.orientation {
      when CLUTTER_ORIENTATION_VERTICAL {
        ($pageIndex * $!layout-manager.pageHeight, $.vadjustment )
      }
      when CLUTTER_ORIENTATION_HORIZONTAL
        ($pageIndex * $!layout-manager.pageWidth, $.hadjustment )
      }
    }

    $!currentPage = $pageIndex;

    $animate = False unless $.mapped;

    Global.compositor.get-laters().add(
      META_LATER_BEFORE_REDRAW,
      -> *@a {
        $adj.ease(
          $nv,
          mode     => CLUTTER_EASE_OUT_CUBIC,
          duration => $animate ?? PAGE_SWITCH_TIME !! 0
        );
        G_SOURCE_REMOVE
      }
    );
  }

  method getItemPage ($item) {
    $!layout-manager.getItemPage($item);
  }

  method getItemPosition ($item) {
    return (Nil, Nil) unless $.contains($item);

    $!layout-manager.getItemPosition($item);
  }

  method getItemAt ($page, $position) {
    $!layout-manager.getItemAt($page, $position);
  }

  method getItemsAtPage ($page) {
    X::Gnome::Shell::BadPage.new(
      "Page {$page} does not exist at IconGrid"
    ).throw unless $page ~~ 0 ..^ $!nPages

    $!layoutManager.getItemsAt($page);
  }

  method setGridModes ($modes) {
    $!gridModes = $modes ?? $modes !! defaultGridModes;
    self.queue-relayout;
  }

  method getDropTarget ($x, $y) {
    $!layout-manager.getDropTarget($x, $y, $!currentPage);
  }

}
