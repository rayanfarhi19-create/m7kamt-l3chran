create extension if not exists pgcrypto;

create table if not exists public.cases (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 40),
  charge text not null,
  punishment text not null,
  guilty integer not null default 0,
  innocent integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.cases enable row level security;

create policy "Anyone can read cases" on public.cases for select using (true);
create policy "Anyone can create cases" on public.cases for insert with check (true);

create or replace function public.vote_case(p_case_id uuid, p_vote text)
returns setof public.cases
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_vote not in ('guilty','innocent') then raise exception 'invalid vote'; end if;
  if p_vote='guilty' then
    return query update public.cases set guilty=guilty+1 where id=p_case_id returning *;
  else
    return query update public.cases set innocent=innocent+1 where id=p_case_id returning *;
  end if;
end;
$$;

grant execute on function public.vote_case(uuid,text) to anon, authenticated;
