use GTK::Main;
use Mutter::Clutter::Stage;
use Gnome::Shell::BoxLayout;
use Gnome::Shell::Button;
use Gnome::Shell::Label;

GTK::Main.init;

my $stage = Mutter::Clutter::Stage.new

my $vbox = Gnome::Shell::BoxLayout.new(
  vertical => True,
  width    => $stage.width,
  height   => $stage.height
);
$stage.add_actor($vbox);

my $hbox = Gnome::Shell::BoxLayout( style => 'spacing: 12px;' );
$vbox.add($hbox);

my $text = Gnome::Shell::Label.new( text => 'Styled Text' );
$vbox.add ($text);

my $size = 24;

sub update_size() {
    $text.style = 'font-size: ' + $size + 'pt';
}
update_size();

my $s-button = Gnome::Shell::Button.new(
  label       => 'Smaller',
  style-class => 'push-button'
);

$hbox.add ($s-button);
$s-button.clicked.tap({
    $size /= 1.2;
    update_size;
});

$b-button = Gnome::Shell::Button.new(
  label       => 'Bigger',
  style_class => 'push-button'
);

$hbox.add ($b-button);
$b-button.clicked.tap({
  $size *= 1.2;
  update_size;
});

GTK::Main.run;
