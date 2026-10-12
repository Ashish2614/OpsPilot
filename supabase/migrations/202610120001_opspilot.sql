create extension if not exists pgcrypto;
create type public.user_role as enum ('admin','agent','employee');
create type public.ticket_priority as enum ('low','medium','high','urgent');
create type public.ticket_status as enum ('open','in_progress','pending','resolved','closed');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 120),
  email text not null unique,
  role public.user_role not null default 'employee',
  department text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.tickets (
  id uuid primary key default gen_random_uuid(),
  reference text not null unique,
  title text not null check (char_length(title) between 5 and 140),
  description text not null check (char_length(description) between 10 and 5000),
  category text not null default 'IT Support',
  requester_id uuid not null references public.profiles(id),
  assignee_id uuid references public.profiles(id),
  priority public.ticket_priority not null default 'medium',
  status public.ticket_status not null default 'open',
  due_date timestamptz,
  resolved_at timestamptz,
  tags text[] not null default '{}',
  history jsonb not null default '[]',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.comments (
  id uuid primary key default gen_random_uuid(), ticket_id uuid not null references public.tickets(id) on delete cascade,
  author_id uuid not null references public.profiles(id), text text not null check (char_length(text) between 1 and 3000), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.notifications (
  id uuid primary key default gen_random_uuid(), recipient_id uuid not null references public.profiles(id) on delete cascade,
  type text not null, title text not null, message text not null, ticket_id uuid references public.tickets(id) on delete cascade,
  dedupe_key text unique, read boolean not null default false, created_at timestamptz not null default now()
);
create table public.audit_logs (
  id uuid primary key default gen_random_uuid(), actor_id uuid references public.profiles(id), action text not null, entity text not null, entity_id uuid, detail jsonb, created_at timestamptz not null default now()
);
create sequence public.ticket_reference_seq start 1001;
create or replace function public.next_ticket_reference() returns text language plpgsql security definer set search_path = public as $$ begin return 'OPS-' || nextval('public.ticket_reference_seq'); end; $$;

create index tickets_requester_idx on public.tickets(requester_id); create index tickets_assignee_idx on public.tickets(assignee_id); create index tickets_queue_idx on public.tickets(status, priority, updated_at desc); create index tickets_due_idx on public.tickets(due_date, status); create index comments_ticket_idx on public.comments(ticket_id, created_at); create index notifications_recipient_idx on public.notifications(recipient_id, read, created_at desc);
create or replace function public.set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end; $$;
create trigger profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at(); create trigger tickets_updated_at before update on public.tickets for each row execute function public.set_updated_at(); create trigger comments_updated_at before update on public.comments for each row execute function public.set_updated_at();

alter table public.profiles enable row level security; alter table public.tickets enable row level security; alter table public.comments enable row level security; alter table public.notifications enable row level security; alter table public.audit_logs enable row level security;
create or replace function public.current_role() returns public.user_role language sql stable security definer set search_path = public as $$ select role from public.profiles where id = auth.uid() and active; $$;
create policy profiles_self_or_admin on public.profiles for select using (id = auth.uid() or public.current_role() = 'admin');
create policy tickets_owner_or_staff on public.tickets for select using (requester_id = auth.uid() or public.current_role() in ('admin','agent'));
create policy tickets_create_own on public.tickets for insert with check (requester_id = auth.uid());
create policy comments_visible_to_ticket_users on public.comments for select using (exists(select 1 from public.tickets t where t.id = ticket_id and (t.requester_id = auth.uid() or public.current_role() in ('admin','agent'))));
create policy notifications_owner on public.notifications for all using (recipient_id = auth.uid()) with check (recipient_id = auth.uid());
create policy audit_admin_read on public.audit_logs for select using (public.current_role() = 'admin');

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$ begin insert into public.profiles(id,name,email) values(new.id,coalesce(new.raw_user_meta_data->>'name',split_part(new.email,'@',1)),new.email); return new; end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();
