// @ts-check
// A delivery door: a trigger the courier walks through. With a parcel on its back the parcel is handed in (the level
// flow counts it and sends parcel_delivered); without one the door only blips.
import { Behaviour, world, audio } from "factoria";

export default class DeliveryDoor extends Behaviour {
  /** Id of the entity with the level_flow script. */
  levelId = "level";

  onTriggerEnter(other) {
    if (!other.hasTag("courier")) return;
    const courier = other.behaviour;
    if (courier.carrying <= 0) {
      if (!this.warned) audio.play("assets/audio/error_001.ogg", { bus: "sfx", volume: 0.5 });
      this.warned = true;
      return;
    }
    const n = courier.deliver();
    audio.play("assets/audio/confirmation_002.ogg", { bus: "sfx", volume: 0.9 });
    const flow = world.find(this.levelId)?.behaviour;
    if (flow) flow.onDelivery(this.entity.id, n);
  }

  onTriggerExit(other) {
    if (other.hasTag("courier")) this.warned = false;
  }
}
