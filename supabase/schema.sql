create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  phone text not null,
  address text not null,
  items jsonb not null,
  total numeric(12,2) not null default 0,
  status text not null default 'pending',
  created_at timestamptz not null default now()
);
alter table public.orders enable row level security;
create policy "public can create orders" on public.orders for insert with check (true);
