use 5.38.2;
use experimental 'class';

class Games::MapBuilder::Room {
    method random_point() { ... }
    method center()       { ... }
    method inner()        { ... }

    # must provide at least the corners as x1, y1, x2, y2
    method as_hash() { ... }

    method intersects ($other) {
        if ( $other isa Games::MapBuilder::Room ) {
            return $other->intersects( $self->as_hash );
        }
        unless ( ref $other eq 'HASH' ) {
            die "$other is not a Room object nor a hash reference";
        }

        my ( $x1, $y1, $x2, $y2 ) = $self->as_hash->@{qw(x1 y1 x2 y2)};

        if ( ref $other eq 'HASH' ) {
            if (   $x2 < $other->{x1}
                || $y2 < $other->{y1}
                || $other->{x2} < $x1
                || $other->{y2} < $y1 )
            {
                return 0;
            }

            return 1;
        }
        die "$other is not a Room object";
    }
}

class Games::MapBuilder::RectangularRoom : isa(Games::MapBuilder::Room) {
    field $x1 : param(x);
    field $y1 : param(y);    # ()()
    field $height : param;
    field $width : param;

    field $x2 = $x1 + $width;
    field $y2 = $y1 + $height;

    method set_origin ( $x, $y ) {
        $x1 = $x;
        $y1 = $y;
        $x2 = $x1 + $width;
        $y2 = $y1 + $height;
    }

    method random_point() {
        my $x = int( $x1 + rand($width) + 1 );
        my $y = int( $y1 + rand($height) + 1 );
        return [ $x, $y ];
    }

    method center() {
        my $x = int( $x1 + $width / 2 );
        my $y = int( $y1 + $height / 2 );
        return [ $x, $y ];
    }

    method inner() {
        [ $x1 + 1 .. $x2 ], [ $y1 + 1 .. $y2 ];
    }

    method as_hash() {
        return {
            x1     => $x1,
            y1     => $y1,
            x2     => $x2,
            y2     => $y2,
            height => $height,
            width  => $width,
        };
    }
}

class Games::MapBuilder::SimpleMapBuilder : isa(Games::MapBuilder) {
    use List::Util qw( any max min );

    field $room_count : param              = 30;
    field $min_size : param(min_room_size) = 6;
    field $max_size : param(max_room_size) = 10;

    field $floor_tile : param;
    field $wall_tile : param;
    field $stairs_down_tile : param;

    field @rooms = ();
    field $map;

    method map() { $map }

    my sub clone ($obj) { $obj->new( $obj->as_hash->%* ) }

    my $tiles_to_floor = method( $x_slice, $y_slice ) {
        for my $y (@$y_slice) {
            $map->set_tile( $_, $y, clone($floor_tile) ) for @$x_slice;
        }
    };

    my $tunnel_between = method( $start, $end ) {
        my ( $x1, $y1 ) = @$start;
        my ( $x2, $y2 ) = @$end;
        if ( rand() < 0.5 ) {

            # horizontal then vertical
            $self->$tiles_to_floor( [ min( $x1, $x2 ) .. max( $x1, $x2 ) ],
                [$y1] );
            $self->$tiles_to_floor( [$x2],
                [ min( $y1, $y2 ) .. max( $y1, $y2 ) ] );
        }
        else {
            # vertical then horizontal
            $self->$tiles_to_floor( [ min( $x1, $x2 ) .. max( $x1, $x2 ) ],
                [$y2] );
            $self->$tiles_to_floor( [$x1],
                [ min( $y1, $y2 ) .. max( $y1, $y2 ) ] );
        }
    };

    method build_map ( $width, $height, $depth = 1 ) {
        $map = Games::MapBuilder::Map->new(
            width  => $width,
            height => $height,
            depth  => $depth,
        );

        $map->tiles( map { clone($wall_tile) } 0 .. $width * $height );

        for ( 0 .. $room_count ) {
            my $rw = int( $min_size + rand( $max_size + 1 - $min_size ) );
            my $rh = int( $min_size + rand( $max_size + 1 - $min_size ) );

            my $room = Games::MapBuilder::RectangularRoom->new(
                x      => int( 0 + rand( $map->width - $rw ) ),
                y      => int( 0 + rand( $map->height - $rh ) ),
                width  => $rw,
                height => $rh,
            );

            # if the new room intersects with a current room, skip it
            next if any { $_->intersects($room) } @rooms;

            # otherwise, dig out the floor
            $self->$tiles_to_floor( $room->inner );

            # tunnel between the previous room and this one
            $self->$tunnel_between( $rooms[-1]->center, $room->center )
              if @rooms;

            # add the room to the list
            push @rooms, $room;
        }
        my $stairs = $rooms[-1]->center;
        $map->set_tile( $stairs->@*, clone($stairs_down_tile) );
        return $self;
    }

    method spawn_entities ($spawner) {
        die "spawner must have a spawn_room method"
          unless $spawner->can('spawn_room');
        $spawner->spawn_room( $map, $_ ) for @rooms;
    }

    method get_starting_position() { $rooms[0]->center }
}
