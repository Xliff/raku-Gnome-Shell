use v6.c;

use Mutter::Raw::Clutter::Keysyms;
use Gnome::Shell::Raw::Types;

use Gnome::Shell::St::Bin;
use Gnome::Shell::St::BoxLayout;
use Gnome::Shell::St::Label;
use Gnome::Shell::St::ScrollView;

use GLib::Roles::Object;

### /home/cbwood/Projects/gnome-shell/js/ui/dialog.js

class Gnome::Shell::Dialog is Gnome::Shell::St::Widget {
  has $!dialog              is built;
  has $!initialKeyFocus     is built;
  has $!setInitialKeyFocus  is built;
  has $!pressedKey          is built;
  has %!buttonKeys          is built;
  has $!parentActor         is built;
  has $!buttonLayout        is built;
  has $!contentLayout       is built;

  method buttonLayout is rw {
    Proxy.new:
      FETCH => -> $     { $!buttonLayout },
      STORE => -> $, \v { $!buttonLayout := v };
  }

  method contentLayout is rw {
    Proxy.new:
      FETCH => -> $     { $!buttonLayout },
      STORE => -> $, \v { $!contentLayout := v };
  }

  submethod BUILD ( :$!parentActor, :$styleClass ) {
    self.layout-manager = Mutter::Clutter::BinLayout.new;
    self.reactive       = True;

    self.destroy.tap( -> *@a { self.onDestroy });
    self.createDialog;
    self.add-child($!dialog);

    self.add-style-class-name($styleClass) with $styleClass;

    $!parentActor.add-child(self);
  }

  method createDialog {
    $!dialog = Gnome::Shell::St::BoxLayout.new(
      style-class => 'modal-dialog',
      x-align     => CLUTTER_ACTOR_ALIGN_CENTER,
      y-align     => CLUTTER_ACTOR_ALIGN_CENTER,
      vertical    => True
    );

    $!dialog.request-mode = CLUTTER_REQUEST_HEIGHT_FOR_WIDTH;
    $!dialog.set-offscreen-redirect(CLUTTER_OFFSCREEN_REDIRECT_ALWAYS);

    $!contentLayout = Gnome::Shell::St::BoxLayout.new(
      vertical    => True,
      style-class => 'model-dialog-content-box',
      y-expand    => True
    );
    $!dialog.add-child(self.contentLayout);

    $!buttonLayout = Gnome::Shell::St::Widget.new(
      layout-manager => Mutter::Clutter::BoxLayout.new( homogenous => True )
    );
    $!dialog.add-child(self.buttonLayout);
  }

  method makeInactive {
    $!parentActor.disconnectObject(self);

    .reactive = False for $!buttonLayout.get-children;
  }

  method onDestroy {
    self.makeInactive;
  }

  method event ($e) is vfunc {
    given $e.type {
      when CLUTTER_KEY_PRESS {
        $!pressedKey = $e.get-key-symbol;
      }

      when CLUTTER_KEY_RELEASE {
        my ($pressedKey, $symbol) = ($!pressedKey, $e.get-key-symbol);
        $!pressedKey = Nil;

        return CLUTTER_EVENT_PROPAGATE unless $symbol == $pressedKey;

        my $buttonInfo = %!buttonKeys{ $symbol };
        return CLUTTER_EVENT_PROPAGATE unless $buttonInfo;

        if .head.reactive && .tail {
          .tail();
           return CLUTTER_EVENT_STOP;
        }
      }
    }
    CLUTTER_EVENT_PROPAGATE;
  }

  method setInitialKeyFocus ($actor) {
    with $!initialKeyFocus { .disconnectObject(self) }
    $!initialKeyFocus = $actor;
    $actor.destroy.tap( -> *@a { $!initialKeyFocus = Nil});
  }

  method initialKeyFocus {
    $!initialKeyFocus // self
  }

  method addButton ($buttonInfo) {
    my ($label, $action, $key) = $buttonInfo<label action key>;
    my  $isDefault             = $buttonInfo<default>;
    my  @key                   = ();

    if $key {
      @key = $key.Array
    } elsif $isDefault {
      @key = [
        MUTTER_CLUTTER_KEY_Return,
        MUTTER_CLUTTER_KEY_KP_Enter,
        MUTTER_CLUTTER_KEY_ISO_Enter
      ];
    }

    my $button = Gnome::Shell::St::Button.new(
      $label,
      style-class => 'modal-dialog-linked-button',
      button-mask => ST_BUTTON_ONE +| ST_BUTTON_THREE,
      reactive    => True,
      can-focus   => True,
      x-expand    => True,
      y-expand    => True
    );

    $button.clicked.tap( -> *@a { $action() });
    $buttonInfo<button> = $button;

    $button.add-style-pseudo-class('default') if $isDefault;

    $!setInitialKeyFocus($button) if $!initialKeyFocus.not || $isDefault;
    $!buttonLayout.add-actor($button);
    return $button;
  }

  method clearButtons {
    $!buttonLayout.destroy-all-children;
    %!buttonKeys = Nil;
  }

}

class Gnome::Shell::Dialog::Message::Content is Gnome::Shell::St::BoxLayout {
  has $!title                  is built;
  has $!description            is built;
  has $!updateTitleStyleLater  is built;

  submethod BUILD ($params) {
    $!title       = Gnome::Shell::St::Label.new(
      style-class => 'message-dialog-title'
    );
    $!description = Gnome::Shell::St::Label.new(
      style-class => 'message-dialog-description'
    );

    $!description.clutter-text.ellipsize = PANGO_ELLIPSIZE_NONE;
    $!description.clutter-text.line-wrap = True;

    my $defaultParams = (
      style-class => 'message-dialog-content',
      x-expand    => True,
      vertical    => True
    );

    self.notify('size').tap( -> *@a { self.updateTitleStyle( |@a ) });
    self.destroy.tap(        -> *@a { self.onDestroy });

    self.add-child($!title);
    self.add-child($!description);
  }

  method onDestroy {
    Mutter::Meta::Later.remove($!updateTitleStyleLater)
      if $!updateTitleStyleLater;
  }

  method updateTitleStyle {
    return unless $!title.mapped;

    $!title.ensure-style;
    my ($, $titleNatWidth) = $!title.get-preferred-width(-1);

    if $titleNatWidth > self.width {
      return if $!updateTitleStyleLater;

      $!updateTitleStyleLater = Mutter::Meta::Later.add(
        META_LATER_BEFORE_REDRAW,
        -> *@a {
          $!updateTitleStyleLater = 0;
          $!title.add-style-class-name('lightweight');
          G_SOURCE_REMOVE
        }
      );
    }
  }

  method title is rw is g-property {
    Proxy.new:
      FETCH => -> $,    { $!title.text },

      STORE => -> $, \v {
        return if $!title.text eq v;

        self.setLabel($!title, v);
        $!title.remove-style-class-name('lightweight');
        self.updateTitleStyle;
        self.emit('notify::title');
      }
  }

  method description is rw is g-property {
    Proxy.new:
      FETCH => -> $,    { $!description.text },

      STORE => -> $, \v {
        return if $!description.text eq v;

        self.setLabel($!description, v);
        self.emit('notify::description');
      }
  }


  method new ( :$defaultParams, :$params ) {
    self.bless( :$defaultParams, :$params );
  }
}

class Gnome::Shell::Dialog::ListSection is Gnome::Shell::St::BoxLayout {
  has $!title;
  has $!list-scroll-view;
  has $.list;
  has $!title-changed;

  submethod BUILD {
    $!title = Gnome::Shell::St::Label.new(
      style-class => 'dialog-list-title'
    );

    $!list-scroll-view = Gnome::Shell::St::ScrollView(
      style-class       => 'dialog-list-scrollview',
      hscrollbar-policy => ST_POLICY_NEVER
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

class Gnome::Shell::UI::Dialog::ListSectionItem
  is Gnome::Shell::St::BoxLayout
{
  has $!iconActorBin        is built;
  has $!title               is built;
  has $!description         is built;
  has $!title-changed       is built;
  has $!description-changed is built;

  submethod BUILD {
    $!iconActorBin = Gnome::St::Bin.new;

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

    $textLayout.add-child($_) for $!title, $!description;
    self.style-class = 'dialog-list-item';
    self.label-actor = $!title;

    $_ = Supplier.new for $!title-changed, $!description-changed;

    self.add-child($_) for $!iconActorBin, $textLayout;
  }

  submethod DESTROY {
    .unref for $!iconActorBin, $!title, $!description
  }

  method icon-actor is rw {
    Proxy.new:
      FETCH => -> $                          { $!iconActorBin.get-child()  },
      STORE => -> $, MutterClutterActor() \a { $!iconActorBin.set-child(a) };
  }

  method title is rw {
    Proxy.new:
      FETCH => -> $           { $!title.text },

      STORE => -> $, Str() \t {
        $!title.text = t;
        $!title-changed.emit;
      };
  }

  method description is rw {
    Proxy.new:
      FETCH => -> $         { $!description.text },

      STORE => -> $, Str() \d {
        $!description.text = d;
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
