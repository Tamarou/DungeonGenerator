use 5.38.2;
use experimental qw(class);

class Games::MapBuilder::MapTile {
    method as_hash() { ... }
}

class Games::MapBuilder::Map {
    field $width : param;
    field $height : param;
    field $depth : param;

    field @tiles = ();

    method tiles (@t) {
        if (@t) { @tiles = @t }
        @tiles;
    }

    method width()  { $width }
    method height() { $height }
    method size()   { $width * $height }

    method xy_for_index ($i) {
        my $x = $i % $width;
        my $y = int( $i / $width );
        return $x, $y;
    }

    method set_tile ( $x, $y, $tile ) {
        $tiles[ $y * $width + $x ] = $tile;
    }
}

class Games::MapBuilder {
    method build_map      ($map)             { ... }
    method spawn_entities ( $map, $spawner ) { ... }
    method map()                   { ... }
    method get_starting_position() { ... }

    # method get_snapshot_history() { ... }
    # method take_snapshot()        { ... }
}

use Games::MapBuilder::SimpleMapBuilder ();
