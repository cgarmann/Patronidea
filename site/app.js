const data = window.FRUMA_DATA;

const state = {
  role: "patron",
  route: "#/patron/vault",
  query: "",
  filters: {
    category: "All",
    status: "All",
    maturity: "All",
    requestState: "All",
    innovatorBackground: "All"
  },
  favorites: new Set(["idea-102", "idea-103"]),
  selectedDealId: "deal-301",
  reviewFilter: "All",
  adminDecisions: {},
  inlineReview: null,
  requests: [...data.requests],
  deals: [...data.deals],
  offers: [...data.offers],
  modal: null
};

const patronNav = [
  ["Vault", "#/patron/vault"],
  ["Favorites", "#/patron/favorites"],
  ["Deal Room", "#/patron/deals/deal-301"],
  ["Pricing", "#/patron/pricing"]
];

const adminNav = [
  ["Dashboard", "#/admin/dashboard"],
  ["Review queue", "#/admin/review"],
  ["Users", "#/admin/users"],
  ["Subscriptions", "#/admin/subscriptions"],
  ["Reports", "#/admin/reports"],
  ["Contact log", "#/admin/contact-log"],
  ["Moderation", "#/admin/moderation"]
];

window.addEventListener("hashchange", routeFromHash);
document.addEventListener("DOMContentLoaded", () => {
  if (!location.hash) location.hash = state.route;
  routeFromHash();
});

function routeFromHash() {
  state.route = location.hash || "#/patron/vault";
  state.role = state.route.includes("/admin/") ? "admin" : "patron";
  render();
}

function render() {
  document.getElementById("app").innerHTML = `
    <div class="layout">
      ${renderSidebar()}
      <main class="main">
        ${renderTopbar()}
        <section class="content">${renderRoute()}</section>
      </main>
    </div>
  `;
  renderModal();
}

function renderSidebar() {
  const nav = state.role === "admin" ? adminNav : patronNav;
  const label = state.role === "admin" ? "Operator tasks" : "Patron workflow";
  return `
    <aside class="sidebar">
      <div class="brand">
        <strong>FRUMA</strong>
        <span class="demo-pill">DEMO</span>
      </div>
      <div class="nav-group-label">${label}</div>
      ${nav.map(([labelText, href]) => `
        <button class="nav-link ${isActive(href) ? "active" : ""}" onclick="go('${href}')">
          <span>${labelText}</span>
          ${navCount(labelText)}
        </button>
      `).join("")}
    </aside>
  `;
}

function renderTopbar() {
  return `
    <header class="topbar">
      <input class="global-search" value="${escapeHtml(state.query)}" placeholder="Search ideas, users, deals" oninput="setQuery(this.value)">
      <div class="role-switch" aria-label="Role switcher">
        <button class="${state.role === "patron" ? "active" : ""}" onclick="go('#/patron/vault')">Patron</button>
        <button class="${state.role === "admin" ? "active" : ""}" onclick="go('#/admin/dashboard')">Admin</button>
      </div>
      <div class="profile">
        <span class="avatar">${state.role === "admin" ? "SA" : "ML"}</span>
        <span class="muted">${state.role === "admin" ? "Schjoldr Admin" : "Northline Patron"}</span>
      </div>
    </header>
  `;
}

function renderRoute() {
  const route = state.route;
  if (route.startsWith("#/patron/idea/")) return renderIdeaDetail(route.split("/").pop());
  if (route.startsWith("#/patron/deals")) return renderDealRoom(route.split("/").pop());
  if (route === "#/patron/favorites") return renderFavorites();
  if (route === "#/patron/pricing") return renderPricing();
  if (route === "#/admin/dashboard") return renderAdminDashboard();
  if (route === "#/admin/review") return renderReviewQueue();
  if (route === "#/admin/users") return renderUsers();
  if (route === "#/admin/subscriptions") return renderSubscriptions();
  if (route === "#/admin/reports") return renderReports();
  if (route === "#/admin/contact-log") return renderContactLog();
  if (route === "#/admin/moderation") return renderModeration();
  return renderVault();
}

function renderVault() {
  const ideas = filteredIdeas();
  return `
    ${viewHead("Vault", "Enterprise discovery queue for reviewed opportunities and controlled access requests.")}
    <div class="split">
      <aside class="panel filter-panel compact-filter">
        <h3>Filters</h3>
        ${selectField("Idea category", "category", ["All", ...data.categories], state.filters.category, "setFilter")}
        ${selectField("Innovator background", "innovatorBackground", ["All", ...data.innovatorBackgrounds], state.filters.innovatorBackground, "setFilter")}
        ${selectField("Status", "status", ["All", "active", "pending request", "in negotiation"], state.filters.status, "setFilter")}
        ${selectField("Maturity", "maturity", ["All", ...uniqueIdeaValues("maturity")], state.filters.maturity, "setFilter")}
        ${selectField("Request state", "requestState", ["All", ...uniqueIdeaValues("requestState")], state.filters.requestState, "setFilter")}
        <button class="button" onclick="clearFilters()">Clear filters</button>
      </aside>
      <div>
        ${renderFilterChips()}
        <div class="table-card vault-table-card">
          <table class="vault-table">
            <thead>
              <tr>
                <th>Opportunity brief</th>
                <th>Domain</th>
                <th>Source background</th>
                <th>Status</th>
                <th>Maturity</th>
                <th>Signal</th>
                <th>Requests</th>
                <th>Last activity</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              ${ideas.length ? ideas.map(renderVaultRow).join("") : `<tr><td colspan="9">${emptyState("No ideas match these filters.")}</td></tr>`}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  `;
}

function renderVaultRow(idea) {
  return `
    <tr class="vault-row">
      <td class="brief-cell">
        <strong>${idea.title}</strong>
        <p>${idea.summary}</p>
      </td>
      <td><span class="badge info">${idea.category}</span></td>
      <td>${idea.innovatorBackground}</td>
      <td>${statusBadge(idea.status)}</td>
      <td>${idea.maturity}</td>
      <td>
        <strong>${idea.confidence}</strong>
        <span class="cell-note">${idea.validationState}</span>
      </td>
      <td>
        <strong>${idea.requestCount}</strong>
        <span class="cell-note">${idea.requestState}</span>
      </td>
      <td>${idea.updatedAt}</td>
      <td>
        <div class="row-actions">
          <button class="button primary compact" onclick="go('#/patron/idea/${idea.id}')">Open brief</button>
          <button class="button compact" onclick="openRequestModal('${idea.id}')">Request access</button>
        </div>
      </td>
    </tr>
  `;
}

function renderIdeaCard(idea) {
  return `
    <article class="card idea-card">
      <div class="idea-card-head">
        <div>
          <span class="badge info">${idea.category}</span>
          <h3>${idea.title}</h3>
        </div>
        ${favoriteButton(idea.id)}
      </div>
      <p>${idea.summary}</p>
      <div class="meta-row">
        ${statusBadge(idea.status)}
        <span class="badge">${idea.maturity}</span>
        <span class="muted">${idea.requestCount} requests</span>
      </div>
      <div class="action-row">
        <button class="button primary" onclick="go('#/patron/idea/${idea.id}')">Inspect idea</button>
        <button class="button" onclick="openRequestModal('${idea.id}')">Send request</button>
      </div>
    </article>
  `;
}

function renderFavorites() {
  const ideas = data.ideas.filter((idea) => state.favorites.has(idea.id));
  return `
    ${viewHead("Favorites", "Saved opportunities for later inspection and request follow-up.", "Return to Vault", "go('#/patron/vault')")}
    <div class="grid cols-2">
      ${ideas.length ? ideas.map(renderIdeaCard).join("") : emptyState("No saved ideas yet. Favorite ideas in the Vault.")}
    </div>
  `;
}

function renderIdeaDetail(id) {
  const idea = findIdea(id);
  if (!idea) return emptyState("Idea not found.");
  return `
    ${viewHead("Idea detail", "Inspect the opportunity before sending a controlled request.", "Send request", `openRequestModal('${idea.id}')`)}
    <div class="detail-layout">
      <article class="panel">
        <div class="meta-row">
          <span class="badge info">${idea.category}</span>
          ${statusBadge(idea.status)}
          <span class="badge">${idea.maturity}</span>
        </div>
        <h1>${idea.title}</h1>
        <p>${idea.summary}</p>
        <hr>
        <h3>Problem</h3>
        <p>${idea.problem}</p>
        <h3>Value</h3>
        <p>${idea.value}</p>
        <h3>Tags</h3>
        <div class="chips">${idea.tags.map((tag) => `<span class="chip">${tag}</span>`).join("")}</div>
      </article>
      <aside class="panel">
        <h3>Source and actions</h3>
        <p><strong>Anonymized source:</strong><br>${idea.source}</p>
        <p><strong>Submitted:</strong><br>${idea.submittedAt}</p>
        <p><strong>Updated:</strong><br>${idea.updatedAt}</p>
        <div class="action-row">
          ${favoriteButton(idea.id, "full")}
          <button class="button primary" onclick="openRequestModal('${idea.id}')">Send request</button>
          <button class="button" onclick="go('#/patron/vault')">Back to Vault</button>
        </div>
      </aside>
    </div>
  `;
}

function renderDealRoom(id) {
  const selected = state.deals.find((deal) => deal.id === id) || state.deals[0];
  state.selectedDealId = selected.id;
  const idea = findIdea(selected.ideaId);
  const offer = state.offers.find((item) => item.id === selected.activeOfferId);
  return `
    ${viewHead("Deal Room", "Track requests, proposals, counteroffers and next action.", "Submit proposal", "openOfferModal()")}
    <div class="deal-layout">
      <aside class="grid">
        ${state.deals.map((deal) => {
          const dealIdea = findIdea(deal.ideaId);
          return `<button class="list-item ${deal.id === selected.id ? "active" : ""}" onclick="go('#/patron/deals/${deal.id}')">
            <strong>${dealIdea.title}</strong>
            ${statusBadge(deal.status)}
          </button>`;
        }).join("")}
      </aside>
      <section class="grid">
        <article class="panel">
          <div class="meta-row">${statusBadge(selected.status)}<span class="badge info">${idea.category}</span></div>
          <h2>${idea.title}</h2>
          <p>${idea.summary}</p>
        </article>
        <article class="panel">
          <h3>Active proposal</h3>
          ${offer ? renderOffer(offer) : emptyState("No active proposal. Submit one to start negotiation.")}
        </article>
        <article class="panel">
          <h3>Messages</h3>
          <div class="grid">${selected.messages.map((msg) => `<div class="message"><strong>${msg.from}</strong><p>${msg.text}</p><span class="muted">${msg.at}</span></div>`).join("")}</div>
        </article>
        <article class="panel">
          <h3>History</h3>
          <div class="timeline">${selected.history.map((item) => `<div class="timeline-item"><strong>${item.at}</strong><p>${item.text}</p></div>`).join("")}</div>
        </article>
      </section>
    </div>
  `;
}

function renderOffer(offer) {
  return `
    <div class="offer">
      <div class="meta-row">${statusBadge(offer.status)}<span class="badge">${offer.type}</span></div>
      <h3>${formatMoney(offer.amount, offer.currency)}</h3>
      <p>${offer.note}</p>
      <p class="muted">From: ${offer.from}</p>
      <div class="action-row">
        <button class="button primary" onclick="acceptOffer('${offer.id}')">Accept</button>
        <button class="button" onclick="openOfferModal('counter')">Counteroffer</button>
      </div>
    </div>
  `;
}

function renderPricing() {
  const plans = [
    ["Basic", "99 kr/month launch", "Vault access, 3 requests/day, mobile-first"],
    ["Pro", "299 kr/month launch", "Saved searches, favorites, exports, web dashboard"],
    ["Enterprise", "Custom", "Team access, advanced reporting, account support"]
  ];
  return `
    ${viewHead("Pricing", "Simple B2B patron plans. Current demo state: Pro access.", "Upgrade plan")}
    <div class="grid cols-3">
      ${plans.map(([name, price, body]) => `<article class="card">
        <span class="badge ${name === "Pro" ? "success" : ""}">${name === "Pro" ? "Current plan" : "Plan"}</span>
        <h2>${name}</h2>
        <h3>${price}</h3>
        <p>${body}</p>
        <button class="button ${name === "Pro" ? "" : "primary"}">${name === "Pro" ? "Current" : "Select plan"}</button>
      </article>`).join("")}
    </div>
  `;
}

function renderAdminDashboard() {
  const pending = data.reviewItems.filter((item) => effectiveReviewStatus(item) === "under review").length;
  const approved = data.reviewItems.filter((item) => effectiveReviewStatus(item) === "approved").length;
  const rejected = Object.values(state.adminDecisions).filter((item) => item.status === "rejected").length;
  return `
    ${viewHead("Admin dashboard", "At-a-glance view of what needs attention now.", "Open review queue", "go('#/admin/review')")}
    <div class="stat-grid">
      ${stat("Pending reviews", pending)}
      ${stat("Approved", approved)}
      ${stat("Rejected", rejected)}
      ${stat("Active users", data.users.filter((user) => user.status === "active").length)}
    </div>
    <div class="grid cols-2" style="margin-top:16px">
      <section class="panel">
        <h3>Recent review activity</h3>
        <div class="timeline">
          ${data.reviewItems.map((item) => `<div class="timeline-item"><strong>${findIdea(item.ideaId).title}</strong><p>${effectiveReviewStatus(item)} · ${item.submittedAt}</p></div>`).join("")}
        </div>
      </section>
      <section class="panel">
        <h3>Moderation alerts</h3>
        <div class="grid">${data.moderationItems.map((item) => `<button class="list-item" onclick="go('#/admin/moderation')"><strong>${item.type}</strong><span>${item.note}</span>${statusBadge(item.severity)}</button>`).join("")}</div>
      </section>
    </div>
  `;
}

function renderReviewQueue() {
  const items = data.reviewItems.filter((item) => state.reviewFilter === "All" || effectiveReviewStatus(item) === state.reviewFilter);
  return `
    ${viewHead("Review queue", "Fast operator triage for submitted ideas and review outcomes.", "Show all", "setReviewFilter('All')")}
    <div class="chips">
      ${["All", "under review", "approved", "rejected", "returned"].map((status) => `<button class="chip" onclick="setReviewFilter('${status}')">${status}</button>`).join("")}
    </div>
    <div class="table-card">
      <table>
        <thead><tr><th>Idea</th><th>Category</th><th>Status</th><th>Risk</th><th>Score</th><th>Action</th></tr></thead>
        <tbody>
          ${items.map((item) => {
            const idea = findIdea(item.ideaId);
            const decision = state.adminDecisions[item.id];
            return `<tr>
              <td><strong>${idea.title}</strong><br><span class="muted">${idea.summary}</span></td>
              <td>${item.category}</td>
              <td>
                ${statusBadge(effectiveReviewStatus(item))}
                ${decision?.reason ? `<span class="cell-note">${decision.reason}</span>` : ""}
              </td>
              <td>${statusBadge(item.risk)}</td>
              <td>${item.score}</td>
              <td>
                <div class="review-actions">
                  <button class="button primary compact" onclick="submitDecision('${item.id}', 'approved')">Approve</button>
                  <button class="button compact" onclick="startInlineDecision('${item.id}', 'returned')">Return</button>
                  <button class="button danger compact" onclick="startInlineDecision('${item.id}', 'rejected')">Reject</button>
                </div>
              </td>
            </tr>
            ${renderInlineDecisionRow(item, idea)}`;
          }).join("")}
        </tbody>
      </table>
    </div>
  `;
}

function renderInlineDecisionRow(item, idea) {
  if (!state.inlineReview || state.inlineReview.id !== item.id) return "";
  const label = state.inlineReview.status === "rejected" ? "Reject reason" : "Return reason";
  return `
    <tr class="inline-decision-row">
      <td colspan="6">
        <div class="inline-decision">
          <div>
            <strong>${label}</strong>
            <span class="muted">${idea.title}</span>
          </div>
          <input id="review-reason-${item.id}" value="${escapeHtml(state.inlineReview.reason)}" placeholder="Short operator note">
          <button class="button primary compact" onclick="submitInlineDecision('${item.id}')">Apply</button>
          <button class="button compact" onclick="cancelInlineDecision()">Cancel</button>
        </div>
      </td>
    </tr>
  `;
}

function renderUsers() {
  return tableView("Users", "Review account status and simulated quick actions.", ["Name", "Company", "Role", "Status", "Plan", "Action"], data.users.map((user) => [
    user.name,
    user.company,
    user.role,
    statusBadge(user.status),
    user.plan,
    `<button class="button" onclick="toast('Simulated action for ${user.name}')">View</button>`
  ]));
}

function renderSubscriptions() {
  return tableView("Subscriptions", "Plan overview, billing state and renewal context.", ["User", "Plan", "Status", "Renewal", "Amount"], data.subscriptions.map((sub) => {
    const user = data.users.find((item) => item.id === sub.userId);
    return [user.name, sub.plan, statusBadge(sub.status), sub.renewal, sub.amount];
  }));
}

function renderReports() {
  return tableView("Reports", "Reported issues that need operator follow-up.", ["Type", "Owner", "Linked", "Severity", "Status"], data.reports.map((report) => [
    report.type,
    report.owner,
    report.linked,
    statusBadge(report.severity),
    statusBadge(report.status)
  ]));
}

function renderContactLog() {
  return tableView("Contact log", "Support and deal-context follow-up in one queue.", ["Subject", "User", "Linked", "Status", "Last activity"], data.contactLog.map((entry) => {
    const user = data.users.find((item) => item.id === entry.userId);
    return [entry.subject, user.name, entry.linked, statusBadge(entry.status), entry.lastActivity];
  }));
}

function renderModeration() {
  return `
    ${viewHead("Moderation", "Flagged content queue with notes and status updates.", "Resolve selected")}
    <div class="grid cols-2">
      ${data.moderationItems.map((item) => `<article class="card">
        <div class="meta-row">${statusBadge(item.severity)}${statusBadge(item.status)}</div>
        <h3>${item.type}</h3>
        <p>${item.note}</p>
        <p class="muted">Linked idea: ${findIdea(item.ideaId).title}</p>
        <div class="action-row">
          <button class="button primary" onclick="toast('Marked ${item.id} as resolved in demo state')">Mark resolved</button>
          <button class="button" onclick="toast('Added moderation note in demo state')">Add note</button>
        </div>
      </article>`).join("")}
    </div>
  `;
}

function tableView(title, description, headers, rows) {
  return `
    ${viewHead(title, description)}
    <div class="table-card">
      <table>
        <thead><tr>${headers.map((head) => `<th>${head}</th>`).join("")}</tr></thead>
        <tbody>${rows.map((row) => `<tr>${row.map((cell) => `<td>${cell}</td>`).join("")}</tr>`).join("")}</tbody>
      </table>
    </div>
  `;
}

function openRequestModal(ideaId) {
  const idea = findIdea(ideaId);
  state.modal = `
    <div class="modal-head">
      <div><h2>Send request</h2><p>${idea.title}</p></div>
      <button class="button ghost" onclick="closeModal()">Close</button>
    </div>
    <div class="field">
      <label>Request intent</label>
      <select id="request-intent">
        <option>Request exclusive review</option>
        <option>Request contact / explore collaboration</option>
        <option>Request licensing discussion</option>
      </select>
    </div>
    <p class="muted">
      This request opens controlled access and negotiation only. The idea owner keeps rights unless a later Deal Room agreement says otherwise.
    </p>
    <div class="field">
      <label>Short message</label>
      <textarea id="request-message" rows="4">We want to explore this opportunity and understand fit for a pilot.</textarea>
    </div>
    <button class="button primary" onclick="submitRequest('${ideaId}')">Submit request</button>
  `;
  renderModal();
}

function submitRequest(ideaId) {
  const intent = document.getElementById("request-intent").value;
  const message = document.getElementById("request-message").value.trim();
  const request = {
    id: `req-${Date.now()}`,
    ideaId,
    patronId: "user-1",
    intent,
    status: "pending",
    message,
    createdAt: "2026-05-07"
  };
  state.requests.push(request);
  state.modal = `
    <div class="modal-head"><div><h2>Request sent</h2><p>The request is now pending approval.</p></div></div>
    <button class="button primary" onclick="closeModal()">Done</button>
  `;
  render();
}

function openOfferModal(mode = "proposal") {
  state.modal = `
    <div class="modal-head">
      <div><h2>${mode === "counter" ? "Send counteroffer" : "Submit proposal"}</h2><p>Demo state updates immediately.</p></div>
      <button class="button ghost" onclick="closeModal()">Close</button>
    </div>
    <div class="field"><label>Deal track</label><select id="offer-type"><option>Partnership</option><option>License discussion</option><option>Assignment discussion</option></select></div>
    <div class="field"><label>Amount NOK</label><input id="offer-amount" type="number" value="58000"></div>
    <div class="field"><label>Note</label><textarea id="offer-note" rows="3">Proposal includes pilot scope, reporting and success criteria.</textarea></div>
    <button class="button primary" onclick="submitOffer('${mode}')">Submit</button>
  `;
  renderModal();
}

function submitOffer(mode) {
  const deal = state.deals.find((item) => item.id === state.selectedDealId);
  const offer = {
    id: `offer-${Date.now()}`,
    dealId: deal.id,
    from: mode === "counter" ? "Idea owner" : "Patron",
    type: document.getElementById("offer-type").value,
    amount: Number(document.getElementById("offer-amount").value),
    currency: "NOK",
    status: "active",
    note: document.getElementById("offer-note").value.trim()
  };
  state.offers.forEach((item) => {
    if (item.dealId === deal.id && item.status === "active") item.status = "countered";
  });
  state.offers.push(offer);
  deal.activeOfferId = offer.id;
  deal.status = mode === "counter" ? "counteroffer received" : "proposal sent";
  deal.history.push({ at: "2026-05-07", text: `${offer.from} submitted ${offer.type.toLowerCase()} proposal` });
  closeModal();
  render();
}

function startInlineDecision(reviewId, status) {
  state.inlineReview = {
    id: reviewId,
    status,
    reason: status === "rejected" ? "Does not meet originality or fit threshold." : "Needs clearer problem, buyer and validation detail."
  };
  render();
}

function submitInlineDecision(reviewId) {
  const reason = document.getElementById(`review-reason-${reviewId}`).value.trim();
  submitDecision(reviewId, state.inlineReview.status, reason);
}

function cancelInlineDecision() {
  state.inlineReview = null;
  render();
}

function submitDecision(reviewId, status, reason = "Approved from queue triage.") {
  state.adminDecisions[reviewId] = { status, reason, at: "2026-05-07" };
  state.inlineReview = null;
  render();
}

function renderModal() {
  const root = document.getElementById("modal-root");
  if (!state.modal) {
    root.innerHTML = "";
    return;
  }
  root.innerHTML = `<div class="modal-backdrop"><div class="modal">${state.modal}</div></div>`;
}

function closeModal() {
  state.modal = null;
  renderModal();
}

function go(hash) {
  location.hash = hash;
}

function setQuery(value) {
  state.query = value;
  render();
}

function setFilter(key, value) {
  state.filters[key] = value;
  render();
}

function clearFilters() {
  state.filters = {
    category: "All",
    status: "All",
    maturity: "All",
    requestState: "All",
    innovatorBackground: "All"
  };
  state.query = "";
  render();
}

function setReviewFilter(status) {
  state.reviewFilter = status;
  render();
}

function toggleFavorite(id) {
  state.favorites.has(id) ? state.favorites.delete(id) : state.favorites.add(id);
  render();
}

function acceptOffer(id) {
  const offer = state.offers.find((item) => item.id === id);
  const deal = state.deals.find((item) => item.id === offer.dealId);
  offer.status = "accepted";
  deal.status = "accepted pending payment";
  deal.history.push({ at: "2026-05-07", text: "Active proposal accepted" });
  render();
}

function filteredIdeas() {
  const query = state.query.toLowerCase();
  return data.ideas.filter((idea) => {
    const matchesQuery = !query || [idea.title, idea.summary, idea.category, ...idea.tags].join(" ").toLowerCase().includes(query);
    const matchesCategory = state.filters.category === "All" || idea.category === state.filters.category;
    const matchesStatus = state.filters.status === "All" || idea.status === state.filters.status;
    const matchesMaturity = state.filters.maturity === "All" || idea.maturity === state.filters.maturity;
    const matchesRequestState = state.filters.requestState === "All" || idea.requestState === state.filters.requestState;
    const matchesBackground = state.filters.innovatorBackground === "All" || idea.innovatorBackground === state.filters.innovatorBackground;
    return matchesQuery && matchesCategory && matchesStatus && matchesMaturity && matchesRequestState && matchesBackground;
  });
}

function renderFilterChips() {
  const chips = [];
  if (state.query) chips.push(`Search: ${state.query}`);
  if (state.filters.category !== "All") chips.push(`Idea category: ${state.filters.category}`);
  if (state.filters.innovatorBackground !== "All") chips.push(`Background: ${state.filters.innovatorBackground}`);
  if (state.filters.status !== "All") chips.push(`Status: ${state.filters.status}`);
  if (state.filters.maturity !== "All") chips.push(`Maturity: ${state.filters.maturity}`);
  if (state.filters.requestState !== "All") chips.push(`Request state: ${state.filters.requestState}`);
  return chips.length ? `<div class="chips">${chips.map((chip) => `<button class="chip" onclick="clearFilters()">${chip} x</button>`).join("")}</div>` : `<div class="chips"><span class="muted">Showing all accessible opportunities</span></div>`;
}

function uniqueIdeaValues(key) {
  return [...new Set(data.ideas.map((idea) => idea[key]).filter(Boolean))];
}

function selectField(label, key, options, value, handler) {
  return `
    <div class="field">
      <label>${label}</label>
      <select onchange="${handler}('${key}', this.value)">
        ${options.map((option) => `<option value="${option}" ${option === value ? "selected" : ""}>${option}</option>`).join("")}
      </select>
    </div>
  `;
}

function viewHead(title, description, actionLabel = "", action = "") {
  return `
    <div class="view-head">
      <div><div class="eyebrow">${state.role} view</div><h1>${title}</h1><p>${description}</p></div>
      ${actionLabel ? `<button class="button primary" onclick="${action || "toast('Demo action')"}">${actionLabel}</button>` : ""}
    </div>
  `;
}

function statusBadge(status) {
  const normalized = String(status).toLowerCase();
  let className = "";
  if (["active", "approved", "accepted", "low"].includes(normalized)) className = "success";
  if (["pending", "under review", "in negotiation", "pending request", "proposal sent", "counteroffer received", "medium", "investigating", "waiting", "needs follow-up", "returned"].includes(normalized)) className = "pending";
  if (["rejected", "flagged", "past due", "high"].includes(normalized)) className = "danger";
  return `<span class="badge ${className}">${status}</span>`;
}

function favoriteButton(id, mode = "icon") {
  const active = state.favorites.has(id);
  return `<button class="favorite ${active ? "active" : ""}" onclick="toggleFavorite('${id}')">${mode === "full" ? (active ? "Saved" : "Save") : (active ? "Saved" : "Save")}</button>`;
}

function navCount(label) {
  if (label === "Favorites") return `<span class="nav-count">${state.favorites.size}</span>`;
  if (label === "Review queue") return `<span class="nav-count">${data.reviewItems.filter((item) => effectiveReviewStatus(item) === "under review").length}</span>`;
  if (label === "Moderation") return `<span class="nav-count">${data.moderationItems.length}</span>`;
  return "";
}

function effectiveReviewStatus(item) {
  return state.adminDecisions[item.id]?.status || item.status;
}

function stat(label, value) {
  return `<article class="card stat"><strong>${value}</strong><p>${label}</p></article>`;
}

function emptyState(text) {
  return `<div class="empty">${text}</div>`;
}

function isActive(href) {
  if (href.includes("/deals") && state.route.includes("/deals")) return true;
  return state.route === href;
}

function findIdea(id) {
  return data.ideas.find((idea) => idea.id === id);
}

function formatMoney(amount, currency) {
  return `${new Intl.NumberFormat("nb-NO").format(amount)} ${currency}`;
}

function toast(message) {
  state.modal = `<div class="modal-head"><div><h2>Demo action</h2><p>${message}</p></div></div><button class="button primary" onclick="closeModal()">OK</button>`;
  renderModal();
}

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (char) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    "\"": "&quot;",
    "'": "&#039;"
  }[char]));
}
