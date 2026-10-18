-- =====================================================================
-- Base de données du site de réservation (Supabase / PostgreSQL)
-- À coller dans Supabase > SQL Editor, puis « Run ».
-- =====================================================================

-- Rendez-vous
create table if not exists rdv (
  id          uuid primary key default gen_random_uuid(),
  prenom      text not null check (char_length(prenom) between 1 and 40),
  tel         text not null check (tel ~ '^\+?[0-9]{9,14}$'),
  prestation  text not null check (char_length(prestation) <= 120),
  duree       int  not null check (duree between 10 and 300),
  debut       timestamptz not null,
  fin         timestamptz not null,
  statut      text not null default 'en_attente' check (statut in ('en_attente','confirme')),
  note        text check (char_length(note) <= 200),
  code        text not null unique,
  created_at  timestamptz not null default now(),
  check (fin > debut),
  -- Empêche deux rendez-vous qui se chevauchent, même si deux clients cliquent en même temps
  constraint rdv_sans_chevauchement exclude using gist (tstzrange(debut, fin) with &&)
);

-- Créneaux bloqués par le coiffeur (pause, congé, formation…)
create table if not exists blocs (
  id     uuid primary key default gen_random_uuid(),
  debut  timestamptz not null,
  fin    timestamptz not null,
  motif  text check (char_length(motif) <= 60),
  check (fin > debut)
);

-- ---------------------------------------------------------------------
-- Sécurité : le public (clé anon) ne lit ni n'écrit les tables directement.
-- Seul le coiffeur connecté (rôle authenticated) y a accès.
-- ---------------------------------------------------------------------
alter table rdv   enable row level security;
alter table blocs enable row level security;

drop policy if exists coiffeur_rdv on rdv;
create policy coiffeur_rdv on rdv for all to authenticated using (true) with check (true);

drop policy if exists coiffeur_blocs on blocs;
create policy coiffeur_blocs on blocs for all to authenticated using (true) with check (true);

-- ---------------------------------------------------------------------
-- Fonctions publiques utilisées par les clients
-- ---------------------------------------------------------------------

-- Plages occupées (sans nom ni téléphone) pour calculer les créneaux libres
create or replace function creneaux_occupes(de timestamptz, a timestamptz)
returns table(debut timestamptz, fin timestamptz)
language sql security definer set search_path = public as $$
  select r.debut, r.fin from rdv r where r.debut < a and r.fin > de
  union all
  select b.debut, b.fin from blocs b where b.debut < a and b.fin > de;
$$;

-- Prise de rendez-vous : vérifie le créneau et renvoie le code client
create or replace function prendre_rdv(
  p_prenom text, p_tel text, p_prestation text, p_duree int, p_debut timestamptz, p_note text default null)
returns text
language plpgsql security definer set search_path = public as $$
declare
  v_fin  timestamptz := p_debut + make_interval(mins => p_duree);
  v_code text;
begin
  if p_debut < now() then raise exception 'Ce créneau est déjà passé.'; end if;
  if p_debut > now() + interval '60 days' then raise exception 'Date trop loin dans le futur.'; end if;
  if (select count(*) from rdv where tel = p_tel and debut > now()) >= 2 then
    raise exception 'Limite atteinte : 2 rendez-vous à venir maximum par numéro.';
  end if;
  if exists (select 1 from blocs where debut < v_fin and fin > p_debut) then
    raise exception 'Créneau indisponible';
  end if;
  v_code := upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6));
  insert into rdv (prenom, tel, prestation, duree, debut, fin, note, code)
  values (trim(p_prenom), p_tel, p_prestation, p_duree, p_debut, v_fin, nullif(trim(p_note), ''), v_code);
  return v_code;
exception
  when exclusion_violation then raise exception 'Créneau indisponible';
end;
$$;

-- Le client retrouve son rendez-vous avec code + téléphone
create or replace function mon_rdv(p_code text, p_tel text)
returns table(prenom text, prestation text, duree int, debut timestamptz, statut text)
language sql security definer set search_path = public as $$
  select prenom, prestation, duree, debut, statut from rdv
  where code = upper(p_code) and tel = p_tel;
$$;

-- Le client annule son rendez-vous (seulement s'il n'est pas passé)
create or replace function annuler_rdv(p_code text, p_tel text)
returns boolean
language plpgsql security definer set search_path = public as $$
begin
  delete from rdv where code = upper(p_code) and tel = p_tel and debut > now();
  return found;
end;
$$;

grant execute on function creneaux_occupes(timestamptz, timestamptz) to anon, authenticated;
grant execute on function prendre_rdv(text, text, text, int, timestamptz, text) to anon, authenticated;
grant execute on function mon_rdv(text, text) to anon, authenticated;
grant execute on function annuler_rdv(text, text) to anon, authenticated;
