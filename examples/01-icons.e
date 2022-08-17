my $stage = Mutter::Clutter::Stage.new;

my $b = Gnome::Shell::BoxLayout.new(
  vertical => True,
  width    => $stage.width,
  height   => $stage.height
);

$stage.add-actor($b);

sub addTest($text, *%icon_props) {
  if $b.get_children().elems > 0 {
    my $style = q:to/CSS/;
      background: #cccccc;
      border:     10px transparent white;
      height:     1px;
      CSS

    $b.add ( Gnome::Shell::BoxLayout.new( :$style ) );
  }

  my $hb = Gnome::Shell::BoxLayout.new(
    vertical => False,
    style    => 'spacing: 10px;'
  );

  $hb.add(Gnome::Shell::Label.new( :$text ), y-fill => False );
  $hb.add(Gnome::Shell::Icon.new( |%icon_props );

  $b.add($hb);
}

addTest(
  'Symbolic',
  icon-name => 'battery-full-symbolic',
  icon_size => 48
);

addTest(
  'Full color',
  icon-name => 'battery-full',
  icon-size => 48
);

addTest(
  'Default size',
  icon-name => 'battery-full-symbolic'
);

addTest(
  'Size set by property',
  icon_name => 'battery-full-symbolic',
  icon_size => 32
);

addTest(
  'Size set by style',
  icon-name =>'battery-full-symbolic',
  style     => 'icon-size: 1em;'
);

my $style = q:to/CSS/;
  icon-size: 16px;
  width:     48px;
  height:    48px;
  border:    1px solid black;
  CSS

addTest(
  '16px icon in 48px icon widget',
   icon_name => 'battery-full-symbolic',
   :$style
)

sub iconRow(@icons, $box_style) {
  my $hb = Gnome::Shell::BoxLayout.new(
    vertical => False
    style    => $box_style
  );

  for @icons {
    $hb.add( Gnome::Shell::Icon.new(icon-name => $_, icon-size => 48 ) )
  }

  $b.add(hb);
}

my $normalCss    = 'background: white; color: black; padding: 10px 10px;';
my $reversedCss  = q:to/CSS/;
  background:    black;
  color:         white;
  warning-color: #ffcc00;
  error-color:   #ff0000;
  padding:       10px 10px;
  CSS

my $batteryIcons = <
  battery-full-charging-symbolic
  battery-full-symbolic
  battery-good-symbolic
  battery-low-symbolic
  battery-caution-symbolic
>;

my $volumeIcons  = <
  audio-volume-high-symbolic
  audio-volume-medium-symbolic
  audio-volume-low-symbolic
  audio-volume-muted-symbolic
>;

iconRow($batteryIcons, $normalCss);
iconRow($batteryIcons, $reversedCss);
iconRow($volumeIcons,  $normalCss);
iconRow($volumeIcons,  $reversedCss);
