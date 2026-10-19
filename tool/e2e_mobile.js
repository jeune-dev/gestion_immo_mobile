'use strict';
// Rejoue les appels de l'app mobile (mêmes chemins, mêmes corps) contre une API locale
// sur une base de TEST (il crée des comptes et des données).
// Usage : NODE_PATH=<backend>/node_modules node tool/e2e_mobile.js   (API=http://… pour une autre adresse)
// Préalable pour le contrat PDF : un modèle de bail publié par le super admin (sinon 409 accepté).
const crypto = require('crypto');
const sharp = require('sharp');

const j = (x) => String(JSON.stringify(x));
const BASE = process.env.API || 'http://127.0.0.1:5010/api/v1';
const resultats = [];
let echecs = 0;

const uuid = () => crypto.randomUUID();
const jour = (decalage = 0) => new Date(Date.now() + decalage * 86400000).toISOString().slice(0, 10);

class Client {
  constructor(nom) { this.nom = nom; this.access = null; this.refresh = null; }
  async appel(methode, chemin, { body, query, idem, form, brut } = {}) {
    const url = new URL(BASE + chemin);
    for (const [k, v] of Object.entries(query || {})) if (v !== undefined && v !== null && v !== '') url.searchParams.set(k, String(v));
    // Pas d'en-tête Origin : comme le mobile, le refresh token arrive dans le corps.
    const headers = { Accept: 'application/json' };
    if (this.access) headers.Authorization = `Bearer ${this.access}`;
    if (idem) headers['Idempotency-Key'] = idem;
    let corps;
    if (form) {
      const fd = new FormData();
      for (const [k, v] of Object.entries(form.champs || {})) if (v !== null && v !== undefined) fd.append(k, String(v));
      if (form.fichier) fd.append('fichier', new Blob([form.fichier], { type: form.type || 'image/png' }), form.nom || 'photo.png');
      corps = fd;
    } else if (methode !== 'GET') {
      headers['Content-Type'] = 'application/json';
      corps = j(body ?? {});
    }
    const r = await fetch(url, { method: methode, headers, body: corps });
    if (brut) return { status: r.status, octets: Buffer.from(await r.arrayBuffer()), type: r.headers.get('content-type'), retry: r.headers.get('retry-after') };
    const texte = await r.text();
    let json; try { json = JSON.parse(texte); } catch { json = texte; }
    return { status: r.status, json, data: json?.data };
  }
}

async function etape(libelle, fn, attendu = [200, 201]) {
  try {
    const r = await fn();
    const ok = attendu.includes(r.status);
    if (!ok) echecs++;
    const detail = ok ? '' : ` → ${r.status} ${j(r.json?.error || r.json).slice(0, 300)}`;
    resultats.push(`${ok ? 'OK  ' : 'ÉCHEC'} ${libelle}${detail}`);
    return r;
  } catch (e) {
    echecs++;
    resultats.push(`ÉCHEC ${libelle} → exception ${e.message}`);
    return { status: 0 };
  }
}

function verifier(libelle, condition, info = '') {
  if (!condition) echecs++;
  resultats.push(`${condition ? 'OK  ' : 'ÉCHEC'} ${libelle}${condition ? '' : ' ' + info}`);
}

async function pdf(client, libelle, chemin) {
  for (let i = 0; i < 4; i++) {
    const r = await client.appel('GET', chemin, { brut: true });
    if (r.status === 503) { await new Promise((ok) => setTimeout(ok, 1000 * Number(r.retry || 2))); continue; }
    verifier(libelle, r.status === 200 && r.octets.slice(0, 4).toString() === '%PDF', `→ ${r.status} ${r.type}`);
    return;
  }
  verifier(libelle, false, '→ 503 persistant');
}

(async () => {
  const image = await sharp({ create: { width: 64, height: 64, channels: 3, background: { r: 200, g: 120, b: 40 } } }).png().toBuffer();
  const suffixe = String(Date.now()).slice(-6);
  const mdp = 'Demo2026Immo';
  const p = new Client('propriétaire');

  // ── Authentification (session_cubit.dart) ──────────────────────────────────
  const insc = await etape('POST /auth/inscription', () => p.appel('POST', '/auth/inscription', {
    body: { first_name: 'Awa', last_name: 'Ndiaye', phone: `77 9${suffixe.slice(0, 2)} ${suffixe.slice(2, 4)} ${suffixe.slice(4)}`, email: `awa.${suffixe}@demo.sn`, city: 'Dakar', password: mdp, password_confirmation: mdp },
  }));
  p.access = insc.data?.access_token; p.refresh = insc.data?.refresh_token;
  verifier('inscription : refresh_token dans le corps (client mobile)', Boolean(p.refresh));
  const compte = await etape('GET /compte', () => p.appel('GET', '/compte'));
  verifier('compte : user.role_code, owner, abonnement.actif', compte.data?.user?.role_code === 'proprietaire' && compte.data?.owner && compte.data?.abonnement?.actif === true,
    j(compte.data?.abonnement));
  const con = await etape('POST /auth/connexion', () => new Client().appel('POST', '/auth/connexion', {
    body: { identifiant: `awa.${suffixe}@demo.sn`, password: mdp, device_name: 'Application mobile', platform: 'ios' },
  }));
  const ref = await etape('POST /auth/refresh (corps)', () => new Client().appel('POST', '/auth/refresh', { body: { refresh_token: con.data?.refresh_token } }));
  verifier('refresh : nouveaux jetons', Boolean(ref.data?.access_token && ref.data?.refresh_token));
  await etape('GET /referentiels', () => p.appel('GET', '/referentiels'));

  // ── Patrimoine (formulaires.dart) ──────────────────────────────────────────
  const imm = await etape('POST /immeubles', () => p.appel('POST', '/immeubles', {
    body: { name: 'Résidence Almadies', address: 'Route des Almadies', district: 'Ngor', city: 'Dakar', floors_count: 3, declared_apartments_count: 6, description: null },
  }));
  const immId = imm.data?.building?.id;
  await etape('GET /immeubles (tri name)', () => p.appel('GET', '/immeubles', { query: { page: 1, tri: 'name' } }));
  await etape('PATCH /immeubles/:id', () => p.appel('PATCH', `/immeubles/${immId}`, { body: { name: 'Résidence Almadies', address: 'Route des Almadies', district: 'Ngor', city: 'Dakar', floors_count: 4, declared_apartments_count: 6 } }));
  await etape('GET /immeubles/:id', () => p.appel('GET', `/immeubles/${immId}`));
  const corpsApp = (n) => ({ building_id: immId, number: n, type: 'f3', floor: 1, rent_amount: 250000, charges_amount: 0, surface: 75.5, rooms_count: 3, charge_coefficient: 1, is_furnished: false });
  const a1 = await etape('POST /appartements (A1)', () => p.appel('POST', '/appartements', { body: corpsApp('A1') }));
  const a2 = await etape('POST /appartements (A2)', () => p.appel('POST', '/appartements', { body: corpsApp('A2') }));
  const a3 = await etape('POST /appartements (A3)', () => p.appel('POST', '/appartements', { body: corpsApp('A3') }));
  const [app1, app2, app3] = [a1, a2, a3].map((r) => r.data?.apartment?.id);
  await etape('GET /appartements (filtre, tri number)', () => p.appel('GET', '/appartements', { query: { page: 1, status: 'disponible', tri: 'number', building_id: immId } }));
  await etape('PATCH /appartements/:id/statut', () => p.appel('PATCH', `/appartements/${app3}/statut`, { body: { status: 'en_travaux' } }));
  await etape('PATCH /appartements/:id', () => p.appel('PATCH', `/appartements/${app3}`, { body: { number: 'A3', type: 'f2', rent_amount: 200000, charges_amount: 10000, is_furnished: true } }));

  const loc = await etape('POST /locataires (+ invitation)', () => p.appel('POST', '/locataires', {
    idem: uuid(),
    body: { first_name: 'Moussa', last_name: 'Diallo', phone: `78 4${suffixe.slice(0, 2)} ${suffixe.slice(2, 4)} ${suffixe.slice(4)}`, email: null, id_document_type: 'cni', id_document_number: '1234567890123', whatsapp_consent: true, send_invitation: true },
  }));
  const tenantId = loc.data?.tenant?.id;
  const invitation = loc.data?.invitation;
  verifier("création locataire : code d'invitation à 8 chiffres", /^\d{8}$/.test(invitation?.code || ''), j(invitation));
  await etape('GET /locataires (tri last_name)', () => p.appel('GET', '/locataires', { query: { page: 1, tri: 'last_name' } }));
  const fiche = await etape('GET /locataires/:id', () => p.appel('GET', `/locataires/${tenantId}`));
  verifier('fiche locataire : balance, leases, pending_invitation', fiche.data?.tenant && 'balance' in fiche.data.tenant && 'pending_invitation' in fiche.data.tenant, Object.keys(fiche.data?.tenant || {}).join(','));
  await etape('PATCH /locataires/:id', () => p.appel('PATCH', `/locataires/${tenantId}`, { body: { first_name: 'Moussa', last_name: 'Diallo', notes: 'Bon payeur' } }));

  const corpsBail = (app) => ({ apartment_id: app, tenant_id: tenantId, lease_type: 'habitation', start_date: jour(-40), periodicity: 'mensuel', due_day: 5, deposit_amount: 500000, occupants_count: 2, notice_period_months: 1 });
  const b1 = await etape('POST /baux', () => p.appel('POST', '/baux', { idem: uuid(), body: corpsBail(app1) }));
  const bail1 = b1.data?.lease?.id;
  await etape('PATCH /baux/:id (brouillon)', () => p.appel('PATCH', `/baux/${bail1}`, { body: { ...corpsBail(app1), apartment_id: undefined, tenant_id: undefined, special_conditions: 'Animaux interdits' } }));
  // ── État des lieux (gestion des pièces/éléments/photos ajoutée) ───────────
  const edl = await etape('POST /etats-des-lieux', () => p.appel('POST', '/etats-des-lieux', { idem: uuid(), body: { lease_id: bail1, type: 'entree', performed_at: jour(), client_reference: `edl-${uuid()}` } }));
  const edlId = edl.data?.inspection?.id;
  let det = await etape('GET /etats-des-lieux/:id', () => p.appel('GET', `/etats-des-lieux/${edlId}`));
  await etape('PATCH /etats-des-lieux/:id (relevés)', () => p.appel('PATCH', `/etats-des-lieux/${edlId}`, { body: { water_meter: 12.5, electricity_meter: 3400, keys_count: 3, keys_details: '2 portes, 1 boîte', general_observations: 'Bon état général' } }));
  const pc = await etape('POST /etats-des-lieux/:id/pieces', () => p.appel('POST', `/etats-des-lieux/${edlId}/pieces`, {
    body: { name: 'Chambre 2', items: ['murs', 'sols', 'plafond', 'portes', 'fenetres', 'electricite'].map((element) => ({ element })) },
  }));
  const piece = pc.data?.room;
  await etape('PATCH /etats-des-lieux/:id/pieces/:roomId (renommer)', () => p.appel('PATCH', `/etats-des-lieux/${edlId}/pieces/${piece?.id}`, { body: { name: 'Chambre parentale' } }));
  const el = await etape('POST …/pieces/:roomId/elements', () => p.appel('POST', `/etats-des-lieux/${edlId}/pieces/${piece?.id}/elements`, { body: { element: 'mobilier', label: 'Placard mural' } }));
  const item = el.data?.item;
  await etape('PATCH …/elements/:itemId (précision)', () => p.appel('PATCH', `/etats-des-lieux/${edlId}/elements/${item?.id}`, { body: { label: 'Placard 3 portes' } }));
  await etape('PATCH …/elements/:itemId (précision effacée)', () => p.appel('PATCH', `/etats-des-lieux/${edlId}/elements/${item?.id}`, { body: { label: null } }));
  await etape('POST …/elements/:itemId/photos', () => p.appel('POST', `/etats-des-lieux/${edlId}/elements/${item?.id}/photos`, { idem: uuid(), form: { fichier: image, champs: { captured_at: new Date().toISOString() } } }));
  det = await etape('GET /etats-des-lieux/:id (après ajouts)', () => p.appel('GET', `/etats-des-lieux/${edlId}`));
  const rooms = det.data?.inspection?.rooms || [];
  const elementAvecPhoto = rooms.flatMap((r) => r.items || []).find((i) => i.id === item?.id);
  verifier('EDL : pièce renommée et photo rattachée (items[].photos[].id)', rooms.some((r) => r.name === 'Chambre parentale') && elementAvecPhoto?.photos?.[0]?.id);
  await etape('DELETE …/photos/:photoId', () => p.appel('DELETE', `/etats-des-lieux/${edlId}/photos/${elementAvecPhoto?.photos?.[0]?.id}`));
  await etape('DELETE …/elements/:itemId', () => p.appel('DELETE', `/etats-des-lieux/${edlId}/elements/${item?.id}`));
  await etape('DELETE …/pieces/:roomId', () => p.appel('DELETE', `/etats-des-lieux/${edlId}/pieces/${piece?.id}`));
  det = await etape('GET /etats-des-lieux/:id (avant saisie)', () => p.appel('GET', `/etats-des-lieux/${edlId}`));
  const tous = (det.data?.inspection?.rooms || []).flatMap((r) => r.items || []);
  await etape('PUT /etats-des-lieux/:id/saisie', () => p.appel('PUT', `/etats-des-lieux/${edlId}/saisie`, { body: { items: tous.map((i) => ({ item_id: i.id, condition: 'bon', comment: null })) } }));
  await etape('POST /etats-des-lieux/:id/soumettre', () => p.appel('POST', `/etats-des-lieux/${edlId}/soumettre`));
  await pdf(p, 'GET /etats-des-lieux/:id/pdf', `/etats-des-lieux/${edlId}/pdf`);
  await etape('GET /etats-des-lieux (tri -created_at)', () => p.appel('GET', '/etats-des-lieux', { query: { page: 1, tri: '-created_at' } }));

  const act = await etape('POST /baux/:id/activer', () => p.appel('POST', `/baux/${bail1}/activer`));
  verifier('activation : avertissements est une liste', Array.isArray(act.data?.avertissements), j(act.data).slice(0, 200));
  await etape('GET /baux/:id', () => p.appel('GET', `/baux/${bail1}`));
  await etape('GET /baux (status actif, tri -start_date)', () => p.appel('GET', '/baux', { query: { page: 1, status: 'actif', tri: '-start_date' } }));
  const contrat = await etape('POST /baux/:id/contrats (201, ou 409 si aucun modèle publié par le super admin)', () => p.appel('POST', `/baux/${bail1}/contrats`, { idem: uuid(), body: { special_clauses: 'Peinture à refaire à la sortie' } }), [201, 409]);
  const contrats = await etape('GET /baux/:id/contrats', () => p.appel('GET', `/baux/${bail1}/contrats`));
  const docContrat = contrats.data?.contracts?.[0]?.document_id;
  if (docContrat) await pdf(p, 'GET /documents/:id/fichier (contrat PDF)', `/documents/${docContrat}/fichier`);
  else resultats.push(`INFO contrat non généré : ${contrat.json?.error?.code}`);
  await etape('POST /baux/:id/loyer (révision)', () => p.appel('POST', `/baux/${bail1}/loyer`, { body: { rent_amount: 260000, charges_amount: 0, effective_from: jour(30) } }));
  await etape('GET /appartements/:id', () => p.appel('GET', `/appartements/${app1}`));
  await etape('GET /appartements/:id/rentabilite', () => p.appel('GET', `/appartements/${app1}/rentabilite`, { query: { du: `${jour().slice(0, 4)}-01-01`, au: `${jour().slice(0, 4)}-12-31` } }));
  await etape('GET /appartements/:id/historique', () => p.appel('GET', `/appartements/${app1}/historique`, { query: { limit: 15 } }));

  // ── Loyers et paiements ────────────────────────────────────────────────────
  const imp = await etape('GET /echeances (impayés)', () => p.appel('GET', '/echeances', { query: { page: 1, lease_id: bail1, impayes: true, tri: 'due_date' } }));
  await etape('GET /echeances (statut, -due_date)', () => p.appel('GET', '/echeances', { query: { page: 1, status: 'a_venir', tri: '-due_date' } }));
  const echeance = imp.data?.items?.[0];
  verifier('au moins une échéance impayée après activation', Boolean(echeance), j(imp.data?.pagination));
  const enc = await etape('POST /paiements/especes', () => p.appel('POST', '/paiements/especes', {
    idem: uuid(), body: { lease_id: bail1, rent_schedule_id: echeance?.id, amount: echeance ? echeance.amount_due - echeance.amount_paid : 1000, method: 'especes', paid_on: jour(), reference: 'REC-001', comment: null },
  }));
  const paiementId = enc.data?.payment?.id;
  verifier('encaissement : payment.id renvoyé', Boolean(paiementId), j(enc.data).slice(0, 200));
  await etape('GET /paiements (tri -paid_on)', () => p.appel('GET', '/paiements', { query: { page: 1, method: 'especes', tri: '-paid_on' } }));
  await etape('GET /paiements/:id', () => p.appel('GET', `/paiements/${paiementId}`));
  const qs = await etape('GET /paiements/:id/quittances', () => p.appel('GET', `/paiements/${paiementId}/quittances`));
  await etape('GET /quittances (tri -issued_at)', () => p.appel('GET', '/quittances', { query: { page: 1, tri: '-issued_at' } }));
  const quittanceId = qs.data?.receipts?.[0]?.id;
  if (quittanceId) await pdf(p, 'GET /quittances/:id/pdf', `/quittances/${quittanceId}/pdf`);
  else verifier('quittance générée', false);

  // ── Moyens de paiement (profil_screen.dart, correctif « clés vides ») ──────
  await etape('PUT /paiements/moyens (Wave, preuve)', () => p.appel('PUT', '/paiements/moyens', { body: { provider: 'wave', mode: 'preuve', label: 'Wave perso', account_number: '77 123 45 67', is_active: true } }));
  const cleTest = 'test_private_' + 'x'.repeat(20);
  await etape('PUT /paiements/moyens (PayDunya intégré, clés test)', () => p.appel('PUT', '/paiements/moyens', {
    body: { provider: 'paydunya', mode: 'integre', label: 'PayDunya', is_active: false, credentials: { master_key: 'master_key_12345', private_key: cleTest, token: 'token_123456789', mode: 'test' } },
  }));
  await etape('PUT /paiements/moyens (modif. PayDunya sans ressaisir les clés)', () => p.appel('PUT', '/paiements/moyens', { body: { provider: 'paydunya', mode: 'integre', label: 'PayDunya Business', is_active: false } }));
  const moyens = await etape('GET /paiements/moyens', () => p.appel('GET', '/paiements/moyens'));
  verifier('moyens : PayDunya renommé, clés conservées sans être renvoyées',
    moyens.data?.providers?.some((m) => m.provider === 'paydunya' && m.label === 'PayDunya Business') && !j(moyens.data).includes(cleTest));

  // ── Cautions ───────────────────────────────────────────────────────────────
  const cautions = await etape('GET /cautions', () => p.appel('GET', '/cautions', { query: { page: 1, tri: '-created_at' } }));
  const cautionId = cautions.data?.items?.[0]?.id;
  await etape('POST /cautions/:id/versements', () => p.appel('POST', `/cautions/${cautionId}/versements`, { idem: uuid(), body: { amount: 500000, method: 'wave', occurred_on: jour(), reference: 'WV-123' } }));
  await etape('GET /cautions/:id', () => p.appel('GET', `/cautions/${cautionId}`));
  await etape('POST /cautions/:id/justificatifs', () => p.appel('POST', `/cautions/${cautionId}/justificatifs`, { idem: uuid(), form: { fichier: image } }));

  // ── Dépenses (+ modification ajoutée) ──────────────────────────────────────
  const cats = await etape('GET /categories-depenses', () => p.appel('GET', '/categories-depenses'));
  const [cat1, cat2] = cats.data?.categories || [];
  await etape('GET /categories-depenses (inactives)', () => p.appel('GET', '/categories-depenses', { query: { inclure_inactives: true } }));
  const cat = await etape('POST /categories-depenses', () => p.appel('POST', '/categories-depenses', { body: { name: 'Jardinage', cash_group: 'entretien' } }));
  await etape('PATCH /categories-depenses/:id', () => p.appel('PATCH', `/categories-depenses/${cat.data?.category?.id}`, { body: { name: 'Jardin', cash_group: 'entretien' } }));
  const dep = await etape('POST /depenses (file hors ligne)', () => p.appel('POST', '/depenses', {
    idem: uuid(), body: { building_id: immId, category_id: cat1?.id, amount: 45000, method: 'especes', spent_on: jour(), description: 'Ampoules', client_reference: `dep-${uuid()}` },
  }));
  const depId = dep.data?.expense?.id;
  const listeDep = await etape('GET /depenses (tri -spent_on)', () => p.appel('GET', '/depenses', { query: { page: 1, status: 'valide', tri: '-spent_on' } }));
  const d0 = listeDep.data?.items?.find((d) => d.id === depId) || {};
  verifier('liste dépenses : champs lus par « Modifier » (category, building_id, apartment_id, contractor_id)',
    d0.category && 'building_id' in d0 && 'apartment_id' in d0 && 'contractor_id' in d0, Object.keys(d0).join(','));
  await etape('PATCH /depenses/:id (corps du formulaire mobile)', () => p.appel('PATCH', `/depenses/${depId}`, { body: { category_id: cat2?.id, apartment_id: app1, contractor_id: null, description: 'Ampoules LED' } }));
  await etape('POST /depenses/:id/justificatifs', () => p.appel('POST', `/depenses/${depId}/justificatifs`, { form: { fichier: image } }));

  // ── Caisse ─────────────────────────────────────────────────────────────────
  await etape('POST /caisse/autres-revenus', () => p.appel('POST', '/caisse/autres-revenus', { idem: uuid(), body: { label: 'Location terrasse', amount: 20000, method: 'especes', occurred_on: jour(), building_id: immId } }));
  await etape('GET /caisse/synthese', () => p.appel('GET', '/caisse/synthese', { query: { du: jour(-30), au: jour() } }));
  await etape('GET /caisse', () => p.appel('GET', '/caisse', { query: { page: 1, du: jour(-30), au: jour() } }));

  // ── Factures communes (+ modification et « à répartir ») ──────────────────
  const fac = await etape('POST /factures-communes', () => p.appel('POST', '/factures-communes', {
    idem: uuid(), body: { building_id: immId, charge_type: 'electricite', supplier: 'SENELEC', amount: 60000, period_start: jour(-30), period_end: jour(-1), allocation_method: 'consommation', recharge_to_tenants: true },
  }));
  const facId = fac.data?.invoice?.id;
  const ar = await etape('GET /factures-communes/a-repartir', () => p.appel('GET', '/factures-communes/a-repartir'));
  verifier('à répartir : count et total_amount (bandeau)', ar.data?.count >= 1 && ar.data?.total_amount !== undefined, j(ar.data).slice(0, 150));
  const facDet = await etape('GET /factures-communes/:id', () => p.appel('GET', `/factures-communes/${facId}`));
  const f = facDet.data?.invoice || {};
  // Formulaire de modification : tous les champs affichés, valeurs initiales de la fiche
  await etape('PATCH /factures-communes/:id (corps du formulaire mobile)', () => p.appel('PATCH', `/factures-communes/${facId}`, {
    body: { building_id: f.building_id, charge_type: f.charge_type, supplier: 'SENELEC SA', invoice_number: 'F-2026-01', amount: 66000, period_start: String(f.period_start).slice(0, 10), period_end: String(f.period_end).slice(0, 10), due_date: null, allocation_method: f.allocation_method, recharge_to_tenants: true },
  }));
  const lignes = { lines: [{ apartment_id: app1, consumption: 120 }, { apartment_id: app2, consumption: 80 }], unit: 'kWh' };
  await etape('POST /factures-communes/:id/apercu', () => p.appel('POST', `/factures-communes/${facId}/apercu`, { body: lignes }));
  await etape('POST /factures-communes/:id/apercu (unité omise)', () => p.appel('POST', `/factures-communes/${facId}/apercu`, { body: { lines: lignes.lines } }));
  await etape('POST /factures-communes/:id/repartir', () => p.appel('POST', `/factures-communes/${facId}/repartir`, { body: lignes }));
  await etape('GET /factures-communes (tri -period_start)', () => p.appel('GET', '/factures-communes', { query: { page: 1, tri: '-period_start' } }));
  await etape('GET /charges (tri -due_date)', () => p.appel('GET', '/charges', { query: { page: 1, tri: '-due_date' } }));

  // ── Artisans, travaux (+ retrait de photo), incidents ─────────────────────
  const art = await etape('POST /artisans', () => p.appel('POST', '/artisans', { idem: uuid(), body: { name: 'Ibrahima Plomberie', trade: 'plombier', phone: '76 555 44 33' } }));
  const artId = art.data?.contractor?.id;
  await etape('GET /artisans (tri name)', () => p.appel('GET', '/artisans', { query: { page: 1, tri: 'name' } }));
  await etape('GET /artisans (is_active)', () => p.appel('GET', '/artisans', { query: { is_active: true } }));
  await etape('POST /artisans/:id/desactiver', () => p.appel('POST', `/artisans/${artId}/desactiver`));
  await etape('POST /artisans/:id/reactiver', () => p.appel('POST', `/artisans/${artId}/reactiver`));
  const tr = await etape('POST /travaux', () => p.appel('POST', '/travaux', {
    idem: uuid(), body: { building_id: immId, title: 'Fuite salle de bain', category: 'plomberie', priority: 'haute', apartment_id: app1, estimated_amount: 30000, contractor_id: artId, scheduled_for: jour(2) },
  }));
  const trId = tr.data?.work_order?.id;
  await etape('POST /travaux/:id/statut (valide)', () => p.appel('POST', `/travaux/${trId}/statut`, { body: { status: 'valide' } }));
  await etape('POST /travaux/:id/statut (artisan_assigne)', () => p.appel('POST', `/travaux/${trId}/statut`, { body: { contractor_id: artId, status: 'artisan_assigne' } }));
  const ph = await etape('POST /travaux/:id/photos', () => p.appel('POST', `/travaux/${trId}/photos`, { idem: uuid(), form: { fichier: image, champs: { phase: 'avant', captured_at: new Date().toISOString() } } }));
  const detTr = await etape('GET /travaux/:id', () => p.appel('GET', `/travaux/${trId}`));
  const photoTr = detTr.data?.work_order?.photos?.avant?.[0];
  verifier('travaux : photos.avant[].id et document.id (retrait par appui long)', photoTr?.id && photoTr?.document?.id, j(ph.data).slice(0, 150));
  await etape('DELETE /travaux/:id/photos/:photoId', () => p.appel('DELETE', `/travaux/${trId}/photos/${photoTr?.id}`));
  await etape('POST /travaux/:id/depenses', () => p.appel('POST', `/travaux/${trId}/depenses`, { idem: uuid(), body: { amount: 15000, method: 'wave', spent_on: jour(), client_reference: `dep-${uuid()}` } }));
  await etape('PATCH /travaux/:id', () => p.appel('PATCH', `/travaux/${trId}`, { body: { title: 'Fuite salle de bain', category: 'plomberie', priority: 'urgente', apartment_id: app1, estimated_amount: null, contractor_id: artId } }));
  await etape('GET /travaux (tri -created_at)', () => p.appel('GET', '/travaux', { query: { page: 1, tri: '-created_at' } }));
  const inc = await etape('POST /incidents', () => p.appel('POST', '/incidents', { idem: uuid(), body: { building_id: immId, category: 'probleme_commun', title: 'Ascenseur en panne', description: 'Bloqué au 2e étage' } }));
  const incId = inc.data?.incident?.id;
  await etape('POST /incidents/:id/analyser', () => p.appel('POST', `/incidents/${incId}/analyser`, { body: { note: 'Technicien prévenu' } }));
  await etape('POST /incidents/:id/travaux', () => p.appel('POST', `/incidents/${incId}/travaux`, { idem: uuid(), body: { category: 'autre', priority: 'normale' } }));
  await etape('GET /incidents/:id', () => p.appel('GET', `/incidents/${incId}`));
  await etape('GET /documents (incident)', () => p.appel('GET', '/documents', { query: { entity_type: 'incident', entity_id: incId } }));

  // ── Documents (visibilité, lien, suppression ajoutés) ─────────────────────
  const doc = await etape('POST /documents (photo sur le locataire)', () => p.appel('POST', '/documents', {
    idem: uuid(), form: { fichier: image, champs: { entity_type: 'tenant', entity_id: tenantId, category: 'photo', captured_at: new Date().toISOString() } },
  }));
  const docId = doc.data?.document?.id;
  const docs = await etape('GET /documents (locataire)', () => p.appel('GET', '/documents', { query: { entity_type: 'tenant', entity_id: tenantId, limit: 50 } }));
  verifier('documents : visible_to_tenant, category, has_thumbnail', docs.data?.items?.[0] && 'visible_to_tenant' in docs.data.items[0]);
  const miniature = await p.appel('GET', `/documents/${docId}/fichier`, { query: { taille: 'miniature' }, brut: true });
  verifier('GET /documents/:id/fichier?taille=miniature', miniature.status === 200 && /^image\//.test(miniature.type || ''), `${miniature.status} ${miniature.type}`);
  await etape('PATCH /documents/:id (visible locataire)', () => p.appel('PATCH', `/documents/${docId}`, { body: { visible_to_tenant: true } }));
  const lien = await etape('GET /documents/:id/lien', () => p.appel('GET', `/documents/${docId}/lien`));
  verifier('lien : url + expires_in (stockage disque → url relative, le mobile affiche un message)', typeof lien.data?.url === 'string' && 'expires_in' in (lien.data || {}), j(lien.data));
  await etape('PATCH /documents/:id (retrait du partage)', () => p.appel('PATCH', `/documents/${docId}`, { body: { visible_to_tenant: false } }));
  await etape('DELETE /documents/:id', () => p.appel('DELETE', `/documents/${docId}`));
  if (docContrat) await etape('DELETE /documents/:id (contrat → protégé)', () => p.appel('DELETE', `/documents/${docContrat}`), [409]);

  // ── Messagerie, tableau de bord, rapports, paramètres, abonnement ────────
  const msg = await etape('POST /messagerie/locataires/:tenantId/messages', () => p.appel('POST', `/messagerie/locataires/${tenantId}/messages`, { idem: uuid(), body: { body: 'Bonjour, bienvenue !' } }));
  const filId = msg.data?.message?.thread_id;
  await etape('POST /messagerie/locataires/:tenantId/photos', () => p.appel('POST', `/messagerie/locataires/${tenantId}/photos`, { idem: uuid(), form: { fichier: image } }));
  await etape('GET /messagerie/fils', () => p.appel('GET', '/messagerie/fils', { query: { page: 1 } }));
  await etape('GET /messagerie/fils/:id/messages', () => p.appel('GET', `/messagerie/fils/${filId}/messages`, { query: { limit: 100 } }));
  await etape('POST /messagerie/fils/:id/lu', () => p.appel('POST', `/messagerie/fils/${filId}/lu`));
  const dash = await etape('GET /dashboard', () => p.appel('GET', '/dashboard'));
  verifier('dashboard : patrimoine et loyers', dash.data?.dashboard?.patrimoine && dash.data?.dashboard?.loyers);
  await etape('GET /dashboard/graphiques (nb_mois 6)', () => p.appel('GET', '/dashboard/graphiques', { query: { nb_mois: 6 } }));
  for (const type of ['financier', 'immobilier', 'locataires', 'travaux']) {
    await etape(`GET /rapports/${type}`, () => p.appel('GET', `/rapports/${type}`, { query: { du: jour(-60), au: jour() } }));
    const csv = await p.appel('GET', `/rapports/${type}`, { query: { du: jour(-60), au: jour(), format: 'csv' }, brut: true });
    verifier(`GET /rapports/${type}?format=csv`, csv.status === 200 && /csv/.test(csv.type || ''), `${csv.status} ${csv.type}`);
  }
  await etape('GET /rapports/rentabilite', () => p.appel('GET', '/rapports/rentabilite', { query: { du: jour(-60), au: jour(), page: 1, tri: '-resultat_net' } }));
  const par = await etape('GET /parametres', () => p.appel('GET', '/parametres'));
  verifier('paramètres : owner et settings', par.data?.owner && par.data?.settings);
  await etape('PATCH /parametres (relances)', () => p.appel('PATCH', '/parametres', { body: { reminder_offsets: [-3, 0, 3] } }));
  await etape('PATCH /parametres (entier)', () => p.appel('PATCH', '/parametres', { body: { late_grace_days: 5 } }));
  await etape('PATCH /parametres/profil', () => p.appel('PATCH', '/parametres/profil', { body: { display_name: 'Awa Ndiaye Immobilier', city: 'Dakar' } }));
  await etape('GET /abonnement', () => p.appel('GET', '/abonnement'));
  await etape('GET /abonnement/plans', () => p.appel('GET', '/abonnement/plans'));
  await etape('GET /abonnement/paiements', () => p.appel('GET', '/abonnement/paiements', { query: { limit: 10 } }));
  await etape('GET /notifications/compteur', () => p.appel('GET', '/notifications/compteur'));
  await etape('GET /notifications', () => p.appel('GET', '/notifications', { query: { page: 1, non_lues: true } }));
  await etape('POST /notifications/tout-lire', () => p.appel('POST', '/notifications/tout-lire'));
  await etape('GET /compte/sessions', () => p.appel('GET', '/compte/sessions'));
  await etape('PATCH /compte (langue)', () => p.appel('PATCH', '/compte', { body: { first_name: 'Awa', last_name: 'Ndiaye', language: 'fr' } }));
  await etape('POST /compte/mfa/initialiser', () => p.appel('POST', '/compte/mfa/initialiser', { body: { current_password: mdp } }));

  // ── Espace locataire ───────────────────────────────────────────────────────
  const l = new Client('locataire');
  const actv = await etape('POST /auth/locataire/activation', () => l.appel('POST', '/auth/locataire/activation', {
    body: { code: invitation?.code, phone: loc.data?.tenant?.phone, password: mdp, password_confirmation: mdp, device_name: 'Application mobile', platform: 'android' },
  }));
  l.access = actv.data?.access_token;
  const cl = await etape('GET /compte (locataire)', () => l.appel('GET', '/compte'));
  verifier('compte locataire : role_code locataire', cl.data?.user?.role_code === 'locataire');
  const acc = await etape('GET /locataire/accueil', () => l.appel('GET', '/locataire/accueil'));
  verifier('accueil : homes[] avec next_schedule / amount_overdue', Array.isArray(acc.data?.homes) && acc.data.homes.length === 1, j(acc.data).slice(0, 200));
  await etape('GET /locataire/echeances (à payer, asc)', () => l.appel('GET', '/locataire/echeances', { query: { page: 1, a_payer: true, ordre: 'asc' } }));
  const echL = await etape('GET /locataire/echeances (desc)', () => l.appel('GET', '/locataire/echeances', { query: { page: 1, ordre: 'desc' } }));
  await etape('GET /locataire/paiements', () => l.appel('GET', '/locataire/paiements', { query: { page: 1 } }));
  await etape('GET /locataire/paiements/transactions', () => l.appel('GET', '/locataire/paiements/transactions', { query: { page: 1 } }));
  const qL = await etape('GET /locataire/quittances', () => l.appel('GET', '/locataire/quittances', { query: { page: 1, tri: '-issued_at' } }));
  if (qL.data?.items?.[0]) await pdf(l, 'GET /locataire/quittances/:id/pdf', `/locataire/quittances/${qL.data.items[0].id}/pdf`);
  await etape('GET /locataire/caution', () => l.appel('GET', '/locataire/caution'));
  await etape('GET /locataire/charges', () => l.appel('GET', '/locataire/charges', { query: { page: 1, tri: '-due_date' } }));
  const moy = await etape('GET /locataire/paiements/moyens', () => l.appel('GET', '/locataire/paiements/moyens', { query: { lease_id: bail1 } }));
  verifier('moyens locataire : methods.integre[] et methods.preuve[]', Array.isArray(moy.data?.methods?.integre) && Array.isArray(moy.data?.methods?.preuve), j(moy.data));
  const aPayer = (echL.data?.items || []).find((e) => ['a_payer', 'en_retard', 'partiellement_paye'].includes(e.status));
  if (aPayer) {
    const prv = await etape('POST /locataire/paiements/preuves', () => l.appel('POST', '/locataire/paiements/preuves', {
      idem: uuid(), form: { fichier: image, champs: { provider_transaction_id: `TX${suffixe}AB`, amount: aPayer.amount_due - aPayer.amount_paid, rent_schedule_id: aPayer.id, wallet: 'wave' } },
    }));
    const txId = prv.data?.transaction?.id;
    await etape('GET /locataire/paiements/transactions/:id', () => l.appel('GET', `/locataire/paiements/transactions/${txId}`));
    await etape('GET /paiements/transactions (preuves)', () => p.appel('GET', '/paiements/transactions', { query: { page: 1, status: 'en_attente', mode: 'preuve', tri: '-created_at' } }));
    await etape('GET /paiements/transactions/:id', () => p.appel('GET', `/paiements/transactions/${txId}`));
    await etape('POST /paiements/transactions/:id/valider', () => p.appel('POST', `/paiements/transactions/${txId}/valider`, { idem: uuid() }));
  } else verifier('échéance payable côté locataire', false, j(echL.data?.items?.map((e) => e.status)));
  await etape('GET /paiements/rapprochements', () => p.appel('GET', '/paiements/rapprochements', { query: { page: 1, status: 'en_attente' } }));

  const incL = await etape('POST /locataire/incidents (bail unique, sans lease_id)', () => l.appel('POST', '/locataire/incidents', {
    idem: uuid(), body: { category: 'fuite', title: 'Fuite sous l’évier', description: 'Goutte à goutte', client_reference: `inc-${uuid()}` },
  }));
  const incLId = incL.data?.incident?.id;
  await etape('POST /locataire/incidents/:id/pieces', () => l.appel('POST', `/locataire/incidents/${incLId}/pieces`, { idem: uuid(), form: { fichier: image } }));
  await etape('GET /locataire/incidents/:id', () => l.appel('GET', `/locataire/incidents/${incLId}`));
  await etape('GET /locataire/incidents', () => l.appel('GET', '/locataire/incidents', { query: { page: 1 } }));
  await etape('GET /locataire/etats-des-lieux', () => l.appel('GET', '/locataire/etats-des-lieux', { query: { page: 1, tri: '-created_at' } }));
  await etape('GET /locataire/etats-des-lieux/:id', () => l.appel('GET', `/locataire/etats-des-lieux/${edlId}`));
  await pdf(l, 'GET /locataire/etats-des-lieux/:id/pdf', `/locataire/etats-des-lieux/${edlId}/pdf`);
  await etape('POST /locataire/etats-des-lieux/:id/accepter', () => l.appel('POST', `/locataire/etats-des-lieux/${edlId}/accepter`, { idem: uuid() }));
  const filsL = await etape('GET /locataire/messagerie', () => l.appel('GET', '/locataire/messagerie', { query: { page: 1 } }));
  verifier('fils locataire : owner.display_name', filsL.data?.items?.[0]?.owner?.display_name);
  const filL = filsL.data?.items?.[0]?.id;
  await etape('GET /locataire/messagerie/:threadId/messages', () => l.appel('GET', `/locataire/messagerie/${filL}/messages`, { query: { limit: 100 } }));
  await etape('POST /locataire/messagerie/:threadId/messages', () => l.appel('POST', `/locataire/messagerie/${filL}/messages`, { idem: uuid(), body: { body: 'Merci !' } }));
  await etape('POST /locataire/messagerie/:threadId/photos', () => l.appel('POST', `/locataire/messagerie/${filL}/photos`, { idem: uuid(), form: { fichier: image } }));
  await etape('POST /locataire/messagerie/:threadId/lu', () => l.appel('POST', `/locataire/messagerie/${filL}/lu`));
  await etape('POST /locataire/consentement-whatsapp', () => l.appel('POST', '/locataire/consentement-whatsapp', { body: { accorde: false } }));

  // ── Correctif « plusieurs locations » : 2e bail actif pour le même locataire ──
  const b2 = await etape('POST /baux (2e logement)', () => p.appel('POST', '/baux', { idem: uuid(), body: corpsBail(app2) }));
  const edl2 = await etape('POST /etats-des-lieux (2e logement)', () => p.appel('POST', '/etats-des-lieux', { idem: uuid(), body: { lease_id: b2.data?.lease?.id, type: 'entree', performed_at: jour(), client_reference: `edl-${uuid()}` } }));
  const det2 = await p.appel('GET', `/etats-des-lieux/${edl2.data?.inspection?.id}`);
  await etape('PUT saisie (2e logement)', () => p.appel('PUT', `/etats-des-lieux/${edl2.data?.inspection?.id}/saisie`, { body: { items: (det2.data?.inspection?.rooms || []).flatMap((r) => r.items || []).map((i) => ({ item_id: i.id, condition: 'usage', comment: null })) } }));
  await etape('POST soumettre (2e logement)', () => p.appel('POST', `/etats-des-lieux/${edl2.data?.inspection?.id}/soumettre`));
  await etape('POST /baux/:id/activer (2e logement)', () => p.appel('POST', `/baux/${b2.data?.lease?.id}/activer`));
  const logement = await etape('GET /locataire/logement', () => l.appel('GET', '/locataire/logement'));
  const actifs = (logement.data?.leases || []).filter((b) => b.status === 'actif');
  verifier('logement : 2 baux actifs avec apartment.number et apartment.building.name (sélecteur mobile)',
    actifs.length === 2 && actifs.every((b) => b.apartment?.number && b.apartment?.building?.name), j(actifs.map((b) => b.apartment)).slice(0, 200));
  await etape('POST /locataire/incidents sans lease_id (ancien mobile → 422 attendu)', () => l.appel('POST', '/locataire/incidents', {
    idem: uuid(), body: { category: 'serrure', title: 'Serrure bloquée', description: 'La clé ne tourne plus', client_reference: `inc-${uuid()}` },
  }), [422]);
  await etape('POST /locataire/incidents avec lease_id (mobile corrigé)', () => l.appel('POST', '/locataire/incidents', {
    idem: uuid(), body: { lease_id: actifs[1]?.id, category: 'serrure', title: 'Serrure bloquée', description: 'La clé ne tourne plus', client_reference: `inc-${uuid()}` },
  }));

  // ── Fin de bail et déconnexion ─────────────────────────────────────────────
  await etape('POST /baux/:id/terminer', () => p.appel('POST', `/baux/${b2.data?.lease?.id}/terminer`, { body: { ended_on: jour(), termination_reason: 'Départ' } }));
  await etape('POST /auth/mot-de-passe-oublie', () => new Client().appel('POST', '/auth/mot-de-passe-oublie', { body: { identifiant: `awa.${suffixe}@demo.sn` } }));
  await etape('POST /auth/deconnexion', () => new Client().appel('POST', '/auth/deconnexion', { body: { refresh_token: ref.data?.refresh_token } }));

  console.log(resultats.join('\n'));
  console.log(`\n${resultats.length} vérifications, ${echecs} échec(s)`);
  process.exit(echecs ? 1 : 0);
})();
