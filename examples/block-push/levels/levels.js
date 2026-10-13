// Level data for Block Push. Each map is text, one string per row, top row first.
//   #  wall          .  target (goal tile)      $  box          @  player
//   (space)  floor
// Checked by `factoria call project.check_levels '{}' --project .`:
// same number of boxes and targets, exactly one player, walls that close the play area.

export const LEVELS = [
  {
    name: "First push",
    map: [
      "#######",
      "#     #",
      "#. $@ #",
      "#     #",
      "#######",
    ],
  },
  {
    name: "Two crates",
    map: [
      "#######",
      "#     #",
      "# .$  #",
      "#  $. #",
      "#  @  #",
      "#######",
    ],
  },
  {
    name: "Three crates",
    map: [
      "#########",
      "#       #",
      "# $ # . #",
      "#   #   #",
      "# $ @ . #",
      "#   $ . #",
      "#########",
    ],
  },
];
