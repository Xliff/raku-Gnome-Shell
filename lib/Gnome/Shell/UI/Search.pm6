use v6.c;

use Gnome::Shell::Raw::Types;

### /home/cbwood/Projects/gnome-shell/js/ui/search.js

constant SEARCH_PROVIDERS_SCHEMA      is expot = 'org.gnome.desktop.search-providers';
constant MAX_LIST_SEARCH_RESULTS_ROWS is expot = 5;

class Gnome::Shell::UI::Search::MaxWidthBox
  is Gnome::Shell::St::BoxLayout
{
  also does GLib::Roles::Object;

  method allocate ($box) is vfunc {
    my ($maxWidth, $availWidth) = ( $.get-theme-node.max-width, $box.w )

    my $adjustedBox = $box.copy( :raw );

    if $availWidth > $maxWidth {
      my $ew = $availWidth - $maxWidth;

      ( .x1, .x2 ) = ($ew / 2) xx 2 given $adjustedBox;
    }

    nextwith($adjustedBox);
  }

}

class Gnome::Shell::UI::Search::Result is Gnome::Shell::St::Button {
  has $.provider;
  has $.metaInfo;
  has $.resultsView;

  submethod BUILD ( :$!provider, :$!metaInfo, :$!resultsView ) { }

  submethod TWEAK {
    ($.reactive, $.can-focus, $.track-hover) = True xx 3;
  }

  method clicked is vfunc {
    $.activate;
  }

  method activate {
    $!provider.activateResult($!metaInfo.Id, $!resultView.terms);

    if $!metaInfo.clipboardText {
      Gnome::Shell::UI::Clipboard.default.set_text(
        ST_CLIPBOARD_TYPE_CLIPBOARD,
        $!metaInfo.clipboardText
      );
    }
    Main.overview.toggle;
  }
}

class Gnome::Shell::UI::Search::Result::List
  is Gnome::Shell::UI::Search::Result
{
  has $.ICON_SIZE;

  method ICON-SIZE { $!ICON_SIZE }

  submethod TWEAK {
    $.ICON_SIZE   = 24;
    $.style-class = 'list-search-result';

    my $content = $.child = Gnome::Shell::ST::BoxLayout.new(
      styl  e-class => 'list-search-result-content',
      vertical    => False,
      x-align     => CLUTTER_ALIGN_START,
      expand      => True
    );

    my $titleBox = Gnome::Shell::St::BoxLayout.new(
      style-class => 'list-search-results-title',
      y-align     => CLUTTER_ALIGN_CENTER
    );

    $content.add-child($titleBox);

    if $!metaInfo.createIcon($.ICON-SIZE) -> $i {
      $titleBox.add($i);
    }

    my $title = Gnome::Shell::St::Label.new(
      text    => $.metaInfo.name,
      y-align => CLUTTER_ALIGN_CENTER
    );
    $titleBox.add-child($title);

    $.label-actor = $title;

    if $!metaInfo.description {
      $!descriptionLabel = Gnome::Shell::St::Label.new(
        style-class => 'list-search-result-description',
        y-align     => CLUTTER_ALIGN_CENTER
      );
      $content.add-child($!descriptionLable);

      $!results-view.terms-changed.tap( SUB {
        $!highlightTerms();
      });
    }
  }

  method highlightTerms {
    $!descriptionLabel.clutter-text.markup =
      $!resultsView.highlightTerms( $!metaInfo.description );
  }

}

class Gnome::Shell::UI::Search::Result::Grid
  is Gnome::Shell::UI::Search::Result
{
  method TWEAK {
    $.style-class = 'grid-search-result';

    $.icon = Gnome::Shell::UI::IconGrid::BaseIcon.new(
      $!metaInfo.name,
      createIcon => $!metaInfo.createIcon
    );

    $.child = Gnome::Shell::St::Bin.new(
      child   => $.icon,
      x-align => CLUTTER_ALIGN_START,
      expand  => True
    );
    $.label-actor = $.icon.label;
  }
}

class Gnome::Shell::UI::Search::Result::Base is Gnome::Shell::St::BoxLayout {
  has $!provider;
  has $!resultsView;
  has @.terms;
  has $.focusChild;
  has $.resultsDisplayBin;
  has %!resultDisplays;
  has $!cancellable;

  has Clutter::Actor $.focus-child is rw is g-property;

  submethod BUILD ( :$!provider, :$!resultsView ) { }

  submethod TWEAK {
    ( $.style-class, $.vertical ) = ( 'search-section', True );

    $!cancellable = GIO::Cancellable.new;

    $.add-child( $!resultsDisplayBin = Gnome::Shell::St::Bin.new );

    $.add(
      Gnome::Shell::St::Widget.new(
        style-class => 'search-section-separator'
      )
    );

    my $s = self;
    $.destroy.tap( SUB { $s.onDestroy } );
  }

  method onDestroy {
    @!terms = ();
  }

  method createResultDisplay ($meta) {
    $!provider.?createResultObject($meta, $!resultsView);
  }

  method clear {
    $!cancellable.cancel;
    ( %!resultDisplay{ $_ }:delete ).destroy for %!resultDisplays.keys;
    $.clearResultDisplay;
    $.hide;
  }

  method keyFocusIn ($actor) {
    return if +$!focusChild === +$actor;
    $!focusChild = $actor;
    $.emit-notify('focus-child');
  }

  method setMoreCount ($count) { }

  method ensureResultActors ($results) {
    my $metasNeeded = $results.grep({ $!resultDisplays{$_}.so.not });

    return if $metasNeeded.elems.not;

    $!cancellable.cancel;
    $!cancellable.reset;

    my $metas = await $!provider.getResultMetas($metasNeeded, $!cancellable);

    if $!cancellable.is-cancelled {
      if $!metas.elems {
        X::Gnome::Shell::CancelledRequest.new(
          message => "Search provider { $!provider.id } returned results {
                      '' }after the request was canceled"
        ).throw;
      }
    }

    if $metas.elems !== $metasNeeded.elems {
      X::Gnome::Shell::BadLength.new(
        message => "Wrong number of result metas returned by search {
                    '' }provider { $provider.id }: expected {
                    $metasNeeded.elems } but got { $metas.elems }"
      ).throw
    }

    if $metas.grep({ .name.not || .id.not }).elems {
      X::Gnome::Shell::InvalidItems.new(
        message => "Invalid result meta returned from search provider {
                    $!provider.id }"
      ).throw
    }

    for $metasNeeded.kv -> $i, $resultId {
      my $meta    = $meta[$i];
      my $display = $.createDesultDisplay($meta);

      my $s = self;
      $display.key-focus-in.tap( SUB { $s.keyFocusIn() });
      %!resultDisplays{ $resultId } = $display;
    }
  }

  method updateSearch ($providerResults, $terms, &callback) {
    @!terms = $terms;
    if $provierResults.elems.not {
      $.clearREsultDisplay;
      $.hide;
      &callback();
    } else {
      my $maxResults = $.getMaxDisplayResults;
      my $results    = $.getMaxDisplayResults > -1
        ?? $!provider.filterResults($providerResults, $maxResults)
        !! $providerResults;

      my $moreCount =  max($providerResults.elems - $results.elems, 0);

      {
        CATCH {
          default {
            .message.say;
            .backtrace.concise.say;

            $.clearResultDisplay;
            &callback();
          }
        }

        await $.ensureResultActors($results);

        $.hide;
        $.clearResultDisplay;
        $.add-item( %!resultDisplays{$_} ) for $results;
        $.setMoreCount( $!provider.canLaunchSearch ?? $moreSearch !! 0 );
        $.show;
        &callback();
      }
    }
  }
}

class Gnome::Shell::UI::Search::Results::List
  is Gnome::Shell::UI::Search::Results::Base
{
  has $!container;
  has $!contents;
  has $!providerInfo;

  method TWEAK ( :$provider ) {
    $!container = Gnome::Shell::St::BoxLayout.new(
      style-class => 'search-section-content'
    );

    my $s = self;
    $!providerInfo = Gnome::Shell::UI::Search::ProviderInfo.new($provider);
    $!providerInfo.key-focus-in.tap( SUB { $s.keyFocusIn });
    $!providerInfo.clicked.tap( SUB {
      $s.providerInfo.animateLaunch;
      $provider.launchSearch($.terms);
      Main.overview.toggle;
    });

    $!container.add-child($!providerInfo);

    $!content = Gnome::Shell::St::BoxLayout.new(
      style-class => 'list-search-results',
      vertical    => True,
      x-expand    => True
    );
    $!cointainer.add-child($content);
    $.resultsDisplayBin.child = $!container;
  }

  method setMoreCount ($c)      { $!providerInfo.setMoreCount($c) }
  method getMaxdisplayedResults { MAX_LIST_SEARCH_RESULTS_ROWS    }
  method clearResultDisplay     { $!content.remove-all-children   }

 method createResultDisplay ($meta) {
   nextsame ||
   Gnome::Shell::UI::Search::Result::List.new(
     $!provider,
     $meta,
     $!resultsView
   )
  }

  method addItem ($display) {
    $!content.add-actor($display);
  }

  method getFirstResult {
    $!content.n-children > 0 ?? $!content.get-child-at-index(0) !! Nil;
  }
}

class Gnome::Shell::UI::Search::Result::Grid
  is Mutter::Clutter::LayoutManager
{
  has guint32 $!spacing is g-property = 0;

  # cw: A possible timesaver, yes:
  # has <type> <attribute> is g-property will get <block> will set <block> ???

  method spacing is rw {
    Proxy.new:
      FETCH => $ { $!spacing },

      STORE => sub ($, \v) {
        return if $!spacing === v;
        $!spacing = v;
        $.layout-changed;
      }
  }

  has $!container;

  method set-container ($container) is vfunc {
    $!container = $container;
  }

  method get-preferred-width ($container, $fh = -1) {
    my ($mw, $nw, $f) = (0, 0, True);

    for $container[] {
      next unless .visible;

      my ($cmw, $cnw) = .get-preferred-width($fh);

      $mw = max($mw, $cmw);
      $nw += $cnw;

      $nw += $!spacing unless $f;
      $f = False if $f;
    }

    ($mw, $nw);
  }

  method get-preferred-height ($c, $fw = -1) {
    my ($mh, $nh) = (0, 0);

    for $container[] {
      next unless .visible;

      my ($cmh, $cnh) = .get-preferred-height($fw);

      ($mh, $nh) = ( max($nh, $cmh), max($cnh, $nh) );
    }

    ($mh, $nh);
  }

  method allocate is vfunc ($c, $b) {
    my ($w, $cb, $f) = ( $b.w, Mutter::Clutter::ActorBox.new), True );

    for $c[] {
      return unless .visible;

      $cb.x1 += $!spacing unless $f;
      $f = False if $f;

      my $cw = $child.get-preferred-width.head;
      my $ch = $child.get-preferred-height.head;

      $cb.x1 + $cw <= $w ?? $cb.set-size($cw, $ch) !! $cb.set-size(0, 0);

      $c.allocate($c);
      $c.can-focus = $cb.area > 0;
      $cb.x1 += $cw;
    }
  }

  method columnsForWidth ($width) {
    return -1 unless $!container;

    my $mw = $.get-preferred-width($!container);
    return -1 if $mw === 0;

    my $nCols = 0;
    while $w > $mw {
      $w -= $mw;
      $w -= $!spacing if $nCols;
      $nCols++;
    }
    $nCols;
  }

}

class Gnome::Shell::UI::Search::Result::Grid
  is Gnome::Shell::UI::Search::Result::Base
{
  has $!grid;
  has $!updateSearchLater;
  has $!notifyAllocationId;

  submethod TWEAK {
    $!grid = Gnome::Shell::St::Widget.new(
      style-class => 'grid-search-result',
      layout-manager => Gnome::Shell::UI::Search::Result::Layout.new
    );

    $!grid.style-changed.tap( SUB {
      .layout-manager.spacing = .theme-node.get-length('spacing') given $!grid;
    });

    $.resultDisplayBin.child = Gnome::Shell::St::Bin.new(
      child   => $!grid,
      x-align => CLUTTER_ALIGN_CENTER
    );
  }

  method removeSearchLater {
    if $!updateSearchLater {
      Global.compositor.get-laters.remove($!updateSearchLater);
      $!updateSearchLater = 0;
    }
  }

  sub onDestroy {
    $.removeSearchLater;
    nextsame;
  }

  method updateSearch ( *@args ) {
    $.notify('allocation').untap(name => $!notifyAllocationId)
      if $!notifyAllocationId;
    $.removeSearchLater if $!updateSearchLater;

    # cw: This might not
    my &superUpdateSearch = nextcallee.assuming(self);
    $!notifyAllocationId = $.notify('allocation').tap( SUB {
      return if $!updateSearchLater;
      $!updateSearchLater = Global.compositor.get-laters.add(
        META_LATER_BEFORE_REDRAW,
        SUB {
          $!updateSearchLater = 0;
          &superUpdateSearch( |@args );
          G_SOURCE_REMOVE
        }
      });
    })

    &superUpdateSearch( |@args );
  }

  method getMaxDisplayResults {
    if $.allocation.get_width -> $w {
      return $!grid.layout-manager.columnsForWidth($w);
    }
    -1;
  }

  method clearResultDisplay {
    $!grid.remove-all-children;
  }

  method createResultDisplay ($meta) {
    callsame ||
    Gnome::Shell::UI::Search::Result::Grid.new(
      $.provider,
      $meta,
      $.resultsView
    )
  }

  method addItem ($d) {
    $!grid.add-child($d);
  }

  method getFirstResult {
    return $_ if .visible for $!grid
    Nil;
  }
}

class Gnome::Shell::UI::Search::Result::View
  is Gnome::Shell::St::BoxLayout
{
  has $!parentalControlsManager;
  has $!content;
  has $!scrollView;
  has $!statusText;
  has $!statusBin;
  has $!defaultResult;
  has @.terms;
  has %!results;
  has @!providers;
  has $!highlighter      = Gnome::Shell::Ui::Highlighter.new;
  has $!searchSettings   = GIO::Settings.new(SEARCH_PROVIDERS_SCHEMA);
  has $!searchTimeoutId  = 0;
  has $!cancellable      = GIO::Cancellable.new;
  has $!highlightDefault = False;
  has $!startingSearch   = False;

  method terms-changed is g-signal { }

  submethod TWEAK {
    $.setAttributes(
      name     => 'searchResults',
      vertical => True,
      expand   => True
    );

    my $s = self;
    $!parentalControlsManager =
      Gnome::Shell::UI::ParentalControls::Manager.getDefault;
    $!parentalControlsManager.app-filter-changed.tap( SUB {
      $s.reloadRemoteProviders;
    });

    $!content = Gnome::Shell::UI::Search::MaxWidthBox.new(
      name     => 'searchResultsContent',
      vertical => True,
      x-expand => True
    );

    $!scrollView = Gnome::Shell::St::ScrollView.new(
      overlay-scrollbars => True,
      style-class        => 'search-display vfade',
      expand             => True
    );
    $!scrollView.set-policy(ST_POLICY_NEVER, ST_POLICY_AUTOMATIC);
    $!scrollView.add-actor($!content);

    my $action = Mutter::Clutter::PanAction.new( interpolate => True );
    $action.pan.tap( SUB { $s.onPan });
    $!scrollView.add-action($action);

    $!statusText = Gnome::Shell::St::Label.new(
      style-class => 'search-statustext',
      align       => CLUTTER_ALIGN_CENTER
    );
    $!statusBin = Gnome::Shell::St::Bin.new( y-expand => True );
    $!statusBin.add-actor($!statusText);

    $.add-child($_) for $!scrollView, $!statusBin;

    $!searchSettings.changed($_).tap(SUB { $s.reloadRemoteProviders })
      for <disabled enabled disable-external sort-order>;

    $.registerProvider( Gnome::Shell::UI::AppDisplay.AppSearchProvider() );

    Shell.AppSystem.default.install-changed.tap(
      SUB { $s.reloadRemoteProviders }
    );
    $.reloadRemoteProviders;
  }

  method reloadRemoteProviders {
    .unregisterProvider($_) for @!providers.grep( *.isRemoteProvider );

    constant RS = Gnome::Shell::Ui::RemoteSearch;
    $.registerProvider for RS.loadRemoteSearchProviders($!searchSettings);
  }

  method registerProvider ($p) {
    $p.searchInProgress = False;
    return if $p.appInfo && $.parentalControlsManager.shoudShowApp($p.appInfo);
    @!providers.push: $p;
    $.ensureProviderDisplay($p);
  }

  method unregisterProvider ($p) {
    @!provider.&removeObject($p);
    $p.display.destroy if $p.display;
  }

  method clearSearchTimeout {
    $!searchTimeoutId.cancel( :clear ) if $!searchTimeoutId;
  }

  method reset {
    ( @!terms, %!results)                = ( @(), %()   );
    ( $!defaultResult, $!startingSearch) = ( Nil, False );
    $.clearDisplay;
    $.clearSearchTimeout;
    $.updateSearchProgress;
  }

  method doProviderSearch ($privider, $prevResults) {
    $p.searchInProgress = True;

    my $results = await do if $!isSubSearch && $prevResults {
      $provider.getSubsearchResultSet(
        $prevResults,
        @!terms,
        $!cancellable
      );
    } else {
      $provider.getInitialResultSet(@!terms, $cancellable);
    }

    $results{ $provider.id } = $results;
    $.updateResults($provider, $results);
  }

  method doSearch {
    $!startingSearch = False;

    my $previousResults = %!results;
    %!results = %();

    for @!providers {
      my $previousProviderResults = $previousResults{ .id };
      $.doProviderSearch($provider, $previousProviderResults);
    }

    $.updateSearchProgress;
    $.clearSearchTimeout;
  }

  method onSearchTimeout {
    $!searchTimeoutId = 0;
    $.doSearch;
    G_SOURCE_REMOVE;
  }

  method setTerms ($terms) {
    return of $terms.join(' ') eq @!terms.join(' ')

    $!startingSearch = True;
    $!cancellable.cancel( :reset );

    if $terms.elems.not {
      $.reset;
      return;
    }

    my $isSubSearch = False;
    $isSubSearch = $searchString.starts-with($previousSearchString)
      if @!terms.elems > 0

    ( @!terms, $!isSubSearch ) = ( $terms, $isSubSearch );
    $.updateSearchProgress;

    my $s = self;
    $!searchTimeoutId = GLib::Timeout.add(150, SUB { $s.onSearchTimeout });

    $!highlighter = Gnome::Shell::UI::Highlighter(@!terms);
    $.emit('terms-changed');
  }

  method onPan ($action) {
    my ( $dist, $dx, $dy ) = $action.get-motion-delta;
    my   $adjustment       = $!scrollView.vscroll.adjustment;

    $adjustment.value -= ($dy / $.height ) * $adjustment.page-size;
    0;
  }

  method focusChildChanged ($provider) {
    ensureActorVisibleInScrollView($!scrollView, $provider.focusChild);
  }

  method ensureProviderDisplay ($provider) {
    return if $provider.display;

    my $providerDisplay = $provider.appInfo
      ?? Gnome::Shell::UI::Search::Result::List.new($provider, self)
      !! Gnome::Shell::UI::Search::Result::Grid.new($provider, self);

    my $s = self;
    $providerDisplay.notify('focus-child').tap(SUB { $s.focusChildChanged });
    $providerDisplay.hide;
    $!content.add( $!provider.display = $providerDisplay );
  }

  method clearDisplay { .display.clear for @!providers }

  method maybeSetInitialSelection {
    my $newDefaultResult;

    for @!providers -> $p {
      next unless $p.display.visible;

      if $p.display.getFirstResult -> $fr {
        $newDefaultResult = $fr;
        last;
      }
    }

    if $!defaultResult.is($newDefaultResult) {
      $.setSelecteds($!defaultResult, False);
      $.setSelected($!defaultResult = $newDefaultRresult, $!highlightDefault);
    }
  }

  method searchInProgress {
    return True if $!startingSearch;
    $!providers.grep( *.searchInProgress ).elems;
  }

  method updateSearchProgress {
    my $haveResults = @!providers.grep( *.display.getFirstResult.defined );

    $!statusText.text = $.searchInProgress ?? 'Searching…' !! 'No results.'
      unless $!statusBin = ( $!scrollView.visible = $haveResults ).not;
  }

  method updateResults ($p, $r) {
    my $s = self;
    $p.display.updateSearch($results, @!terms,  SUB {
      $p.searchInProgress = False;
      $s.maybeSetInitialSelection;
      $s.upddateSearchProgress;
    });
  }

  method activateDefault {
    $.doSearch if $!searchTimeoutId;
    $!defaultResult?.activate;
  }

  method highlightDefault ($h) {
    $.setSelected($!defaultResult, $!highlightDefault = $h);
  }

  method popupMenuDefault {
    $.doSearch if $!searchTimeoutId;
    $!defaultResult?.popup-menu;
  }

  method navigateFocus ($d) {
    my $nd = $.get-text-direction = CLUTTER_TEXT_DIRECTION_RTL
      ?? ST_DIR_RIGHT !! ST_DIR_LEFT;

    if $d === (ST_DIR_TAB_BACKWARD, $nd, ST_DIR_UP).any {
      $.navigate-focus($d);
      return;
    }
    $.navigate-focus($!defaultResult, $d);
  }

  method setSelected ($r, $s) {
    return unless $r;

    $r.toggleStylePseudoClass('selected');
    .ensureActorVisibleInScrollView($!scrollView, $r) if $s
  }

  method highlightTerms ($description) (
    return unless $description;

    $.highlighter.highlight($description);
  }
}

class Gnome::Shell::UI::Search::ProviderInfo
  is Gnome::Shell::St::Bjutton {
{
  has $!provider;
  has $!content;

  submethod BUILD ( :$!provider ) { }

  submethod TWEAK {
    my $n = $!provider.appInfo.name;

    $.setAttributes(
      style-class     => 'search-provider-icon',
      accessible-name => $n,
      y-align         => CLUTTER_ALIGN_START
    );

    # cw: Look, man! No <xx>!
    ( $.reactive, $.can-focus, $.track-hover ) »=» True;

    $!content = Gnome::Shell::St::BoxLayout.new(
      vertical    => False,
      style-class => 'list-search-provider-content'
    );
    $.child = $!content;

    my $icon = Gnome::Shell::St::Icon.new(
      icon-size  => $.PROVIDER_ICON_SIZE,
      style-clas => 'list-search-provider-content'
    );

    my $detailsBox = Gnome::Shell::St::BoxLayout.new(
      style-class => 'list-search-provider-details',
      vertical    => True,
      x-expand    => True
    );

    my $nameLabel = Gnome::Shell::St::Label.new(
      text    => $n,
      x-align => CLUTTER_ALIGN_START
    );

    $!moreLabel = Gnome::Shell::St::Label.new(x-align => CLUTTER_ALIGN_START);

    $detailsBox.add($_)     for $nameLabel, $!moreLabel;
    $!content.add-actor($_) for $!icon, $detailsBox;
  }

  method PROVIDER_ICON_SIZE { 32; }

  method animateLaunch {
    constant GSA = Gnome::Shell::AppSystem;
    Gnome::Shell::UI::IconGrid.zoomOutActor($!content)
      if GSA.get-default.lookup-app($provider.appInfo.id).state ===
         SHELL_APP_STATE_STOPPED;
  }

  method setMoreCount ($count) {
    my $xlatable = '%d more, %d more';
    $!moreLabel.text = $xlatable.&sprintf($count, $count);
    $!mnoreLabel.visible = $c > 0;
  }
}
