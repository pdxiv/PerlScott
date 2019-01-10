#!/usr/bin/perl
use strict;
use warnings;
use Readonly;
use Carp;
use English qw( -no_match_vars );
use Getopt::Long;
our $VERSION = '1.0.0';

Readonly::Scalar my $ACTION_COMMAND_OFFSET    => 6;
Readonly::Scalar my $ACTION_ENTRIES           => 8;
Readonly::Scalar my $AUTO                     => 0;
Readonly::Scalar my $COMMAND_CODE_DIVISOR     => 150;
Readonly::Scalar my $COMMANDS_IN_ACTION       => 4;
Readonly::Scalar my $CONDITION_DIVISOR        => 20;
Readonly::Scalar my $CONDITIONS               => 5;
Readonly::Scalar my $COUNTER_TIME_LIMIT       => 8;
Readonly::Scalar my $DIRECTION_NOUNS          => 6;
Readonly::Scalar my $FALSE                    => 0;
Readonly::Scalar my $FALSE_VALUE              => 0;
Readonly::Scalar my $FLAG_LAMP_EMPTY          => 16;
Readonly::Scalar my $FLAG_NIGHT               => 15;
Readonly::Scalar my $LIGHT_SOURCE_ID          => 9;
Readonly::Scalar my $LIGHT_WARNING_THRESHOLD  => 25;
Readonly::Scalar my $MESSAGE_1_END            => 51;
Readonly::Scalar my $MESSAGE_2_START          => 102;
Readonly::Scalar my $PAR_CONDITION_CODE       => 0;
Readonly::Scalar my $PERCENT_UNITS            => 100;
Readonly::Scalar my $ROOM_INVENTORY           => -1;
Readonly::Scalar my $ROOM_STORE               => 0;
Readonly::Scalar my $ROUNDING_OFFSET          => 0.5;
Readonly::Scalar my $TRUE                     => -1;
Readonly::Scalar my $VERB_CARRY               => 10;
Readonly::Scalar my $VERB_DROP                => 18;
Readonly::Scalar my $VERB_GO                  => 1;
Readonly::Scalar my $ALTERNATE_ROOM_REGISTERS => 6;
Readonly::Scalar my $ALTERNATE_COUNTERS       => 9;
Readonly::Scalar my $STATUS_FLAGS             => 32;
Readonly::Scalar my $MINIMUM_COUNTER_VALUE    => -1;
Readonly::Array my @DIRECTION_NOUN_TEXT => qw( NORTH SOUTH EAST WEST UP DOWN );

Readonly::Scalar my $FIAD_HEADER_START    => 0x08a0;
Readonly::Scalar my $FIAD_HEADER_POINTERS => 0x08ac;
Readonly::Scalar my $FIAD_POINTER_OFFSET  => 0x0380;

my $game_file;    # Filename of game data file
my ( $keyboard_input, $keyboard_input_2 );
my (
    $carried_objects,     $command_or_display_message,
    $command_parameter,   $command_parameter_index,
    $cont_flag,           $counter_register,
    $current_room,        $global_noun,
    $max_objects_carried, $number_of_actions,
    $number_of_messages,  $number_of_objects,
    $number_of_rooms,     $number_of_treasures,
    $number_of_words,     $starting_room,
    $stored_treasures,    $time_limit,
    $treasure_room_id,    $word_length,
    $adventure_version,   $adventure_number,
    $game_bytes,
);

my ( $number_of_verbs, $number_of_nouns );    # FIAD-specific

my ( @alternate_counter, @alternate_room );

my ( @object_description, @message, @extracted_input_words,
    @list_of_verbs_and_nouns, @room_description );

my ( @action_data, @action_description, @object_original_location,
    @object_location, @found_word, @room_exit, @status_flag );

my ( $command_in_handle, $command_out_handle );

$game_file = 'adv01.fiad';

load_fiad_game_data_file();

sub load_fiad_game_data_file {
    open my $handle, '<', $game_file or croak;
    my $file_content = do { local $INPUT_RECORD_SEPARATOR; <$handle> };
    close $handle or croak;

    my $unpack_pattern;
    $unpack_pattern = "\@${FIAD_HEADER_START}CCCCCCCCnC";

    # Unpack header into variables
    (
        $number_of_objects,   $number_of_verbs,     $number_of_nouns,
        $number_of_rooms,     $max_objects_carried, $starting_room,
        $number_of_treasures, $word_length,         $time_limit,
        $treasure_room_id
    ) = unpack $unpack_pattern, $file_content;

    print "number_of_objects: $number_of_objects\n";
    print "number_of_verbs: $number_of_verbs\n";
    print "number_of_nouns: $number_of_nouns\n";
    print "number_of_rooms: $number_of_rooms\n";
    print "max_objects_carried: $max_objects_carried\n";
    print "starting_room: $starting_room\n";
    print "number_of_treasures: $number_of_treasures\n";
    print "word_length: $word_length\n";
    print "time_limit: $time_limit\n";
    print "treasure_room_id: $treasure_room_id\n";

    $unpack_pattern = "\@${FIAD_HEADER_POINTERS}nnnnnnnnnnn";
    my (
        $pointer_object_table,
        $pointer_original_items,
        $pointer_link_table_from_noun_to_object,
        $pointer_object_descriptions,
        $pointer_message_pointers,
        $pointer_room_exits_table,
        $pointer_room_descr_table,
        $pointer_noun_table,
        $pointer_verb_table,
        $pointer_explicit_action_table,
        $pointer_implicit_actions
    ) = unpack $unpack_pattern, $file_content;

    # Subtract offset value from pointer, to get correct location in file
    foreach (
        (
            $pointer_object_table,
            $pointer_original_items,
            $pointer_link_table_from_noun_to_object,
            $pointer_object_descriptions,
            $pointer_message_pointers,
            $pointer_room_exits_table,
            $pointer_room_descr_table,
            $pointer_noun_table,
            $pointer_verb_table,
            $pointer_explicit_action_table,
            $pointer_implicit_actions
        )
      )
    {
        $_ -= $FIAD_POINTER_OFFSET;
    }

    printf "pointer_object_table: %04x\n",   $pointer_object_table;
    printf "pointer_original_items: %04x\n", $pointer_original_items;
    printf "pointer_link_table_from_noun_to_object: %04x\n",
      $pointer_link_table_from_noun_to_object;
    printf "pointer_object_descriptions: %04x\n", $pointer_object_descriptions;
    printf "pointer_message_pointers: %04x\n",    $pointer_message_pointers;
    printf "pointer_room_exits_table: %04x\n",    $pointer_room_exits_table;
    printf "pointer_room_descr_table: %04x\n",    $pointer_room_descr_table;
    printf "pointer_noun_table: %04x\n",          $pointer_noun_table;
    printf "pointer_verb_table: %04x\n",          $pointer_verb_table;
    printf "pointer_explicit_action_table: %04x\n",
      $pointer_explicit_action_table;
    printf "pointer_implicit_actions: %04x\n", $pointer_implicit_actions;

    return 1;
}
