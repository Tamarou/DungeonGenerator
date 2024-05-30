#!/usr/bin/env perl
use v5.38.2;
use lib 'lib';
use experimental 'class';

use Games::MapBuilder ();
use Term::Screen;

class Tile : isa(Games::MapBuilder::MapTile) {
    field $glyph : param    = '?';
    field $walkable : param = 0;

    method glyph() { $glyph }

    method is_walkable() { $walkable }

    method as_hash() {
        return {
            glyph    => $glyph,
            walkable => $walkable,
        };
    }
}

my $map_builder = Games::MapBuilder::SimpleMapBuilder->new(
    min_room_size    => 6,
    max_room_size    => 10,
    floor_tile       => Tile->new( glyph => '.', walkable => 1 ),
    stairs_down_tile => Tile->new( glyph => '>', walkable => 1 ),
    wall_tile        => Tile->new( glyph => '#', walkable => 0 ),
);

my $map  = $map_builder->build_map( 24, 80 )->map;
my $term = Term::Screen->new();
$term->clrscr();
$term->curinvis();
while (1) {
    my $i = 0;
    for my $tile ( $map->tiles ) {
        $term->at( $map->xy_for_index( $i++ ) )->puts( $tile->glyph );
    }
}
