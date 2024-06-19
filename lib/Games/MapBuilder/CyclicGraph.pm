use 5.38.2;
use experimental 'class';

use Games::MapBuilder ();

class Games::MapBuilder::CyclicGraph : isa(Games::MapBuilder) {
    field $map;
    method map() { $map }

    my @cycle_types = qw(
      TwoAlternativePaths
      TwoKeys
      HiddenShortcut
      DangerousRoute
      ForeshadowingLoop
      FalseGoal
      LockAndKeyCycle
      BlockedRetreat
      MonsterPatrol
      AlteredReturn
      FalseGoal
      SimpleLockAndKey
      Gambit
    );

    method random_cycle() {
        my $class = @cycle_types[ rand @cycle_types ];
        return __PACKAGE__ . "::$class"->new();
    }

    method insertion_points() { ... }
    method insert_cycle()     { ... }

    method build_map() {
        my $cycle = $self->random_cycle()->new();

        $cycle->insert_cycle( $self->random_cycle() )
          for $cycle->insertion_points();

        $map = $cycle->build_map();
    }
}

class Games::MapBuilder::CyclicGraph::TwoAlternativePaths :
  isa(Games::MapBuilder) {

    field $floor_tile : param;
    field $wall_tile : param;
    field $stairs_down_tile : param;

    field $min_size = 5;
    field $max_size = 10;
    field @rooms    = ();
    field $map;

    method rooms() { @rooms }

    method insertion_points() { 2, 4 }

    method insert_cycle ( $index, $cycle ) { $rooms[$index] = $cycle }

    method flatten() {

        # little helper sub here
        my sub rand_size() {
            int( $min_size + rand( $max_size + 1 - $min_size ) );
        }

        my sub new_room() {
            Games::MapBuilder::RectangularRoom->new(
                x      => 0,
                y      => 0,
                width  => rand_size(),
                height => rand_size(),
            );
        }

        # the first and third nodes are always rooms
        $rooms[0] = new_room();
        $rooms[2] = new_room();

        # the second and fourth nodes are either rooms or cycles
        for my $i (qw(4 2)) {
            if ( !defined $rooms[$i] ) {
                $rooms[$i] = new_room();
                next;
            }

            # otherwise splice in the rooms from the cycle
            splice @rooms, $i, 0, $rooms[$i]->flatten();
        }
        return $self;
    }

    my $tiles_to_floor = method( $x_slice, $y_slice ) {
        for my $y (@$y_slice) {
            $map->set_tile( $_, $y, clone($floor_tile) ) for @$x_slice;
        }
    };

    method build_map ( $width, $height, $depth = 1 ) {
        $map = Games::MapBuilder::Map->new(
            width  => $width,
            height => $height,
            depth  => $depth,
        );
        $map->tiles( map { clone($wall_tile) } 0 .. $width * $height );
        $self->flatten();

        my $current_x = 0;
        my $current_y = 0;
        for my $room (@rooms) {
            if ( $current_x + $room->width > $map->width ) {
                $current_x = 0;
                $current_y += $room->height;
            }
            if ( $current_y + $room->height > $map->height ) {
                die "Couldn't place room: "
                  . Data::Dumper::Dumper( $room->as_hash );
            }
            $self->$tiles_to_floor( $room->inner );
            ( $current_x, $current_y ) = $room->as_hash->%{qw( x y)};
        }
    }
}
