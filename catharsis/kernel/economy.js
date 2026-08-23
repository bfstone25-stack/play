/* StarDust + ammo. Numbers only — titles never mint their own currency. */
const Economy = (() => {
  const state = { stardust: 0, tickets: 20 };
  const TICKET_CAP = 99;

  function snapshot() {
    return { stardust: state.stardust, tickets: state.tickets };
  }

  function grant(n) {
    const v = Math.max(0, Math.floor(n) || 0);
    state.stardust += v;
    return v;
  }

  function spend(n) {
    const v = Math.max(0, Math.floor(n) || 0);
    if (state.stardust < v) return false;
    state.stardust -= v;
    return true;
  }

  function addTickets(n) {
    const v = Math.floor(n) || 0;
    state.tickets = Math.max(0, Math.min(TICKET_CAP, state.tickets + v));
    return state.tickets;
  }

  function consumeTicket() {
    if (state.tickets <= 0) return false;
    state.tickets -= 1;
    return true;
  }

  function load(data) {
    if (!data) return snapshot();
    state.stardust = Math.max(0, Math.floor(data.stardust) || 0);
    state.tickets = Math.max(0, Math.min(TICKET_CAP, Math.floor(data.tickets) || 0));
    return snapshot();
  }

  return { snapshot, grant, spend, addTickets, consumeTicket, load, TICKET_CAP };
})();
