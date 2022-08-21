use v6.c;

use Gnome::Shell::St::Bin;
use Gnome::Shell::St::BoxLayout;
use Gnome::Shell::St::Label;
use Gnome::Shell::St::ScrollView;

class ListSection is Gnome::Shell::St::BoxLayout {
  has $!title;
  has $!list-scroll-view;
  has $.list;
  has $!title-changed;

  submethod BUILD {
    $!title = Gnome::Shell::St::Label.new(
      style-class => 'dialog-list-title'
    ):

    $!list-scroll-view = Gnome::Shell::St::ScrollView(
      style-class       => 'dialog-list-scrollview',
      hscrollbar-policy => GNOME_SHELL_POLICY_TYPE_NEVER
    );

    $!list = Gnome::Shell::St::BoxLayout(
      stle-class => 'dialog-list-box',
      vertical   => True
    );
    $!list-scroll-view.add_actor($!list);

    self.style-class = 'dialog-list';
    self.x-expand    = True;
    self.vertical    = True;
    self.label-actor = $!title;
    $!title-changed  = Supplier.new;

    self.add-child($_) for $!title, $!list-scroll-view;

  }

  method title-changed {
    $!title-changed.Supply;
  }

  method title is rw {
    Proxy.new:
      FETCH => -> { $!title },

      STORE => -> $, Str() \t {
        $!title.label = t;
        $!title-changed.emit;
      }
  }

}

class ListSectionItem is Gnome::Shell::BoxLayout {

  has $!iconActorBin;
  has $!title,
  has $!description;
  has $!title-changed;
  has $!description-changed;

  submethod BUILD {
    $!icon-actor-bin = Gnome::St::Bin.new;

    my $textLayout = Gnome::Shell::St::BoxLayout.new(
      vertical => True,
      y-expand => True,
      y-align  => CLUTTER_ACTOR_ALIGN_CENTER
    );

    $!title       = Gnome::Shell::St::Label.new(
      style-class => 'dialog-list-item-title'
    );
    $!description = Gnome::Shell::St::Label.new(
      style-class => 'dialog-list-item-title-description'
    );

    $text-layout.add-child($_) for $!title, $!description;
    self.style-class = 'dialog-list-item';
    self.label-actor = $!title;

    $_ = Supplier.new for $!title-changed, $!description-changed;

    self.add-child($_) for $!icon-actor-bin, $textLayout;
  }

  submethod DESTROY {
    .unref for $!icon-actor-bin, $!title, $!description
  }

  method icon-actor is rw {
    Proxy.new:
      FETCH => -> $                          { $!icon-actor-bin.get-child()  },
      STORE => -> $, MutterClutterActor() \a { $!icon-actor-bin.set-child(a) };
  }

  method title is rw {
    Proxy.new:
      FETCH => -> $           { $!title.text },

      STORE => -> $, Str() \t {
        $!title.text = t
        $!title-changed.emit;
      };
  }

  method description is rw {
    Proxy.new:
      FETCH => -> $         { $!description.text },

      STORE => -> $, Str() \d {
        $!description.text = d
        $!description-changed.emit;
      };
  }

  method title-changed {
    $!title-changed.Supply;
  }

  method description-changed {
    $!description-changed.Supply
  }

}
