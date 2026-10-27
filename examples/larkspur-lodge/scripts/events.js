// @ts-check
// The game events of Larkspur Lodge: the names sent with world.emit and what each one carries. Scripts import EVENTS
// instead of writing the strings, so a typo is a load error and not a silent no-op. world.on listeners die with the scene
// (an event is dropped on a scene load): a script that needs a fact across scenes reads scripts/story.js (the flags),
// scripts/items.js (the inventory) or `session`.
//
//   emit(EVENTS.interacted, { id: "library_desk", kind: "examine" });
//   world.on(EVENTS.flagChanged, (d) => d.flag === "storm_over" && ...);
//
// README.md, "Contracts", lists the same events as the contract between the packages.
import { world } from "factoria";

export const EVENTS = Object.freeze({
  /** An area (a scene of the lodge) is ready and the porter stands at its spawn: { area: "ground", spawn: "spawn_default", scene: path }. */
  areaReady: "area_ready",
  /** The porter started to leave the area through a door or stairs: { from: area, to: area, spawn: spawn id }. */
  areaLeaving: "area_leaving",
  /** The porter used an interactable: { id: entity id, kind: "door"|"area"|"examine"|"item"|"talk", name: locale key, ok: bool }. */
  interacted: "interacted",
  /** The nearest interactable in reach changed (or there is none): { id: entity id | null, kind, verb: locale key | null }. */
  targetChanged: "target_changed",
  /** A door was opened: { id: entity id }. A door that stays shut sends doorLocked instead. */
  doorOpened: "door_opened",
  /** A locked door was tried: { id: entity id, requires: item id | flag name, text: locale key of the line shown }. */
  doorLocked: "door_locked",
  /** An item went into the inventory: { item: item id, from: entity id | "" }. */
  itemPicked: "item_picked",
  /** The inventory changed (an item added or removed): { items: [item ids] }. */
  inventoryChanged: "inventory_changed",
  /** A story flag changed: { flag, value, previous } (scripts/story.js). */
  flagChanged: "flag_changed",
  /** Something wants a conversation: { id: dialogue id, speaker: entity id }. scripts/dialogue.js answers it. */
  dialogueRequested: "dialogue_requested",
  /** A conversation began: { id: conversation id, speaker: entity id of whoever talks }. */
  dialogueStarted: "dialogue_started",
  /** A line is on offer: { id: conversation id, node: node id, speaker: character id, textKey, voice: clip id | "", choices: [{ id, textKey }] }. */
  dialogueLine: "dialogue_line",
  /** A conversation is over: { id: conversation id, speaker: entity id, completed: false when it was aborted, picked: [choice ids] }. */
  dialogueEnded: "dialogue_ended",
  /** The night moved to another chapter: { chapter: new number, previous: number }. scripts/chapters.js sends it. */
  chapterChanged: "chapter_changed",
  /** The story is over: { ending: "dawn" | "quiet" | "long" }. The ending screen is up; the porter takes no input. */
  storyEnded: "story_ended",
  /** Something wants a cut-scene (P4): { id: cut-scene id }. scripts/cutscene.js answers it. */
  cutsceneRequested: "cutscene_requested",
  /** A cut-scene began to play: { id, skippable }. cutscene.active() is true from now on. */
  cutsceneStarted: "cutscene_started",
  /** A cut-scene is over and its end state is in place (also when it was skipped): { id, skipped }. cutscene.active() is false unless another one is queued. */
  cutsceneEnded: "cutscene_ended",
  /** The porter changed how it is controlled (the last device that gave input): { device: "keyboard"|"mouse"|"touch"|"gamepad" }. */
  deviceChanged: "device_changed",
});

/** Sends an event to every listener of the scene (world.emit with a name from EVENTS). */
export function emit(name, data = {}) {
  world.emit(name, data);
}
