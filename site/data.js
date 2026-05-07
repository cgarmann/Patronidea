window.FRUMA_DATA = {
  categories: [
    "Healthtech",
    "Energy",
    "Logistics",
    "Operations",
    "Fintech",
    "Education",
    "Sustainability"
  ],
  ideas: [
    {
      id: "idea-101",
      title: "Micro-learning for night-shift nurses",
      category: "Healthtech",
      tags: ["B2B", "Workflow", "Training"],
      status: "active",
      maturity: "Prototype-ready",
      source: "Verified healthcare operator",
      submittedAt: "2026-05-01",
      updatedAt: "2026-05-05",
      summary: "Short training prompts delivered during low-load clinical windows.",
      problem: "Clinical teams need continuous training, but night-shift schedules rarely leave room for traditional courses.",
      value: "Turns idle micro-moments into measurable learning without pulling nurses away from patient care.",
      requestCount: 8
    },
    {
      id: "idea-102",
      title: "Solar quote verifier for housing associations",
      category: "Energy",
      tags: ["B2B", "Procurement", "Benchmarking"],
      status: "active",
      maturity: "Validated concept",
      source: "Anonymous energy advisor",
      submittedAt: "2026-04-28",
      updatedAt: "2026-05-03",
      summary: "Checks vendor estimates against local benchmarks and payback models.",
      problem: "Housing associations struggle to compare solar offers because vendors format assumptions differently.",
      value: "Creates a normalized decision layer before the board approves procurement.",
      requestCount: 11
    },
    {
      id: "idea-103",
      title: "Deposit layer for reusable delivery packaging",
      category: "Logistics",
      tags: ["Circular", "Local commerce", "Payments"],
      status: "in negotiation",
      maturity: "Pilot candidate",
      source: "Operations founder",
      submittedAt: "2026-04-22",
      updatedAt: "2026-05-06",
      summary: "Tracks return incentives for local food delivery operators.",
      problem: "Restaurants want reusable packaging, but return behavior is hard to coordinate across delivery networks.",
      value: "A deposit ledger reduces packaging loss and gives customers a clear reason to return containers.",
      requestCount: 5
    },
    {
      id: "idea-104",
      title: "Cash-flow cockpit for small contractors",
      category: "Operations",
      tags: ["SMB", "Risk", "Finance"],
      status: "active",
      maturity: "MVP-specified",
      source: "Construction operator",
      submittedAt: "2026-04-18",
      updatedAt: "2026-05-02",
      summary: "Highlights payment risk before staffing and material commitments.",
      problem: "Small contractors commit labor and materials before they see the cash impact of delayed invoices.",
      value: "Gives owners a weekly risk view and suggested actions before cash gaps become critical.",
      requestCount: 9
    },
    {
      id: "idea-105",
      title: "Inventory alerts for independent pharmacies",
      category: "Healthtech",
      tags: ["Retail", "Automation", "Compliance"],
      status: "pending request",
      maturity: "Research-backed",
      source: "Pharmacy technician",
      submittedAt: "2026-04-14",
      updatedAt: "2026-04-30",
      summary: "Detects reorder risk across slow-moving but critical medicines.",
      problem: "Independent pharmacies lose time manually reviewing low-volume products with high customer impact.",
      value: "Prioritizes attention and reduces stockouts without replacing existing pharmacy systems.",
      requestCount: 3
    },
    {
      id: "idea-106",
      title: "AI assistant for industrial maintenance logs",
      category: "Operations",
      tags: ["Industrial", "AI", "Maintenance"],
      status: "active",
      maturity: "Technical brief",
      source: "Plant maintenance lead",
      submittedAt: "2026-04-09",
      updatedAt: "2026-05-01",
      summary: "Summarizes maintenance patterns before equipment downtime escalates.",
      problem: "Important warning signs are buried in unstructured maintenance notes.",
      value: "Helps teams spot recurring faults and plan service before costly stoppages.",
      requestCount: 6
    }
  ],
  users: [
    { id: "user-1", name: "Maja Lund", company: "Northline Ventures", role: "Patron", status: "active", plan: "Pro" },
    { id: "user-2", name: "Jonas Berg", company: "Fjord Capital", role: "Patron", status: "active", plan: "Enterprise" },
    { id: "user-3", name: "Sara Myhre", company: "Admin", role: "Admin", status: "active", plan: "Internal" },
    { id: "user-4", name: "Eirik Dahl", company: "Nordic Build", role: "Patron", status: "flagged", plan: "Basic" },
    { id: "user-5", name: "Klara Solheim", company: "Helix Labs", role: "Patron", status: "trial", plan: "Pro" }
  ],
  subscriptions: [
    { id: "sub-1", userId: "user-1", plan: "Pro", status: "active", renewal: "2026-06-07", amount: "399 kr/month" },
    { id: "sub-2", userId: "user-2", plan: "Enterprise", status: "active", renewal: "Custom", amount: "Custom" },
    { id: "sub-3", userId: "user-4", plan: "Basic", status: "past due", renewal: "2026-05-10", amount: "149 kr/month" },
    { id: "sub-4", userId: "user-5", plan: "Pro", status: "trial", renewal: "2026-05-21", amount: "299 kr/month" }
  ],
  requests: [
    { id: "req-201", ideaId: "idea-103", patronId: "user-1", intent: "Partnership", status: "approved", message: "We want to explore a pilot with regional restaurants.", createdAt: "2026-05-04" },
    { id: "req-202", ideaId: "idea-105", patronId: "user-2", intent: "License", status: "pending", message: "Interested in evaluating fit for pharmacy groups.", createdAt: "2026-05-06" }
  ],
  deals: [
    {
      id: "deal-301",
      ideaId: "idea-103",
      requestId: "req-201",
      patronId: "user-1",
      status: "in negotiation",
      activeOfferId: "offer-401",
      messages: [
        { from: "Patron", at: "2026-05-05 09:12", text: "We can start with a 6-week pilot in Oslo." },
        { from: "Idea owner", at: "2026-05-05 13:48", text: "Pilot works. We need clear packaging loss targets." }
      ],
      history: [
        { at: "2026-05-04", text: "Request approved" },
        { at: "2026-05-05", text: "Deal Room opened" },
        { at: "2026-05-06", text: "Counteroffer received" }
      ]
    },
    {
      id: "deal-302",
      ideaId: "idea-102",
      requestId: "req-203",
      patronId: "user-2",
      status: "pending proposal",
      activeOfferId: null,
      messages: [{ from: "Admin note", at: "2026-05-06 15:20", text: "Waiting for patron proposal." }],
      history: [{ at: "2026-05-06", text: "Deal Room opened" }]
    }
  ],
  offers: [
    { id: "offer-400", dealId: "deal-301", from: "Patron", type: "Partnership", amount: 45000, currency: "NOK", status: "countered", note: "Pilot fee plus success bonus." },
    { id: "offer-401", dealId: "deal-301", from: "Idea owner", type: "Partnership", amount: 62000, currency: "NOK", status: "active", note: "Higher pilot fee, lower success bonus." }
  ],
  reviewItems: [
    { id: "rev-501", ideaId: "idea-106", status: "under review", category: "Operations", submittedAt: "2026-05-06", risk: "low", score: 78 },
    { id: "rev-502", ideaId: "idea-105", status: "under review", category: "Healthtech", submittedAt: "2026-05-05", risk: "medium", score: 72 },
    { id: "rev-503", ideaId: "idea-102", status: "approved", category: "Energy", submittedAt: "2026-04-28", risk: "low", score: 91 }
  ],
  moderationItems: [
    { id: "mod-601", type: "Duplicate concern", ideaId: "idea-105", severity: "medium", status: "open", note: "Similar pharmacy inventory concept reported by user." },
    { id: "mod-602", type: "External link", ideaId: "idea-106", severity: "low", status: "open", note: "Source included vendor link in description." }
  ],
  reports: [
    { id: "rep-701", type: "Payment question", status: "open", severity: "low", linked: "deal-301", owner: "Maja Lund" },
    { id: "rep-702", type: "Duplicate report", status: "investigating", severity: "medium", linked: "idea-105", owner: "Jonas Berg" },
    { id: "rep-703", type: "Contact concern", status: "closed", severity: "low", linked: "req-202", owner: "Admin" }
  ],
  contactLog: [
    { id: "log-801", userId: "user-1", linked: "deal-301", status: "needs follow-up", subject: "Pilot scope clarification", lastActivity: "2026-05-06" },
    { id: "log-802", userId: "user-2", linked: "req-202", status: "waiting", subject: "License request pending", lastActivity: "2026-05-06" },
    { id: "log-803", userId: "user-4", linked: "sub-3", status: "billing", subject: "Past due subscription", lastActivity: "2026-05-04" }
  ]
};
