use v6.c;

use Gnome::Shell::Raw::Types;

### /home/cbwood/Projects/gnome-shell/js/ui/checkBox.js

class Gnome::Shell::St::UI::Checkbox {
  has $!container;
  has $!box;
  has $!label handles(text => 'label');

  submethod BUILD ( :$label ) {
    $!container = Gnome::Shell::BoxLayout.new(
      x_expand => True,
      y_expand => True,
    );

    self.add-child($!container);

    self.style_class = 'check-box';
    self.button_mask = ST_BUTTON_MASK_ONE;
    self.toggle_mode = True;
    self.can_focus   = True;

    $!box = Gnome::Shell::Bin.new( y-align => CLUTTER_ACTOR_ALIGN_START );
    $!container.add_child($!box);
    $!label = Gnome::Shell::Label.new( y-align => CLUTTER_ACTOR_ALIGN_CENTER );
    $!label.clutter-text.line-wrap = True;
    $!label.clutter-text.ellipsize = PANGO_ELLIPSIZE_NONE;
    $!container.add_child($!label);

    self.set_accessible_role(ATK_ROLE_CHECK_BOX);
    self.label-actor = $!label;
    self.set_label($label);
  }

  method Gnome::Shell::Raw::Definitions::StWidget
  { self.get_content_area.StWidget }

  method set_label ($label) {
    return unless $label;
    self.label = $label;
  }

  method get_content_area {
    $!container;
  }

  method get_label_actor {
    $!label;
  }

  method new ( :$label, *%props ) {
    self.bless( :$label, |%props );
  }

}
